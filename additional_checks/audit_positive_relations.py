"""Verify the positive-pre-event-relations fit and its economic scales."""
from pathlib import Path
import json
import sys
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parent
REP=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else ROOT.parent
OUT=ROOT/'outputs'
terms=['meanpd5_post','pri5_post','trendpd5_post','distance_post2022','dependence_post','trend_dependence_post']
base=pd.read_stata(REP/'new_checks/供应关系异质性/input.dta',convert_categoricals=False)
source=base.loc[base.dependence.gt(0)].set_index(['ex','im','year'])
inp=pd.read_stata(OUT/'positive_input.dta',convert_categoricals=False).set_index(['ex','im','year'])
pred=pd.read_stata(OUT/'positive_predictions.dta',convert_categoricals=False).set_index(['ex','im','year'])
cols=['tradevalue','dependence','pair_id','ex_year','im_year']+terms
pd.testing.assert_frame_equal(inp[cols],source.loc[inp.index,cols],check_exact=True)
pd.testing.assert_frame_equal(pred[cols],inp[cols],check_exact=True)
assert (pred.dependence>0).all() and np.isfinite(pred.op_eta).all()
assert np.isfinite(pred.op_mu).all() and (pred.loc[pred.tradevalue.gt(0),'op_mu']>0).all()
a=pd.read_stata(OUT/'positive_standard.dta').set_index('term').loc[terms]
b=pd.read_stata(OUT/'positive_custom.dta').set_index('term').loc[terms]
bd=float(abs(a.b-b.b).max())
sd=float(abs(a.se-b.se).max())
assert bd<1e-6 and sd<1e-5
residual=pred.tradevalue-pred.op_mu
margins={key:float((residual.groupby(pred[key]).sum().abs()/pred.tradevalue.groupby(pred[key]).sum()).max()) for key in ['pair_id','ex_year','im_year']}
x=pred[terms].to_numpy()
score=float(abs((x/x.std(axis=0)).T@residual.to_numpy()).max()/pred.tradevalue.sum())
assert max(margins.values())<1e-8 and score<1e-8
cov=pd.read_stata(OUT/'positive_covariance.dta').to_numpy()
assert cov.shape==(6,6) and np.allclose(np.sqrt(np.diag(cov)),b.se,rtol=1e-7,atol=1e-8)
quantiles=pred.dependence.quantile([.5,.75,.9])
rows=[]
for q,s in quantiles.items():
    slope=float(b.loc['trendpd5_post','b']+s*b.loc['trend_dependence_post','b'])
    se=float(np.sqrt(cov[2,2]+2*s*cov[2,5]+s*s*cov[5,5]))
    rows.append({'percentile':int(q*100),'share':float(s),'slope':slope,'SE':se,
                 'conditional_pct':float(100*np.expm1(.01*slope)),
                 'lower_pct':float(100*np.expm1(.01*(slope-1.95996398454*se))),
                 'upper_pct':float(100*np.expm1(.01*(slope+1.95996398454*se)))})
pd.DataFrame(rows).to_csv(OUT/'positive_share_magnitudes.csv',index=False)
pred.reset_index()[['ex','im','year']].to_csv(OUT/'positive_final_keys.csv.gz',index=False,compression={'method':'gzip','mtime':0})
audit={'positive_candidates':len(source),'final_N':len(pred),'pairs':int(pred.pair_id.nunique()),
       'positive_outcomes':int(pred.tradevalue.gt(0).sum()),'coefficient_max_difference':bd,
       'SE_max_difference':sd,'relative_margins':margins,'normalised_score':score,
       'unchanged_outcomes_and_regressors':True,'passed':True,
       'full_sample_zero_share_observations':int(base.dependence.eq(0).sum()),
       'full_sample_total_observations':len(base),'positive_sample_percentiles_and_magnitudes':rows}
(OUT/'positive_relations_audit.json').write_text(json.dumps(audit,indent=2),'utf8')
print(json.dumps(audit,indent=2))
