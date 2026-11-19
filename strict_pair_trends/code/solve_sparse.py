"""Independent PPML IRLS check, exact certified sample and unchanged specification.

Pair intercepts/slopes are eliminated analytically in each weighted least-squares
step. Remaining country-year effects and regressors are solved with SciPy LSMR.
An Armijo line search acts on the FULL linear predictor, with no eta clipping,
penalty, outcome replacement, or change to the certified observation support.
This is diagnostic code; its estimates are not automatically adopted in Word.
"""
from pathlib import Path
import os
os.environ['OPENBLAS_NUM_THREADS']='2'
os.environ['OMP_NUM_THREADS']='2'
import sys, argparse, json, time, hashlib
import numpy as np
import pandas as pd
HERE=Path(__file__).resolve().parent
BASE=HERE.parent/'导师补充验证_1016'
from scipy.sparse.linalg import LinearOperator, lsmr, cg
from scipy.special import xlogy
from scipy.stats import norm

ap=argparse.ArgumentParser()
ap.add_argument('year',type=int,choices=[2023,2024])
ap.add_argument('--no-trend',action='store_true')
ap.add_argument('--maxiter',type=int,default=100)
ap.add_argument('--restart',action='store_true')
ap.add_argument('--normal-cg',action='store_true')
ap.add_argument('--curvature-floor',type=float,default=0.)
ap.add_argument('--inference-only',action='store_true')
ap.add_argument('--start-from')
ap.add_argument('--objective-tol',type=float,default=1e-10)
args=ap.parse_args()
tag='baseline' if args.no_trend else 'strict'
if args.curvature_floor:tag+='_curvature'
OUT=HERE.parent/'python_outputs'/str(args.year)/tag
OUT.mkdir(parents=True,exist_ok=True)
terms=['meanpd5_post','pri5_post','trendpd5_post','distance_post2022']
d=pd.read_stata(HERE.parent/'data'/f'strict_{args.year}.dta',convert_categoricals=False)
y=d.tradevalue.to_numpy(dtype=float)/1e9
t=(d.year.to_numpy(dtype=float)-2012)/12
p,pl=pd.factorize(d.pair_id,sort=True)
e,el=pd.factorize(d.ex_year,sort=True)
i,il=pd.factorize(d.im_year,sort=True)
npair,ne,ni=len(pl),len(el),len(il)
n=len(d); total=y.sum()
x=d[terms].to_numpy(dtype=float)
xs=x.std(axis=0)
x=x/xs
hist=[]; begin=time.monotonic()
beta=np.zeros(4)
eta=np.log(np.bincount(p,weights=y)[p]/np.bincount(p)[p])
checkpoint=(HERE/str(args.year)/args.start_from/'checkpoint.npz') if args.start_from else OUT/'checkpoint.npz'
if args.start_from or ((args.restart or args.inference_only) and checkpoint.exists()):
    prior=np.load(checkpoint);eta=prior['eta'];beta=prior['beta']
    assert len(eta)==n
if args.restart and (OUT/'iterations.csv').exists():
    hist=pd.read_csv(OUT/'iterations.csv').to_dict('records')
previous_seconds=float(hist[-1]['seconds']) if hist else 0.
print('INPUT',args.year,'strict',not args.no_trend,'N',n,'pairs',npair,'positive',int((y>0).sum()),'columns',ne+ni+4,flush=True)

