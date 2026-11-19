from pathlib import Path
import argparse
import atexit
import ctypes
import hashlib
import json
import os
import sys
import time
import warnings
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parent
# Reuse the project's existing scientific solver dependency, without installation.
sys.path.insert(0,str(ROOT.parent/'政治距离校准_1003/solver_dependencies'))
from scipy import sparse
from scipy.optimize import linprog, OptimizeWarning
warnings.filterwarnings('ignore',category=OptimizeWarning,message='Unrecognized options detected')

ap=argparse.ArgumentParser()
ap.add_argument('year',choices=['2023','2024'])
ap.add_argument('bundle',choices=['legacycore','core','loco','dual','replay'])
args=ap.parse_args()
OUT=ROOT/args.year
lockpath=OUT/(args.bundle+'_solver.lock')
if lockpath.exists():
    priorpid=int(lockpath.read_text('ascii'))
    kernel=ctypes.windll.kernel32
    handle=kernel.OpenProcess(0x1000,False,priorpid)
    running=False
    if handle:
        code=ctypes.c_ulong()
        kernel.GetExitCodeProcess(handle,ctypes.byref(code));kernel.CloseHandle(handle)
        running=code.value==259
    if running:
        print('EXISTING_SOLVER_OWNS_BUNDLE',args.year,args.bundle,priorpid,flush=True)
        sys.exit(0)
    lockpath.unlink()
with lockpath.open('x',encoding='ascii') as f:f.write(str(os.getpid()))
atexit.register(lambda: lockpath.unlink(missing_ok=True))
d=pd.read_stata(OUT/'validation_panel.dta',convert_categoricals=False)
specs=pd.read_csv(OUT/'models.csv')
if args.bundle=='legacycore':specs=specs.loc[specs.group.isin(['replay','endpoint','pairtrend','pretrade','mirror'])]
elif args.bundle=='core':specs=specs.loc[~specs.group.str.startswith(('loco_','dual_'))]
elif args.bundle in ('loco','dual'):specs=specs.loc[specs.group.str.startswith(args.bundle+'_')]
else:specs=specs.loc[specs.group.eq(args.bundle)]
flags=d[['ex','im','year']].copy()
audit=[]
stage=[]
cache={}
started=time.monotonic()
auditpath=OUT/(args.bundle+'_lp_audit.csv')
flagpath=OUT/('certified_'+args.bundle+'_flags.dta')
if auditpath.exists() and flagpath.exists():
    old=pd.read_csv(auditpath)
    oldflags=pd.read_stata(flagpath,convert_categoricals=False)
    assert oldflags[['ex','im','year']].equals(flags[['ex','im','year']])
    flags=oldflags
    audit=old.to_dict('records')
    stagepath=OUT/(args.bundle+'_selection_stages.csv')
    if stagepath.exists():
        try:stage=pd.read_csv(stagepath).to_dict('records')
        except pd.errors.EmptyDataError:pass
def hash_frame(frame):
    return hashlib.sha256(pd.util.hash_pandas_object(frame,index=False).to_numpy().tobytes()).hexdigest()

def prune(mask,spec):
    mask=mask.copy()
    keys=[s.split('##')[0] for s in spec.fe.split()]
    positive=d[spec.outcome].gt(0).to_numpy()
    for iteration in range(100):
        drop=np.zeros(len(d),bool)
        for key in keys:
            code=d[key].to_numpy(dtype=int)
            n=np.bincount(code[mask],minlength=code.max()+1)
            p=np.bincount(code[mask&positive],minlength=code.max()+1)
            drop|=mask&((n[code]<=1)|(p[code]==0))
        if not drop.any():return mask
        stage.append(dict(model=spec.model,stage='FE_pruning',removed=int(drop.sum()),positive_removed=int((drop&positive).sum())))
        mask[drop]=False
    raise RuntimeError('Pruning failed to stabilize')

