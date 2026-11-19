"""Audit the seven freshly estimated principal models, without refitting."""
from pathlib import Path
import hashlib,json
import numpy as np
import pandas as pd
R=Path(__file__).resolve().parent
frozen=json.loads((R/'input_manifest.json').read_text('utf8'))
for name,digest in frozen.items():
    assert hashlib.sha256((R/name).read_bytes()).hexdigest()==digest,name
assert 'MAIN_MODELS_COMPLETE' in (R/'outputs/run.log').read_text('utf8',errors='replace')
old=pd.read_csv(R/'reference/coefficients.csv')
new=pd.read_csv(R/'outputs/coefficients.csv')
assert not old.duplicated(['model','term']).any() and not new.duplicated(['model','term']).any()
joined=old.merge(new,on=['model','term'],suffixes=('_old','_new'),validate='one_to_one',how='outer',indicator=True)
assert joined['_merge'].eq('both').all()
assert joined.converged_new.eq(1).all() and joined.N_new.eq(joined.N_old).all()
assert np.isfinite(joined[['b_new','se_new','p_new']]).all().all()
report=[]
for model,g in joined.groupby('model',sort=False):
    be=float(abs(g.b_new-g.b_old).max());se=float(abs(g.se_new-g.se_old).max())
    assert be<1e-6 and se<1e-5,(model,be,se)
    report.append(dict(model=model,N=int(g.N_new.iloc[0]),regressors=len(g),coefficient_max_difference=be,SE_max_difference=se,passed=True))
(R/'outputs/verification.json').write_text(json.dumps(dict(models=report,input_hashes_unchanged=True,scope='Estimation on frozen final supports, not reconstruction from original downloads.'),indent=2),'utf8')
print(json.dumps(report,indent=2))
