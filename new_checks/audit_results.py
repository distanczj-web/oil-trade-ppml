from pathlib import Path
import json,hashlib
import numpy as np,pandas as pd
R=Path(__file__).resolve().parent
state=pd.read_csv(R/'run_state.csv');assert state.state.iloc[0]=='complete'
manifest=json.loads((R/'frozen_manifest.json').read_text('utf8'))
for name,digest in manifest.items():assert hashlib.sha256((R/name).read_bytes()).hexdigest()==digest,name
checks=[]
terms=['meanpd5_post','pri5_post','trendpd5_post','distance_post2022']
for name in ['PL2015','PL2017','Dependence']:
 if name=='Dependence':
  folder=R/'供应关系异质性';a=pd.read_stata(folder/'standard_results.dta').set_index('term');b=pd.read_stata(folder/'results.dta').set_index('term');inp=folder/'input.dta';pred=folder/'validated_predictions.dta';xterms=terms+['dependence_post','trend_dependence_post']
 else:
  folder=R/'历史安慰剂';res=pd.read_stata(folder/'results.dta');a=res.loc[res.model.eq(name)].set_index('term');b=res.loc[res.model.eq(name+'_local')].set_index('term');inp=folder/(name+'_input.dta');pred=folder/(name+'_local/validated_predictions.dta');xterms=terms
 d=pd.read_stata(pred);f=pd.read_stata(inp)
 assert d[['ex','im','year','tradevalue']].equals(f[['ex','im','year','tradevalue']])
 assert np.isfinite(d.op_eta).all() and np.isfinite(d.op_mu).all() and (d.op_mu[d.tradevalue.gt(0)]>0).all()
 y=d.tradevalue.to_numpy()/1e9;mu=d.op_mu.to_numpy()/1e9;err={};margin={}
 for key in ['pair_id','ex_year','im_year']:
  residual=pd.Series(y-mu).groupby(d[key]).sum();total=pd.Series(y).groupby(d[key]).sum()
  err[key]=float(abs(residual).max()/y.sum());margin[key]=float((abs(residual)/total).max())
 x=d[xterms].to_numpy();err['regressors']=float(abs((x/x.std(axis=0)).T@(y-mu)).max()/y.sum())
 bm=float(abs(a.b-b.b).max());sm=float(abs(a.se-b.se).max())
 assert bm<1e-6 and sm<1e-5 and max(err.values())<1e-8 and max(margin.values())<1e-8
 checks.append(dict(model=name,N=len(d),b_error=bm,se_error=sm,score_errors=err,relative_margins=margin,passed=True))
joint=pd.read_stata(R/'维度比较/joint_tests.dta');assert len(joint)==6 and joint.N.eq(83563).all()
report=dict(checks=checks,frozen_inputs_intact=True,portable_run_complete=True,scope='New-check estimation layer; not a raw-download reconstruction')
(R/'validation.json').write_text(json.dumps(report,indent=2),'utf8');print(json.dumps(report,indent=2))