class WeightedSystem:
    def __init__(self,mu,include_x=True):
        self.mu=mu; self.root=np.sqrt(mu);self.include_x=include_x
        self.s0=np.bincount(p,weights=mu,minlength=npair)
        # Center around the largest-weight observation first. Direct subtraction
        # t-mean(t) can invent ~1e-16 slope variance in nearly one-point pairs.
        largest=np.full(npair,-np.inf);np.maximum.at(largest,p,mu)
        anchor=np.full(npair,-1,dtype=int)
        np.maximum.at(anchor,p,np.where(mu==largest[p],np.arange(n),-1))
        dt=t-t[anchor][p]
        mt=np.bincount(p,weights=mu*dt,minlength=npair)/self.s0
        self.tc=dt-mt[p]
        self.var=np.bincount(p,weights=mu*self.tc**2,minlength=npair)
        self.var=np.maximum(self.var,1e-290)
        # Column norm preconditioning; exact pair projection is in matvec/rmatvec.
        norms=np.r_[np.bincount(e,weights=mu,minlength=ne),np.bincount(i,weights=mu,minlength=ni)]
        if include_x:norms=np.r_[norms,(mu[:,None]*x*x).sum(axis=0)]
        self.scale=1/np.sqrt(np.maximum(norms,1e-290))
        self.operator=LinearOperator((n,len(self.scale)),matvec=self.matvec,rmatvec=self.rmatvec,dtype=float)
    def project(self,v):
        a=np.bincount(p,weights=self.root*v,minlength=npair)/self.s0
        out=v-self.root*a[p]
        if not args.no_trend:
            b=np.bincount(p,weights=self.root*self.tc*v,minlength=npair)/self.var
            out-=self.root*self.tc*b[p]
        return out
    def residualize_pair(self,v):
        a=np.bincount(p,weights=self.mu*v,minlength=npair)/self.s0
        out=v-a[p]
        if not args.no_trend:
            b=np.bincount(p,weights=self.mu*self.tc*v,minlength=npair)/self.var
            out-=self.tc*b[p]
        return out
    def z(self,c):
        out=c[e]+c[ne+i]
        if self.include_x:out=out+x@c[ne+ni:]
        return out
    def matvec(self,c):return self.project(self.root*self.z(c*self.scale))
    def rmatvec(self,v):
        w=self.root*self.project(v)
        out=np.r_[np.bincount(e,weights=w,minlength=ne),np.bincount(i,weights=w,minlength=ni)]
        if self.include_x:out=np.r_[out,x.T@w]
        return out*self.scale
    def solve(self,rhs,tol=2e-11):
        fit=lsmr(self.operator,self.project(rhs),atol=tol,btol=tol,conlim=1e14,maxiter=15000)
        if fit[1] not in (1,2,4,5):print('LSMR_WARNING',fit[1:8],flush=True)
        return fit[0]*self.scale,dict(lsmr_stop=int(fit[1]),lsmr_iter=int(fit[2]),lsmr_normal=float(fit[4]))
    def solve_score(self,resid):
        # Construct the normal-equation RHS without y/sqrt(mu), which can be
        # astronomically large for tiny positive observations during IRLS.
        a=np.bincount(p,weights=resid,minlength=npair)/self.s0
        rr=resid-self.mu*a[p]
        if not args.no_trend:
            b=np.bincount(p,weights=resid*self.tc,minlength=npair)/self.var
            rr-=self.mu*self.tc*b[p]
        g=np.r_[np.bincount(e,weights=rr,minlength=ne),np.bincount(i,weights=rr,minlength=ni),x.T@rr]*self.scale
        normal=LinearOperator((len(g),len(g)),matvec=lambda c:self.rmatvec(self.matvec(c)),dtype=float)
        count=[0]
        def tick(_):count[0]+=1
        q,rc=cg(normal,g,rtol=2e-11,atol=1e-14,maxiter=12000,callback=tick)
        er=float(np.linalg.norm(normal@q-g))
        if rc:print('CG_WARNING',rc,er,flush=True)
        return q*self.scale,dict(lsmr_stop=int(rc),lsmr_iter=count[0],lsmr_normal=er)

def objective(z):
    if not np.isfinite(z).all() or z.max()>700:return np.inf
    return float((np.exp(z)-y*z).sum())

def score_check(mu):
    r=y-mu
    values=[np.bincount(p,weights=r),np.bincount(e,weights=r),np.bincount(i,weights=r),x.T@r]
    if not args.no_trend:values.append(np.bincount(p,weights=r*t))
    return max(float(np.max(np.abs(a),initial=0)) for a in values)/total

converged=False
if args.inference_only:
    oldhist=pd.read_csv(OUT/'iterations.csv')
    assert len(oldhist)>=2 and oldhist.iloc[-1].score_relative<1e-9
    assert oldhist.iloc[-1].max_beta_step<1e-6
    assert abs(oldhist.iloc[-1].objective-oldhist.iloc[-2].objective)/total<args.objective_tol
    assert score_check(np.exp(eta))<1e-9
    converged=True
