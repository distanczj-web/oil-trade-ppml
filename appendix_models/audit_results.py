from pathlib import Path
import json,hashlib
import numpy as np,pandas as pd
R=Path(__file__).resolve().parent
for name,digest in json.loads((R/'input_manifest.json').read_text('utf8')).items():assert hashlib.sha256((R/name).read_bytes()).hexdigest()==digest,name
log=R/'outputs/run.log'
batch_logs=[R/f'outputs/batch_{k}/run.log' for k in [1,2,3]]
batched=all(p.exists() for p in batch_logs) and max(p.stat().st_mtime for p in batch_logs)>log.stat().st_mtime
if batched:
 for k,p in enumerate(batch_logs,1):assert f'APPENDIX_BATCH_{k}_COMPLETE' in p.read_text('utf8',errors='replace'),p
 new=pd.concat([pd.read_csv(R/f'outputs/batch_{k}/coefficients.csv') for k in [1,2,3]],ignore_index=True)
 new.to_csv(R/'outputs/coefficients.csv',index=False)
else:
 assert 'APPENDIX_ORDINARY_MODELS_COMPLETE' in log.read_text('utf8',errors='replace')
 new=pd.read_csv(R/'outputs/coefficients.csv')
old=pd.read_csv(R/'reference/coefficients.csv')
keys=['group','model','term']
assert not old.duplicated(keys).any() and not new.duplicated(keys).any()
d=old.merge(new,on=keys,how='outer',suffixes=('_old','_new'),validate='one_to_one',indicator=True)
assert d['_merge'].eq('both').all() and d.converged_new.eq(1).all() and d.N_old.eq(d.N_new).all()
assert np.isfinite(d[['b_new','se_new','p_new']]).all().all()
report=[]
for (group,model),g in d.groupby(['group','model'],sort=False):
 be=float(abs(g.b_new-g.b_old).max());se=float(abs(g.se_new-g.se_old).max())
 assert be<1e-6 and se<1e-5,(group,model,be,se)
 report.append(dict(group=group,model=model,N=int(g.N_new.iloc[0]),coefficient_max_difference=be,SE_max_difference=se,passed=True))
assert len(report)==80
annual=pd.read_csv(R/'outputs/annual_tests.csv').set_index('test')
assert abs(annual.loc['trajectory_pre_joint','p']-.0988934719128902)<1e-8
assert abs(annual.loc['trajectory_post_equality','p']-.0191524898056151)<1e-8
assert annual.N.eq(19208).all()
(R/'outputs/verification.json').write_text(json.dumps(dict(model_count=len(report),execution='Three batches, reusing freshly completed estimates' if batched else 'Sequential',models=report,scope='Existing ordinary appendix models on certified frozen supports; not a raw-download reconstruction.'),indent=2),'utf8')
print('Verified',len(report),'ordinary appendix models')