def certify(mask,spec):
    begin=time.monotonic()
    checkpoint=OUT/('checkpoint_'+args.bundle+'_'+spec.model+'.npy')
    if checkpoint.exists():
        prior=np.load(checkpoint)
        assert len(prior)==len(mask)
        mask &= prior
    for attempt in range(60):
        mask=prune(mask,spec)
        v=d.loc[mask]
        positive=v[spec.outcome].to_numpy()>0
        if not len(v) or not positive.any():raise RuntimeError('Empty supported sample: '+spec.model)
        if 'pair_id##c.time' in spec.fe:
            # Exact closed-form separating directions for pairs with a single
            # positive observation at an observed time boundary. Their pair
            # intercept/slope alone yields z>=0, with z=0 on all positives.
            bounds=v.groupby('pair_id').time.agg(['min','max'])
            pp=v.loc[positive].groupby('pair_id').time.agg(['count','first'])
            bb=bounds.join(pp)
            bb=bb[bb['count'].eq(1)&(bb['first'].eq(bb['min'])|bb['first'].eq(bb['max']))].copy()
            bb['slope']=np.where(bb['first'].eq(bb['min']),1.,-1.)
            bb['intercept']=-bb['slope']*bb['first']
            z=v.pair_id.map(bb.slope).fillna(0).to_numpy()*v.time.to_numpy()+v.pair_id.map(bb.intercept).fillna(0).to_numpy()
            assert np.abs(z[positive]).max(initial=0)==0 and z.min(initial=0)>=0
            drop=(~positive)&(z>0)
            if drop.any():
                bb.to_csv(OUT/(spec.model+'_analytic_witness_'+str(attempt)+'.csv'))
                stage.append(dict(model=spec.model,stage='analytic_pair_slope_separation',removed=int(drop.sum()),positive_removed=0))
                mask[v.index.to_numpy()[drop]]=False
                np.save(checkpoint,mask)
                print('ANALYTIC_REMOVED',spec.model,int(drop.sum()),flush=True)
                continue
        blocks=[]
        for term in spec.fe.split():
            key=term.split('##')[0]
            codes,levels=pd.factorize(v[key],sort=True)
            block=sparse.csr_matrix((np.ones(len(v)),(np.arange(len(v)),codes)),shape=(len(v),len(levels)))
            blocks.append(block)
            if '##c.' in term:
                slope=term.split('##c.')[1]
                blocks.append(block.multiply(v[slope].to_numpy()[:,None]).tocsr())
        reg=v[spec.terms.split()].to_numpy(dtype=float)
        std=reg.std(axis=0)
        std=np.where(std>1e-14,std,1.0)
        blocks.append(sparse.csr_matrix(reg/std))
        X=sparse.hstack(blocks,format='csr')
        original_columns=X.shape[1]
        if 'pair_id##c.time' in spec.fe:
            # Exact null-space parameterization of the positive-row equalities.
            # Two positive-year anchors identify each pair's intercept/slope.
            # One positive anchor removes its intercept and leaves a free slope.
            # This is the SAME full-design separation problem, with fewer free
            # columns, not a looser/no-pair-trend approximation.
            vv=v.reset_index(drop=True)
            pp=vv.loc[positive].groupby('pair_id').time.agg(['idxmin','idxmax','count'])
            first=vv.pair_id.map(pp['idxmin']).to_numpy(dtype=int)
            last=vv.pair_id.map(pp['idxmax']).to_numpy(dtype=int)
            tt=vv.time.to_numpy(dtype=float)
            gap=tt[last]-tt[first]
            w2=np.divide(tt-tt[first],gap,out=np.zeros(len(vv)),where=gap!=0)
            otherblocks=[]
            for key in ['ex_year','im_year']:
                codes,levels=pd.factorize(vv[key],sort=True)
                otherblocks.append(sparse.csr_matrix((np.ones(len(vv)),(np.arange(len(vv)),codes)),shape=(len(vv),len(levels))))
            otherblocks.append(sparse.csr_matrix(reg/std))
            Z=sparse.hstack(otherblocks,format='csr')
            reduced=Z-Z[first].multiply((1-w2)[:,None])-Z[last].multiply(w2[:,None])
            one=vv.pair_id.map(pp['count']).eq(1).to_numpy()
            if one.any():
                codes,levels=pd.factorize(vv.loc[one,'pair_id'],sort=True)
                slopes=sparse.csr_matrix((tt[one]-tt[first[one]],(np.flatnonzero(one),codes)),shape=(len(vv),len(levels)))
                reduced=sparse.hstack([reduced,slopes],format='csr')
            X=reduced.tocsr();X.eliminate_zeros()
            print('PAIR_SLOPE_NULLSPACE',spec.model,'columns',original_columns,'to',X.shape[1],flush=True)
        Xp,X0=X[positive],X[~positive]
        if X0.shape[0]:
            for method in ['highs-ipm','highs-ds']:
                sol=linprog(-np.asarray(X0.sum(axis=0)).ravel(),A_ub=sparse.vstack([-X0,X0],format='csr'),
                            b_ub=np.r_[np.zeros(X0.shape[0]),np.ones(X0.shape[0])],A_eq=Xp,b_eq=np.zeros(Xp.shape[0]),
                            bounds=(None,None),method=method,options={'primal_feasibility_tolerance':1e-8,
                            'dual_feasibility_tolerance':1e-8,'ipm_optimality_tolerance':1e-10,'time_limit':240,'threads':2})
                if sol.success:break
                print('LP_SOLVER_RETRY',spec.model,method,sol.message,flush=True)
            if not sol.success:raise RuntimeError(spec.model+': '+sol.message)
            z=X@sol.x
            poserr=float(np.abs(z[positive]).max(initial=0))
            zeromin=float(z[~positive].min(initial=0))
            if poserr>1e-6 or zeromin<-1e-6:raise RuntimeError('Invalid separation certificate '+spec.model)
            separated=(~positive)&(z>1e-7)
            objective=float(-sol.fun)
        else:
            separated=np.zeros(len(v),bool)
            objective=poserr=zeromin=0.0
        if separated.any():
            idx=v.index.to_numpy()[separated]
            stage.append(dict(model=spec.model,stage='LP_separation',removed=len(idx),positive_removed=0,objective=objective))
            mask[idx]=False
            np.save(checkpoint,mask)
            print('LP_REMOVED',spec.model,len(idx),flush=True)
            continue
        if abs(objective)>1e-5:raise RuntimeError('Nonzero objective without identified zero rows '+spec.model)
        rec=dict(model=spec.model,N=int(mask.sum()),pairs=int(v.pair_id.nunique()),positive=int(positive.sum()),
                 objective=objective,max_positive_residual=poserr,min_zero_certificate=zeromin,
                 full_design_columns=original_columns,lp_parameterized_columns=X.shape[1],seconds=time.monotonic()-begin,keys_sha256=hash_frame(v[['ex','im','year']]))
        return mask,rec
    raise RuntimeError('Separation support did not stabilize '+spec.model)

