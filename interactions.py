"""Rebuild the main and appendix interaction columns and compare frozen inputs."""
from pathlib import Path
import json

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent
KEYS = ['ex', 'im', 'year']
STEMS = ('meanpd5', 'pri5', 'trendpd5', 'meanpd10', 'pri10', 'trendpd10',
         'sdpd5', 'endpoint', 'annualendpoint', 'rawmean', 'rawpri',
         'rawtrend', 'tradepretrend')
BASE = ['ln_distance', 'pd2021', 'politicaldistance_l1', *STEMS]
ANNUAL_YEARS = (2017, 2018, 2019, 2020, 2022, 2023, 2024)


def comparisons():
    post = [(term + '_post', term, 2022, False) for term in STEMS]
    post += [('pd2021_post2022', 'pd2021', 2022, False),
             ('distance_post2022', 'ln_distance', 2022, False),
             ('pdl1_post2022', 'politicaldistance_l1', 2022, False)]
    later = [(label, term, 2023, False) for label, term in
             zip(('mean23', 'pri23', 'trend23', 'dist23'),
                 ('meanpd5', 'pri5', 'trendpd5', 'ln_distance'))]
    annual = [(prefix + str(year), term, year, True) for year in ANNUAL_YEARS
              for prefix, term in zip(('em', 'ep', 'et', 'eg'),
                                      ('meanpd5', 'pri5', 'trendpd5', 'ln_distance'))]
    return post + later + annual


def run():
    plan = comparisons()
    columns = [term for term, *_ in plan]
    panel = pd.read_stata(ROOT / 'appendix_models/data/regression_panel.dta',
                          convert_categoricals=False)
    assert not panel.duplicated(KEYS).any()
    checks = {}
    for term, parent, year, exact in plan:
        indicator = panel.year.eq(year) if exact else panel.year.ge(year)
        observed = panel[term].to_numpy()
        rebuilt = (panel[parent] * indicator).to_numpy()
        np.testing.assert_allclose(rebuilt, observed, atol=2e-7, rtol=2e-7,
                                   equal_nan=True, err_msg=term)
        checks[term] = float(np.nanmax(np.abs(rebuilt - observed)))
    for model in ['M2', 'M3', 'ABCD']:
        archived = pd.read_stata(ROOT / f'main_models/data/{model}.dta', convert_categoricals=False)
        used = sorted(set(columns).intersection(archived.columns))
        aligned = archived[KEYS + used].merge(panel[KEYS + used], on=KEYS,
             how='left', validate='one_to_one', suffixes=('_fit', '_panel'), indicator=True)
        assert aligned['_merge'].eq('both').all()
        for name in used:
            np.testing.assert_allclose(aligned[name+'_fit'], aligned[name+'_panel'],
                                       atol=2e-7, rtol=2e-7, err_msg=model + ' ' + name)
    report = dict(panel_rows=len(panel), variables=len(checks), max_abs_difference=checks,
                  note='Frozen estimation inputs retain the archived floating-point storage.')
    (ROOT / 'interaction_audit.json').write_text(json.dumps(report, indent=2), 'utf8')
    print('Verified', len(checks), 'interaction columns and alignment with M2, M3 and A–D.')


if __name__ == '__main__':
    run()
