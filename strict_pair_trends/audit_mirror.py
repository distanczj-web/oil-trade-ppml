from pathlib import Path
import json
import numpy as np,pandas as pd
R=Path(__file__).resolve().parent
old=pd.read_csv(R/'reference/mirror.csv').set_index('contrast')
new=pd.read_csv(R/'outputs/mirror/tests.csv').set_index('contrast')
assert np.allclose(old[['b','se','p','ci_low','ci_high']],new[['b','se','p','ci_low','ci_high']],rtol=1e-7,atol=1e-8)
f=pd.read_stata(R/'outputs/mirror/sample_flags.dta',convert_categoricals=False)
d=pd.read_stata(R/'data/mirror_2024.dta',convert_categoricals=False)
assert len(f)==2*len(d)==19974
def keys(v):return v[['ex','im','year']].sort_values(['ex','im','year']).reset_index(drop=True).astype({'year':'int64'})
for source in [0,1]:assert keys(f.loc[f.reporter.eq(source)]).equals(keys(d))
(R/'mirror_validation.json').write_text(json.dumps(dict(passed=True,N_unique=len(d),N_stacked=len(f),scope='Mirror coefficient contrasts and identical positive-flow support; no claim about missing zeros.'),indent=2),'utf8')
print('Mirror contrasts and common support verified')
