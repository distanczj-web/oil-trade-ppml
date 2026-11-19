from pathlib import Path
import argparse,json
import numpy as np,pandas as pd
ROOT=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--mother',type=Path,default=ROOT.parents[2]/'01_回归数据/扩展检验母样本_2000至2024.dta');args=ap.parse_args()
audit=json.loads((ROOT/'flow_coverage_audit.json').read_text('utf8'))
YEARS=[2021,2023,2024]
d=pd.read_stata(args.mother,columns=['ex','im','year','tradevalue','importnetwgt'],convert_categoricals=False)
d=d.loc[d.year.isin(YEARS)].copy();assert not d.duplicated(['ex','im','year']).any()
common=set.intersection(*[set(d.loc[d.year.eq(y),'im']) for y in YEARS])
assert len(common)==94 and common==set(audit['common_reporter_codes'])
eu=set(audit['eu27_in_common']);me=set(audit['middle_east_codes']);assert len(eu)==26 and len(me)==14
selected=d.loc[d.im.isin(common)].copy();assert selected.groupby(['ex','im']).year.nunique().eq(3).all()
invalid=selected.loc[selected.tradevalue.gt(0)&~(np.isfinite(selected.importnetwgt)&selected.importnetwgt.gt(0)),['ex','im']].drop_duplicates()
selected=selected.merge(invalid.assign(excluded=True),on=['ex','im'],how='left',validate='many_to_one')
matched=selected.loc[selected.excluded.isna()].copy()
matched['matched_weight']=matched.importnetwgt.where(matched.tradevalue.gt(0),0)
groups=[('RUS_EU27',{'RUS'},eu),('RUS_CHN_IND',{'RUS'},{'CHN','IND'}),('ME_EU27',me,eu),('USA_EU27',{'USA'},eu)]
rows=[];excluded=[]
for code,exports,imports in groups:
 bad=selected.loc[selected.excluded.eq(True)&selected.ex.isin(exports)&selected.im.isin(imports),['ex','im']].drop_duplicates()
 excluded.extend([dict(flow=code,ex=ex,im=im) for ex,im in bad.itertuples(index=False,name=None)])
 for year in YEARS:
  s=matched.loc[matched.year.eq(year)&matched.ex.isin(exports)&matched.im.isin(imports)]
  assert s.matched_weight.notna().all()
  rows.append(dict(flow=code,year=year,amount_usd=float(s.tradevalue.sum()),weight_kg=float(s.matched_weight.sum()),positive_links=int(s.tradevalue.gt(0).sum())))
result=pd.DataFrame(rows).sort_values(['flow','year']).reset_index(drop=True)
reference=pd.read_csv(ROOT/'figure_1_exact_aggregates.csv').sort_values(['flow','year']).reset_index(drop=True)
assert result[['flow','year']].equals(reference[['flow','year']])
assert np.allclose(result[['amount_usd','weight_kg','positive_links']],reference[['amount_usd','weight_kg','positive_links']],rtol=1e-12,atol=.01)
assert {tuple(sorted(v.items())) for v in excluded}=={tuple(sorted(v.items())) for v in audit['excluded_mass_pairs']}
assert len(excluded)==6
out=ROOT/'verification_outputs';out.mkdir(exist_ok=True)
result.to_csv(out/'figure_1_reproduced.csv',index=False)
report=dict(common_reporters=94,eu_members=26,middle_east_definition=14,excluded_flow_pairs=excluded,exact_aggregates_match=True,no_model_estimated=True,original_data_read_only=True)
(out/'flow_verification.json').write_text(json.dumps(report,indent=2),'utf8');print(json.dumps(report,indent=2))