grouped=list(specs.groupby('group',sort=True))
# Complete ordinary designs first; heterogeneous slopes need more LP time.
grouped.sort(key=lambda item:(item[0]=='pairtrend',item[0]))
for group,ss in grouped:
    if set(ss.model)<=set(r['model'] for r in audit):
        print('RESUME_SKIP_CERTIFIED',group,flush=True)
        continue
    common=np.ones(len(d),bool)
    for spec in ss.itertuples(index=False):
        common &= d[spec.candidate].eq(1).to_numpy()
        common &= d[spec.terms.split()+[spec.outcome]].notna().all(axis=1).to_numpy()
        if spec.country!='ALL':common &= d.ex.ne(spec.country).to_numpy()&d.im.ne(spec.country).to_numpy()
    # A finite full model certifies its nested regressor subsets on the same
    # support. This reduces repeated LP solves without changing selection rules.
    full=[]
    for spec in ss.itertuples(index=False):
        nested=False
        for other in ss.itertuples(index=False):
            if other.model==spec.model or other.outcome!=spec.outcome or not set(spec.terms.split())<=set(other.terms.split()):continue
            fes=set(spec.fe.split());otherfes=set(other.fe.split())
            if fes<=otherfes or (fes=={'pair_id','ex_year','im_year'} and otherfes=={'pair_id##c.time','ex_year','im_year'}):
                nested=True;break
        # EndpointAnnual is exactly EndpointJoint with the focal regressor / 4.
        if spec.model=='EndpointAnnual' and 'EndpointJoint' in set(ss.model):nested=True
        if not nested:full.append(spec)
    if not full:raise RuntimeError('No full design selected '+group)
    for iteration in range(8):
        previous=common.copy()
        records=[]
        for spec in full:
            key=(spec.outcome,spec.terms,spec.fe,hash_frame(d.loc[common,['ex','im','year']]))
            if key in cache:certified,record=cache[key]
            else:
                certified,record=certify(common,spec)
                cache[key]=(certified.copy(),record)
            common &= certified
            records.append(record)
            print('LP_CHECK',args.year,args.bundle,group,spec.model,record['N'],round(record['seconds'],2),flush=True)
        finalhash=hash_frame(d.loc[common,['ex','im','year']])
        if all(r['keys_sha256']==finalhash for r in records):break
    else:raise RuntimeError('Common support failed to stabilize '+group)
    bymodel={r['model']:r for r in records}
    for spec in ss.itertuples(index=False):
        if spec.model in bymodel:record=bymodel[spec.model]
        else:
            for other in full:
                a=set(spec.terms.split());b=set(other.terms.split())
                if spec.model=='EndpointAnnual':a=(a-{'annualendpoint_post'})|{'endpoint_post'}
                if spec.outcome==other.outcome and a<=b:
                    record=bymodel[other.model]|dict(model=spec.model,certificate_inherited_from=other.model)
                    break
            else:raise RuntimeError('Nested certificate owner missing '+spec.model)
        assert record['N']==int(common.sum())
        flags['cert_'+spec.model]=common.astype('int8')
        audit.append(record|dict(group=group,common_support_stable=True))
    pd.DataFrame(audit).to_csv(OUT/(args.bundle+'_lp_audit.csv'),index=False)
    pd.DataFrame(stage).to_csv(OUT/(args.bundle+'_selection_stages.csv'),index=False)
    flags.to_stata(OUT/('certified_'+args.bundle+'_flags.dta'),write_index=False,version=118)
manifest=dict(completed=True,year=args.year,bundle=args.bundle,models=len(audit),seconds=time.monotonic()-started,
              input_panel_sha256=hashlib.sha256((OUT/'validation_panel.dta').read_bytes()).hexdigest(),
              flag_sha256=hashlib.sha256((OUT/('certified_'+args.bundle+'_flags.dta')).read_bytes()).hexdigest(),
              scientific_scope='Independent full-design LP separation checks including heterogeneous pair slopes when specified; model-specific pruning and iterated intersection. No original data overwritten.')
(OUT/(args.bundle+'_certification_completed.json')).write_text(json.dumps(manifest,indent=2),'utf-8')
print('CERTIFICATION_COMPLETED',json.dumps(manifest),flush=True)
