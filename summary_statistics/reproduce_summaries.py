from pathlib import Path
import math
import numpy as np
import pandas as pd

HERE = Path(__file__).resolve().parent
ROOT = HERE / 'reproduced'
ROOT.mkdir(exist_ok=True)
folder = HERE / 'supplier'

def collect():
    pairs = pd.read_stata(HERE / 'political_history_by_pair.dta', convert_categoricals=False)
    available = list(pairs.columns[2:])
    assert len(pairs) == 4112 and not pairs.duplicated(['ex','im']).any()
    observations = pd.read_stata(folder/'input.dta',columns=['dependence'],convert_categoricals=False)
    betas = pd.read_stata(folder/'results.dta',convert_categoricals=False).set_index('term')
    covariance = pd.read_stata(folder/'covariance.dta',convert_categoricals=False)
    assert len(observations)==75316
    assert np.allclose(np.sqrt(np.diag(covariance)),betas.loc[list(covariance.columns),'se'],atol=1e-6)
    names = ['trendpd5_post','trend_dependence_post']
    positions = [list(covariance.columns).index(name) for name in names]
    cov = covariance.to_numpy()[np.ix_(positions,positions)]
    qs = [(f'P{int(q*100)}',float(observations.dependence.quantile(q))) for q in [.5,.75,.9]]
    qs += [('High share',.10),('High share',.25)]
    supplier = []
    for label,share in qs:
        weights = np.array([1,share])
        b = float(weights @ betas.loc[names,'b'].to_numpy())
        se = math.sqrt(float(weights @ cov @ weights))
        pct = [100*math.expm1(.01*value) for value in [b,b-1.95996398454*se,b+1.95996398454*se]]
        supplier.append(dict(label=label,share=share,b=b,se=se,pct=pct[0],low=pct[1],high=pct[2]))
    pd.DataFrame(supplier).to_csv(ROOT / 'supplier_quantiles.csv',index=False)

    summaries = []
    for label,term in zip(['MeanPD','PRI','TrendPD'],available):
        v = pairs[term]
        summaries.append(dict(measure=label,mean=v.mean(),sd=v.std(),p25=v.quantile(.25),median=v.median(),p75=v.quantile(.75),iqr=v.quantile(.75)-v.quantile(.25)))
    pd.DataFrame(summaries).to_csv(ROOT/'pair_weighted.csv',index=False)
    corr = pairs[available].corr().to_numpy().tolist()
    for name in ['supplier_quantiles.csv', 'pair_weighted.csv']:
        pd.testing.assert_frame_equal(pd.read_csv(HERE / name), pd.read_csv(ROOT / name), check_exact=False)
    print('Supplier percentiles and equal-pair statistics match the manuscript inputs.')

if __name__ == '__main__':
    collect()
