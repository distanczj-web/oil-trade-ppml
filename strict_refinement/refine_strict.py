"""Refine the unchanged strict model using local fixed-effect moment checks.

No observation, amount, regressor, or likelihood is changed. All adjustments to
eta are group intercepts, pair slopes, or original regressor combinations.
"""
from pathlib import Path
import os
os.environ['OPENBLAS_NUM_THREADS']='2';os.environ['OMP_NUM_THREADS']='2'
import argparse,ast,json,time
import numpy as np,pandas as pd
from scipy.sparse.linalg import LinearOperator,lsmr,cg
from scipy.stats import norm
R=Path(__file__).resolve().parent
PACK=R.parent/'strict_pair_trends'
ap=argparse.ArgumentParser();ap.add_argument('year',type=int);ap.add_argument('--cold',action='store_true');ap.add_argument('--resume',action='store_true');ap.add_argument('--cycles',type=int,default=500);args=ap.parse_args()
args.no_trend=False
year=args.year;out=R/str(year)/('cold' if args.cold else 'refined');out.mkdir(parents=True,exist_ok=True)
d=pd.read_stata(PACK/f'data/strict_{year}.dta',convert_categoricals=False)
terms=['meanpd5_post','pri5_post','trendpd5_post','distance_post2022']
y=d.tradevalue.to_numpy(dtype=float)/1e9;t=(d.year.to_numpy(dtype=float)-2012)/12
p,pl=pd.factorize(d.pair_id,sort=True);e,el=pd.factorize(d.ex_year,sort=True);i,il=pd.factorize(d.im_year,sort=True)
n=len(d);npair,ne,ni=len(pl),len(el),len(il);total=y.sum()
x=d[terms].to_numpy(dtype=float);xs=x.std(axis=0);x=x/xs
source=PACK/'code/solve_sparse.py';tree=ast.parse(source.read_text('utf8'))
keep=[v for v in tree.body if isinstance(v,ast.ClassDef) and v.name=='WeightedSystem']
exec(compile(ast.Module(body=keep,type_ignores=[]),str(source),'exec'))
Yp=np.bincount(p,weights=y);Ye=np.bincount(e,weights=y);Yi=np.bincount(i,weights=y)
assert min(Yp.min(),Ye.min(),Yi.min())>0
largest=np.full(npair,-np.inf);np.maximum.at(largest,p,y)
anchor=np.full(npair,-1,dtype=int);np.maximum.at(anchor,p,np.where(y==largest[p],np.arange(n),-1))
dt=t-t[anchor][p]
observed_center=np.bincount(p,weights=y*dt)/Yp
q=dt-observed_center[p]
qmin=np.full(npair,np.inf);qmax=np.full(npair,-np.inf)
np.minimum.at(qmin,p,q);np.maximum.at(qmax,p,q)
span=qmax-qmin
assert np.all(qmin<0)&np.all(qmax>0), 'Pair time moment lies at a boundary: audit separation first.'
if args.cold:
 eta=np.log(Yp[p]/np.bincount(p)[p]);beta=np.zeros(4)
else:
 pred=pd.read_stata(PACK/f'outputs/{year}/strict/predictions.dta',convert_categoricals=False)
 assert pred[['ex','im','year','tradevalue']].equals(d[['ex','im','year','tradevalue']])
 eta=pred.op_eta.to_numpy()-np.log(1e9)
 b=pd.read_csv(PACK/f'outputs/{year}/strict/coefficients.csv').set_index('term').loc[terms,'b'].to_numpy()
 beta=b*xs
if args.resume:
 prior=np.load(out/'checkpoint.npz');eta=prior['eta'];beta=prior['beta'];assert len(eta)==n
begin=time.monotonic();history=[]
def objective(z):
 if not np.isfinite(z).all() or z.max()>700:return np.inf
 return float((np.exp(z)-y*z).sum())
def metrics(z):
 mu=np.exp(z);res=y-mu
 result={}
 for label,code,Y in [('pair',p,Yp),('exporter_year',e,Ye),('importer_year',i,Yi)]:
  result[label]=float(np.max(abs(np.bincount(code,weights=res))/Y))
 result['pair_time']=float(np.max(abs(np.bincount(p,weights=mu*q))/(Yp*span)))
 result['regressors_global']=float(abs(x.T@res).max()/total)
 return result
