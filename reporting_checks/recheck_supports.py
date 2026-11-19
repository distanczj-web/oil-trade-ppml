from pathlib import Path
from types import SimpleNamespace
import ast
import hashlib
import json
import shutil
import sys
import time

ROOT = Path(__file__).resolve().parent
import numpy as np
import pandas as pd
from scipy import sparse
from scipy.optimize import linprog

OLD = ROOT
OUT = ROOT / 'regenerated'
for folder in ['data', 'outputs', 'selection']:
    (OUT / folder).mkdir(parents=True, exist_ok=True)
THRESHOLD = 100_000_000
(OUT / 'design.json').write_text(json.dumps({
    'period':[2017,2021], 'primary_role_minimum_average_annual_recorded_usd':THRESHOLD,
    'dominance':'Use average annual flows from frozen positive import-reported bilateral trade for both directions. Compare outgoing and incoming flows. Assign ties and subthreshold flows to other.',
    'gap_threshold_years':3, 'prespecified_before_estimation':True,
    'RoleI3':'Drop importer gaps only when import-oriented.',
    'RoleB3':'Drop importer gaps when import-oriented or exporter gaps when export-oriented.',
    'frozen_D_comparison':'Apply each rule to original D observations and re-certify finite support. Compare with D rebuilt from the eligible mother sample. Same eligible final support implies the same model, so no synthetic second coefficient.'
}, indent=2), 'utf8')
keys = ['ex','im','year']
terms = ['meanpd5_post','pri5_post','trendpd5_post','distance_post2022']
cols = keys + ['tradevalue','pair_id','ex_year','im_year'] + terms
mother = ROOT / 'data/candidate.dta'
d = pd.read_stata(mother, columns=cols + ['cand_core'], convert_categoricals=False)
base = pd.read_stata(ROOT / 'data/Baseline.dta',columns=cols,convert_categoricals=False)
base_keys = pd.MultiIndex.from_frame(base[keys])
idx = pd.MultiIndex.from_frame(d[keys])
assert idx.is_unique and len(base)==83563
base_mask = idx.isin(base_keys)
countries = sorted(set(d.ex) | set(d.im))
pre = d.loc[d.year.between(2017,2021) & d.tradevalue.gt(0)]
roles = pd.DataFrame(index=pd.Index(countries, name='country'))
roles['mean_import'] = pre.groupby('im').tradevalue.sum().reindex(countries,fill_value=0)/5
roles['mean_export'] = pre.groupby('ex').tradevalue.sum().reindex(countries,fill_value=0)/5
roles['role'] = np.select([(roles.mean_import>=THRESHOLD)&(roles.mean_import>roles.mean_export),
                           (roles.mean_export>=THRESHOLD)&(roles.mean_export>roles.mean_import)],
                          ['import-oriented','export-oriented'], default='other')
gaps = pd.read_csv(OLD / 'selection/country_rules.csv')
for flow in ['M','X']:
    roles[f'gap_{flow}'] = gaps.loc[gaps.flow.eq(flow)].set_index('country').max_missing_run.reindex(countries)
assert roles[['gap_M','gap_X']].notna().all().all()
roles.to_csv(OUT / 'selection/pre_event_roles.csv',encoding='utf-8-sig')
source = ROOT / 'certify_supports.py'
tree = ast.parse(source.read_text('utf8'))
functions = [n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ['hash_frame','prune','certify']]
stages = []
namespace = dict(np=np,pd=pd,sparse=sparse,linprog=linprog,time=time,hashlib=hashlib,d=d,
                 OUT=OUT/'selection',args=SimpleNamespace(bundle='role20261111'),stage=stages)
exec(compile(ast.Module(body=functions,type_ignores=[]),str(source),'exec'),namespace)
previous = pd.read_csv(OLD / '结果对照.csv').set_index('model')
records=[]
fits=[]
pre_value = base.loc[base.year.between(2017,2021),'tradevalue'].sum()
post_value = base.loc[base.year.ge(2022),'tradevalue'].sum()

def certify(mask, model):
    spec=SimpleNamespace(model=model,outcome='tradevalue',terms=' '.join(terms),fe='pair_id ex_year im_year')
    selected, _ = namespace['certify'](mask,spec)
    return d.loc[selected,cols].copy()

def stats(model, frame, importers, exporters, mode):
    matched = frame.loc[pd.MultiIndex.from_frame(frame[keys]).isin(base_keys)]
    return dict(model=model,mode=mode,N=len(frame),pairs=int(frame.pair_id.nunique()),
                positive=int(frame.tradevalue.gt(0).sum()),
                pre_value_pct=100*matched.loc[matched.year.between(2017,2021),'tradevalue'].sum()/pre_value,
                post_value_pct=100*matched.loc[matched.year.ge(2022),'tradevalue'].sum()/post_value,
                removed_countries=len((set(base.im)&importers)|(set(base.ex)&exporters)),
                importers=','.join(sorted(set(base.im)&importers)),exporters=','.join(sorted(set(base.ex)&exporters)))

records.append(stats('Baseline',base,set(),set(),'rebuilt') | {'b':float(previous.loc['Baseline','趋势系数']),'se':float(previous.loc['Baseline','聚类标准误']),'p':float(previous.loc['Baseline','p值'])})
for model in ['I3','I4','I5','B3','B4','B5','RoleI3','RoleB3']:
    threshold=int(model[-1]); role_mode=model.startswith('Role')
    importers=set(roles.index[roles.gap_M.ge(threshold) & (roles.role.eq('import-oriented') if role_mode else True)])
    screen_exports=model.startswith('B') or model.startswith('RoleB')
    exporters=set(roles.index[roles.gap_X.ge(threshold) & (roles.role.eq('export-oriented') if role_mode else True)]) if screen_exports else set()
    eligible=(~d.im.isin(importers)&~d.ex.isin(exporters)).to_numpy()
    if role_mode:
        full=certify(eligible & d.cand_core.eq(1).to_numpy(),model)
        full.to_stata(OUT/f'data/{model}.dta',write_index=False,version=118)
        fits.append(model)
        record=stats(model,full,importers,exporters,'rebuilt')
    else:
        full=pd.read_stata(OLD/f'data/{model}.dta',columns=cols,convert_categoricals=False)
        assert len(full)==previous.loc[model,'最终样本量']
        record=stats(model,full,importers,exporters,'rebuilt') | {'b':float(previous.loc[model,'趋势系数']),'se':float(previous.loc[model,'聚类标准误']),'p':float(previous.loc[model,'p值'])}
    records.append(record)
    frozen=certify(eligible & base_mask,model+'F')
    left = pd.MultiIndex.from_frame(full[keys]); right = pd.MultiIndex.from_frame(frozen[keys])
    same=len(left)==len(right) and left.isin(right).all()
    frozen_record=stats(model+'F',frozen,importers,exporters,'frozen_D') | {'same_support_as':model if same else ''}
    if not same:
        frozen.to_stata(OUT/f'data/{model}F.dta',write_index=False,version=118)
        fits.append(model+'F')
    records.append(frozen_record)
    print(model,record['N'],frozen_record['N'],same,flush=True)

pd.DataFrame(records).to_csv(OUT/'selection/supports.csv',index=False,encoding='utf-8-sig')
pd.DataFrame(stages).to_csv(OUT/'selection/selection_stages.csv',index=False)
