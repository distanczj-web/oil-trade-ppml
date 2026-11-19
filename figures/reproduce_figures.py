from pathlib import Path
import json
import numpy as np,pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
R=Path(__file__).resolve().parent;out=R/'verification_outputs';out.mkdir(exist_ok=True)
flow=pd.read_csv(out/'figure_1_reproduced.csv')
frozen=pd.read_csv(R/'figure_1_exact_aggregates.csv')
joined=flow.merge(frozen,on=['flow','year'],validate='one_to_one',suffixes=('_new','_old'))
assert len(joined)==len(flow)==len(frozen) and np.allclose(joined.weight_kg_new,joined.weight_kg_old,rtol=1e-12)
fig,ax=plt.subplots(figsize=(8.2,4.6))
groups=['RUS_EU27','RUS_CHN_IND','MIDDLE_EAST_EU27','USA_EU27']
# Preserve source group codes rather than silently guessing aliases.
groups=list(frozen.flow.drop_duplicates())
labels=['Russia to EU group','Russia to China and India','Middle East to EU group','United States to EU group']
for k,year in enumerate([2021,2023,2024]):
 values=[float(flow.loc[flow.flow.eq(g)&flow.year.eq(year),'weight_kg'].iloc[0])/1e9 for g in groups]
 ax.barh(np.arange(4)+(k-1)*.22,values,height=.22,color=['white','.65','.15'][k],edgecolor='black',hatch='////' if k==0 else None,label=str(year))
 for j,value in enumerate(values):ax.text(value+1,np.arange(4)[j]+(k-1)*.22,f'{value:.1f}',va='center',fontsize=8)
ax.set_yticks(np.arange(4),labels);ax.invert_yaxis();ax.set_xlabel('Net weight, million tonnes');ax.legend(frameon=False);ax.spines[['top','right']].set_visible(False)
fig.tight_layout();fig.savefig(out/'figure_1_reproduced.png',dpi=220);plt.close(fig)
coeff=pd.read_csv(R.parent/'appendix_models/outputs/coefficients.csv')
current=coeff.loc[coeff.group.eq('event')&coeff.term.str.match(r'et20\d\d$')].set_index('term')
old=pd.read_csv(R/'figure_2_unscaled_coefficients.csv').set_index('term')
assert set(old.index)==set(current.index)
assert abs(old.b-current.b).max()<1e-6 and abs(old.se-current.se).max()<1e-5
years=np.array([int(v[2:]) for v in current.index]);order=np.argsort(years);years=years[order]
b=current.b.to_numpy()[order]*.01;se=current.se.to_numpy()[order]*.01
fig,ax=plt.subplots(figsize=(7.8,4.7));ax.axvspan(2021.5,2024.5,color='.94');ax.axhline(0,color='.4',lw=.8)
ax.errorbar(years,b,yerr=1.95996398454*se,fmt='o',capsize=3,color='#253d50',ms=4)
ax.scatter([2021],[0],facecolors='none',edgecolors='#253d50',label='2021 reference not estimated')
ax.set_xticks(range(2017,2025));ax.set_xlabel('Year');ax.set_ylabel('TrendPD × year coefficient per 0.01');ax.set_title('Annual interactions relative to 2021');ax.legend(frameon=False)
ax.spines[['top','right']].set_visible(False);fig.tight_layout();fig.savefig(out/'figure_2_reproduced.png',dpi=220);plt.close(fig)
(out/'plot_verification.json').write_text(json.dumps(dict(figure_1_exact_values_verified=True,figure_2_fresh_annual_coefficients_verified=True,unestimated_reference_year=2021,scale=.01),indent=2),'utf8')
print('Both figures reproduced from verified aggregates and fresh annual estimates')
