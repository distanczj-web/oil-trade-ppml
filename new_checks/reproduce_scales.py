from pathlib import Path
import numpy as np,pandas as pd
R=Path(__file__).resolve().parent
d=pd.read_stata(R/'common_histories.dta');assert len(d)==83563
s=d[['meanpd5','pri5','trendpd5']].describe(percentiles=[.25,.5,.75]).T
c=pd.read_stata(R/'stored_estimates/ABCD_statistics.dta');c=c.loc[c.model.eq('D')].set_index('term')
effects=[]
for v in s.index:
 b=float(c.loc[v+'_post','b']);se=float(c.loc[v+'_post','se'])
 for scale,value in [('IQR',s.loc[v,'75%']-s.loc[v,'25%']),('SD',s.loc[v,'std'])]:
  effects.append(dict(variable=v,scale=scale,increment=value,effect_pct=100*np.expm1(b*value),low_pct=100*np.expm1((b-1.95996398454*se)*value),high_pct=100*np.expm1((b+1.95996398454*se)*value)))
result=pd.DataFrame(effects);reference=pd.read_csv(R/'维度比较/economic_scales.csv')
assert np.allclose(result.select_dtypes('number'),reference.select_dtypes('number'),atol=1e-5,rtol=1e-7)
(R/'descriptive_outputs').mkdir(exist_ok=True)
s.to_csv(R/'descriptive_outputs/summary.csv')
d[['meanpd5','pri5','trendpd5']].corr().to_csv(R/'descriptive_outputs/correlations.csv')
result.to_csv(R/'descriptive_outputs/economic_scales.csv',index=False)
print('COMMON_SAMPLE_SCALES_VERIFIED',len(d))
