"""Independent outcome, local moment and model-space checks of refined fits."""
from pathlib import Path
import json,os
os.environ['OPENBLAS_NUM_THREADS']='2'
import numpy as np,pandas as pd
from scipy.sparse.linalg import LinearOperator,lsmr
R=Path(__file__).resolve().parent
PACK=Path(os.environ.get('STRICT_PACK',str(R.parent/'strict_pair_trends')))
terms=['meanpd5_post','pri5_post','trendpd5_post','distance_post2022']
reports=[]
for year in [2023,2024]:
 for kind in ['refined','cold']:
  folder=R/str(year)/kind
  if not (folder/'verification.json').exists():continue
  meta=json.loads((folder/'verification.json').read_text('utf8'))
  if not meta['converged']:
   reports.append(dict(year=year,kind=kind,passed=False,reason='Local convergence criterion not met',metrics=meta['metrics']));continue
  d=pd.read_stata(PACK/f'data/strict_{year}.dta',convert_categoricals=False)
  pred=pd.read_stata(folder/'predictions.dta',convert_categoricals=False)
  assert pred[['ex','im','year','tradevalue']].equals(d[['ex','im','year','tradevalue']])
  eta=pred.op_eta.to_numpy()-np.log(1e9);mu=np.exp(eta);y=d.tradevalue.to_numpy()/1e9
  assert np.isfinite(eta).all() and np.isfinite(mu).all() and (mu[y>0]>0).all()
  p,pl=pd.factorize(d.pair_id,sort=True);e,el=pd.factorize(d.ex_year,sort=True);i,il=pd.factorize(d.im_year,sort=True)
  x=d[terms].to_numpy();t=(d.year.to_numpy(dtype=float)-2012)/12
  b=pd.read_csv(folder/'coefficients.csv').set_index('term').loc[terms,'b'].to_numpy()
  local={label:float(abs(np.bincount(code,weights=y-mu)/np.bincount(code,weights=y)).max()) for label,code in [('pair',p),('exporter_year',e),('importer_year',i)]}
  count=np.bincount(p);tc=t-np.bincount(p,weights=t)[p]/count[p];variance=np.bincount(p,weights=tc*tc)
  def project(v):return v-np.bincount(p,weights=v)[p]/count[p]-tc*np.bincount(p,weights=tc*v)[p]/variance[p]
  ne,ni=len(el),len(il);scale=1/np.sqrt(np.r_[np.bincount(e),np.bincount(i)])
  def mv(c):
   c=c*scale;return project(c[e]+c[ne+i])
  def rm(v):
   v=project(v);return np.r_[np.bincount(e,weights=v),np.bincount(i,weights=v)]*scale
  op=LinearOperator((len(d),ne+ni),matvec=mv,rmatvec=rm,dtype=float)
  rhs=project(eta-x@b);fit=lsmr(op,rhs,atol=1e-13,btol=1e-13,conlim=1e14,maxiter=10000)
  span=float(abs(rhs-op@fit[0]).max())
  passed=max(local.values())<1e-8 and span<1e-5
  reports.append(dict(year=year,kind=kind,N=len(d),passed=passed,reason='Passed' if passed else 'Do not use: predictor column-space or local-margin check failed',original_keys_and_amounts_identical=True,local_relative_margins=local,predictor_column_span_max_error=span,pair_time_moment=meta['metrics']['pair_time'],coefficient_scores=meta['metrics']['regressors_global'],covariance_iteration_stability=meta['covariance_iteration_stability'],covariance_global_projection_error=meta['global_projection_error']))
(R/'refinement_audit.json').write_text(json.dumps(reports,indent=2),'utf8')
print(json.dumps(reports,indent=2))
assert all(any(v['year']==year and v['kind']=='cold' and v['passed'] for v in reports) for year in [2023,2024]), 'Both cold starts must pass before final adoption.'
