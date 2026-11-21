"""Audit World-total-only importer-years without changing the frozen baseline."""
from pathlib import Path
from hashlib import sha256
import json
import numpy as np
import pandas as pd

ROOT=Path(__file__).resolve().parent
REP=ROOT.parent
# The optional argument lets the staged module use the existing restored inputs.
import sys
if len(sys.argv)>1:
    REP=Path(sys.argv[1]).resolve()
OUT=ROOT/'outputs'
OUT.mkdir(exist_ok=True)
raw=pd.read_csv(ROOT/'data/import_source_records.csv.gz')
source_manifest=json.loads((ROOT/'data/source_manifest.json').read_text('utf8'))
assert sha256((ROOT/'data/import_source_records.csv.gz').read_bytes()).hexdigest()==source_manifest['csv_gzip_sha256']
assert not raw.duplicated(['country','year','partner']).any()
assert np.isfinite(raw.raw_value).all() and raw.raw_value.ge(0).all()
raw['valid_bilateral']=raw.partner_valid_country.eq(1)
raw['positive_bilateral']=raw.valid_bilateral & raw.raw_value.gt(0)
raw['world_value']=raw.raw_value.where(raw.partner_world.eq(1),0)
g=raw.groupby(['country','year']).agg(records=('raw_value','size'),
    valid_bilateral_records=('valid_bilateral','sum'),
    positive_bilateral_records=('positive_bilateral','sum'),
    world_value=('world_value','sum')).reset_index()
g['world_positive_no_bilateral']=g.world_value.gt(0)&g.valid_bilateral_records.eq(0)
g['world_positive_no_positive_bilateral']=g.world_value.gt(0)&g.positive_bilateral_records.eq(0)
g.to_csv(OUT/'importer_year_detail.csv',index=False)
cases=g.loc[g.world_positive_no_bilateral].copy()
cases.to_csv(OUT/'world_only_cases.csv',index=False)
mother=pd.read_stata(REP/'reporting_checks/data/candidate.dta',
    columns=['ex','im','year','tradevalue','cand_core'],convert_categoricals=False)
baseline=pd.read_stata(REP/'main_models/data/ABCD.dta',columns=['ex','im','year','tradevalue'],convert_categoricals=False)
universe=set(mother.ex)|set(mother.im)
assert (raw.partner.isin(universe)&raw.country.ne(raw.partner)).equals(raw.valid_bilateral)
assert raw.partnerCode.eq(0).equals(raw.partner_world.eq(1))
lookup=pd.MultiIndex.from_frame(cases[['country','year']])
broader=pd.MultiIndex.from_frame(g.loc[g.world_positive_no_positive_bilateral,['country','year']])
rows=[]
for name,frame in [('Initial panel',mother),('Final Model D',baseline)]:
    ix=pd.MultiIndex.from_frame(frame[['im','year']])
    strict=ix.isin(lookup)
    broad=ix.isin(broader)
    rows.append({'sample':name,'N':len(frame),'strict_affected_rows':int(strict.sum()),
                 'strict_affected_positive':int((strict&frame.tradevalue.gt(0)).sum()),
                 'strict_affected_value':float(frame.loc[strict,'tradevalue'].sum()),
                 'broad_affected_rows':int(broad.sum()),'retained_N_strict':int((~strict).sum())})
pd.DataFrame(rows).to_csv(OUT/'world_only_sample_comparison.csv',index=False)
annual=g.groupby('year').agg(importer_years=('country','size'),world_only=('world_positive_no_bilateral','sum'),
    no_positive_bilateral=('world_positive_no_positive_bilateral','sum')).reset_index()
annual.to_csv(OUT/'world_only_by_year.csv',index=False)
audit={'raw_import_records':len(raw),'importer_years':len(g),'strict_cases':len(cases),
       'broader_no_positive_cases':int(g.world_positive_no_positive_bilateral.sum()),
       'strict_countries':int(cases.country.nunique()),'strict_pre2022_cases':int(cases.year.lt(2022).sum()),
       'strict_post2022_cases':int(cases.year.ge(2022).sum()),'samples':rows,
       'interpretation':'Source reporting presence does not establish complete bilateral detail. This audit does not recode trade values.',
       'baseline_same_observations':rows[-1]['strict_affected_rows']==0,
       'baseline_broader_same_observations':rows[-1]['broad_affected_rows']==0}
(OUT/'world_only_audit.json').write_text(json.dumps(audit,indent=2),'utf8')
print(json.dumps(audit,indent=2))