def rescale_group(z,code,Y):
 peak=np.full(len(Y),-np.inf);np.maximum.at(peak,code,z)
 s=np.bincount(code,weights=np.exp(z-peak[code]),minlength=len(Y))
 return z+(np.log(Y)-peak-np.log(s))[code]
def moments(z,slope):
 v=z+slope[p]*q
 peak=np.full(npair,-np.inf);np.maximum.at(peak,p,v)
 w=np.exp(v-peak[p]);s=np.bincount(p,weights=w,minlength=npair)
 center=np.bincount(p,weights=w*q,minlength=npair)/s
 # Weighted variance is formed around the dominant observation to avoid cancellation.
 at=np.full(npair,-1,dtype=int);np.maximum.at(at,p,np.where(v==peak[p],np.arange(n),-1))
 dq=q-q[at][p];mean=np.bincount(p,weights=w*dq,minlength=npair)/s
 var=np.bincount(p,weights=w*(dq-mean[p])**2,minlength=npair)/s
 return center,var,peak+np.log(s)
def pair_fit(z):
 lo=np.full(npair,-1.);hi=np.full(npair,1.)
 for k in range(50):
  fl,_,_=moments(z,lo);fh,_,_=moments(z,hi)
  left=fl>0;right=fh<0
  if not(left.any() or right.any()):break
  lo[left]*=2;hi[right]*=2
 else:raise RuntimeError('Pair slope bracketing failed')
 slope=np.zeros(npair)
 for k in range(70):
  f,var,lse=moments(z,slope)
  if np.max(abs(f)/span)<3e-12:break
  active=abs(f)/span>=3e-12
  lo=np.where(active&(f<0),slope,lo);hi=np.where(active&(f>=0),slope,hi)
  with np.errstate(divide='ignore',invalid='ignore'):candidate=slope-f/var
  good=np.isfinite(candidate)&(candidate>lo)&(candidate<hi)
  slope=np.where(active,np.where(good,candidate,(lo+hi)/2),slope)
 else:raise RuntimeError('Pair conditional time moments did not converge')
 return z+slope[p]*q+(np.log(Yp)-lse)[p]

def equilibrate(z,maxcycles):
 for cycle in range(maxcycles):
  z=pair_fit(z);z=rescale_group(z,e,Ye);z=rescale_group(z,i,Yi)
  m=metrics(z)
  if cycle%10==0 or max(m[k] for k in ['pair','exporter_year','importer_year','pair_time'])<1e-8:
   print('LOCAL',cycle,round(time.monotonic()-begin,2),json.dumps(m),flush=True)
  if max(m[k] for k in ['pair','exporter_year','importer_year','pair_time'])<1e-8:return z,m,True
 return z,metrics(z),False

print('START',year,len(d),args.cold,json.dumps(metrics(eta)),flush=True)
eta,m,local_ok=equilibrate(eta,args.cycles)
converged=False
for outer in range(60):
 mu=np.exp(eta);w=WeightedSystem(mu)
 c,info=w.solve_score(y-mu)
 other=w.z(c);res=y-mu-w.mu*other
 a=np.bincount(p,weights=res,minlength=npair)/w.s0
 slope=np.bincount(p,weights=res*w.tc,minlength=npair)/w.var
 step=other+a[p]+w.tc*slope[p]
 old=objective(eta);gd=float((mu-y)@step);alpha=min(1.,30/max(float(abs(step).max()),30.))
 for attempt in range(60):
  trial=eta+alpha*step
  if objective(trial)<=old+1e-4*alpha*gd+1e-13*total:break
  alpha*=.5
 else:raise RuntimeError('Outer line search failed')
 eta=trial;beta+=alpha*c[-4:]
 eta,m,local_ok=equilibrate(eta,min(args.cycles,150))
 beta_step=float(abs(alpha*c[-4:]/xs).max())
 history.append(dict(iteration=outer,seconds=time.monotonic()-begin,beta_step=beta_step,objective=objective(eta),**m))
 pd.DataFrame(history).to_csv(out/'iterations.csv',index=False)
 np.savez_compressed(out/'checkpoint.npz',eta=eta,beta=beta)
 print('OUTER',outer,beta_step,(beta/xs).tolist(),json.dumps(m),flush=True)
 if local_ok and m['regressors_global']<1e-10 and beta_step<1e-7:
  converged=True;break
