from pathlib import Path
import json,hashlib
import numpy as np,pandas as pd
R=Path(__file__).resolve().parent
for name,digest in json.loads((R/'input_manifest.json').read_text('utf8')).items():assert hashlib.sha256((R/name).read_bytes()).hexdigest()==digest,name
assert 'LOCAL_MARGIN_RUN_COMPLETED actual' in (R/'outputs/run_actual.log').read_text('utf8',errors='replace')
records=[];terms=['meanpd5_post','pri5_post','trendpd5_post','distance_post2022']
for name in ['NoConflictZero','ReporterCoverage','WeightAmount','WeightKg']:
 d=pd.read_stata(R/'data'/f'{name}.dta',convert_categoricals=False)
 p=pd.read_stata(R/'outputs'/name/'analysis_ready.dta',convert_categoricals=False)
 assert p[d.columns].equals(d)
 y=d.tradevalue.to_numpy()/1e9;eta=p.op_eta.to_numpy()-np.log(1e9);mu=np.exp(eta)
 assert np.isfinite(eta).all() and np.isfinite(mu).all() and (mu[y>0]>0).all()
 assert np.allclose(mu*1e9,p.op_mu.to_numpy(),rtol=1e-10,atol=1e-10)
 local={}
 for column in ['pair_id','ex_year','im_year']:
  code,_=pd.factorize(d[column],sort=True)
  local[column]=float(abs(np.bincount(code,weights=y-mu)/np.bincount(code,weights=y)).max())
 assert max(local.values())<1e-8,(name,local)
 x=d[terms].to_numpy();score=float(abs((x/x.std(0)).T@(y-mu)).max()/y.sum());assert score<1e-8
 old=pd.read_stata(R/'reference'/f'{name}.dta',convert_categoricals=False).set_index('term')
 new=pd.read_stata(R/'outputs'/name/'coefficients.dta',convert_categoricals=False).set_index('term')
 be=float(abs(old.b-new.b).max());se=float(abs(old.se-new.se).max());assert be<1e-6 and se<1e-5
 records.append(dict(model=name,N=len(d),outcome_and_keys_identical=True,local_margins=local,score_error=score,coefficient_max_difference=be,SE_max_difference=se,passed=True))
(R/'outputs/verification.json').write_text(json.dumps(records,indent=2),'utf8');print(json.dumps(records,indent=2))