for it in range(0 if args.inference_only else args.maxiter):
    mu=np.exp(eta)
    # Optional positive curvature damping regularizes the NEWTON STEP only.
    # The objective, residual, scores and final covariance use original mu.
    floor=args.curvature_floor*(.8**it)
    sysw=WeightedSystem(mu+floor)
    if args.normal_cg:c,info=sysw.solve_score(y-mu)
    else:c,info=sysw.solve((y-mu)/sysw.root)
    other=sysw.z(c)
    resid=y-mu-sysw.mu*other
    a=np.bincount(p,weights=resid,minlength=npair)/sysw.s0
    step=other+a[p]
    if not args.no_trend:
        b=np.bincount(p,weights=resid*sysw.tc,minlength=npair)/sysw.var
        step+=sysw.tc*b[p]
    old=objective(eta)
    gd=float(np.dot(mu-y,step))
    if gd>1e-9*total:raise RuntimeError('Non-descent Newton direction')
    alpha=min(1.,30/max(float(np.max(np.abs(step))),30.))
    for backtrack in range(70):
        trial=eta+alpha*step
        new=objective(trial)
        if new <= old+1e-4*alpha*gd+2e-12*total:break
        alpha*=.5
    else:raise RuntimeError('Line search failed')
    eta=trial;beta+=alpha*c[-4:]
    err=score_check(np.exp(eta))
    row=dict(iteration=len(hist),seconds=previous_seconds+time.monotonic()-begin,objective=new,step_fraction=alpha,
             max_eta=float(eta.max()),min_eta=float(eta.min()),score_relative=err,curvature_damping=floor,
             max_beta_step=float(np.max(np.abs(alpha*c[-4:]/xs))),**info)
    hist.append(row)
    print(json.dumps(dict(**row,beta=(beta/xs).tolist())),flush=True)
    np.savez_compressed(OUT/'checkpoint.npz',eta=eta,beta=beta)
    pd.DataFrame(hist).to_csv(OUT/'iterations.csv',index=False)
    if err<1e-9 and row['max_beta_step']<1e-6 and abs(old-new)/total<args.objective_tol:
        converged=True;break

summary=dict(year=args.year,strict=not args.no_trend,converged=converged,N=n,pairs=npair,
             positive=int((y>0).sum()),beta=dict(zip(terms,(beta/xs).tolist())),
             score_relative=score_check(np.exp(eta)),seconds=time.monotonic()-begin,
             y_scale=1e9,objective_tolerance=args.objective_tol,score_tolerance=1e-9,beta_step_tolerance=1e-6,
             method='pair-block eliminated IRLS, sparse linear solve, full-predictor Armijo line search')
if converged:
    mu=np.exp(eta)
    w=WeightedSystem(mu,include_x=False)
    xres=np.empty_like(x)
    residual_checks=[]
    for j in range(4):
        c,info=w.solve(w.root*x[:,j],tol=2e-12)
        xres[:,j]=w.residualize_pair(x[:,j]-w.z(c))
        residual_checks.append(info)
    H=xres.T@(mu[:,None]*xres)
    cluster_scores=np.column_stack([np.bincount(p,weights=xres[:,j]*(y-mu),minlength=npair) for j in range(4)])
    meat=cluster_scores.T@cluster_scores
    inv=np.linalg.inv(H)
    cov=inv@meat@inv
    se=np.sqrt(np.diag(cov))/xs
    corrected_se=se*np.sqrt(npair/(npair-1))
    coef=beta/xs
    result=pd.DataFrame(dict(term=terms,b=coef,se_uncorrected=se,p_uncorrected=2*norm.sf(np.abs(coef/se))))
    result.to_csv(OUT/'coefficients_uncorrected.csv',index=False)
    pd.DataFrame(dict(term=terms,b=coef,se=corrected_se,p=2*norm.sf(np.abs(coef/corrected_se)),
                      ci_low=coef-1.95996398454*corrected_se,ci_high=coef+1.95996398454*corrected_se)).to_csv(OUT/'coefficients_cluster_corrected.csv',index=False)
    # Scaling changes the nuisance intercept only; original-dollar mu is exported.
    pred=d[['ex','im','year']].copy();pred['mu_sparse']=np.exp(eta)*1e9
    pred.to_stata(OUT/'initial_mu.dta',write_index=False,version=118)
    summary['se_uncorrected']=dict(zip(terms,se.tolist()))
    summary['se_cluster_corrected']=dict(zip(terms,corrected_se.tolist()))
    summary['residualization']=residual_checks
    summary['hessian_eigenvalues']=np.linalg.eigvalsh(H).tolist()
    summary['FE_orthogonality_relative']=max(float(np.abs(np.bincount(k,weights=mu*xres[:,j])).max(initial=0))/total
        for k in [p,e,i] for j in range(4))
    if not args.no_trend:
        summary['pair_slope_orthogonality_relative']=max(float(np.abs(np.bincount(p,weights=mu*t*xres[:,j])).max(initial=0))/total for j in range(4))
    summary['finite_coefficients_and_covariance']=bool(np.isfinite(coef).all() and np.isfinite(cov).all() and (corrected_se>0).all())
    assert summary['finite_coefficients_and_covariance']
    np.savez_compressed(OUT/'inference_arrays.npz',xres=xres,cov_scaled=cov,mu=mu)
(OUT/'diagnostic_summary.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf8')
print('DIAGNOSTIC_FINISHED',json.dumps(summary,ensure_ascii=False),flush=True)