result=dict(year=year,N=n,pairs=npair,converged=converged,cold_start=args.cold,criterion='Every fixed-effect relative margin and normalized pair time moment below 1e-8; scaled coefficient scores below 1e-10; beta step below 1e-7',metrics=m,beta=dict(zip(terms,(beta/xs).tolist())),seconds=time.monotonic()-begin)
if converged:
 mu=np.exp(eta);w=WeightedSystem(mu,include_x=False)
 xres=np.empty_like(x)
 for j in range(4):
  c,info=w.solve(w.root*x[:,j],tol=2e-13)
  xres[:,j]=w.residualize_pair(x[:,j]-w.z(c))
 # Tight local weighted projections supplement global linear-solver stopping.
 covariance_history=[]
 def covariance_from_residuals(a):
  hh=a.T@(mu[:,None]*a);ss=np.column_stack([np.bincount(p,weights=a[:,j]*(y-mu),minlength=npair) for j in range(4)])
  inverse=np.linalg.inv(hh)
  return inverse@(ss.T@ss)@inverse/np.outer(xs,xs)*npair/(npair-1)
 for cycle in range(5001):
  for code,Y in [(e,Ye),(i,Yi)]:
   mass=np.bincount(code,weights=mu)
   for j in range(4):xres[:,j]-=(np.bincount(code,weights=mu*xres[:,j])/mass)[code]
  for j in range(4):xres[:,j]=w.residualize_pair(xres[:,j])
  if cycle%20==0:
   orth=max(float(abs(np.bincount(code,weights=mu*xres[:,j])/np.bincount(code,weights=mu)).max()) for code in [p,e,i] for j in range(4))
   if cycle in [0,1000,2500,5000]:
    covariance_history.append((cycle,covariance_from_residuals(xres).copy()))
    print('COVARIANCE_PROJECTION',cycle,orth,flush=True)
   if orth<1e-8:break
 H=xres.T@(mu[:,None]*xres);scores=np.column_stack([np.bincount(p,weights=xres[:,j]*(y-mu),minlength=npair) for j in range(4)])
 inv=np.linalg.inv(H);cov=inv@(scores.T@scores)@inv/np.outer(xs,xs)*npair/(npair-1)
 se=np.sqrt(np.diag(cov));coef=beta/xs
 global_orth=max(float(abs(np.bincount(code,weights=mu*xres[:,j])).max()/total) for code in [p,e,i] for j in range(4))
 slope_orth=max(float(abs(np.bincount(p,weights=mu*t*xres[:,j])).max()/total) for j in range(4))
 cov_stability=float(abs(cov-covariance_history[-2][1]).max()) if len(covariance_history)>1 else 0.
 assert global_orth<1e-9 and slope_orth<1e-9 and cov_stability<1e-6
 assert np.isfinite(cov).all() and np.linalg.eigvalsh((cov+cov.T)/2).min()>0
 pd.DataFrame(dict(term=terms,b=coef,se=se,p=2*norm.sf(abs(coef/se)),ci_low=coef-1.95996398454*se,ci_high=coef+1.95996398454*se)).to_csv(out/'coefficients.csv',index=False)
 pd.DataFrame(cov,columns=terms).to_csv(out/'covariance.csv',index=False)
 pred=d[['ex','im','year','tradevalue']].copy();pred['op_eta']=eta+np.log(1e9);pred['op_mu']=mu*1e9
 pred.to_stata(out/'predictions.dta',write_index=False,version=118)
 result.update(local_projection_error=orth,global_projection_error=global_orth,slope_projection_error=slope_orth,covariance_iteration_stability=cov_stability,positive_underflows=int(((y>0)&(mu==0)).sum()))
(out/'verification.json').write_text(json.dumps(result,indent=2),'utf8');print('FINISHED',json.dumps(result),flush=True)
