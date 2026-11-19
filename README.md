# Political Relationship Trajectories and Global Crude Oil Trade Reconfiguration after 2022

Replication data and code accompanying the manuscript by 查健.

The analysis uses annual bilateral crude oil trade records for 2000–2024 and political histories constructed from 2017–2021. The supplied inputs are frozen estimation samples and archived source records. Data provenance is recorded in `数据来源.txt`. Detailed estimation commands and numerical tolerances are in `README.txt` and the individual modules.

## Restore the data

Python 3.12 and the standard library are sufficient for this step. Run these commands from the repository directory.

```text
python restore_data.py
python restore_data.py --verify-only
python -m pip install -r strict_refinement/requirements-python.txt
```

Binary data are stored in 4 MiB compressed parts under `data_archive`. The restoration script verifies every part and restores the original Stata, NumPy and compiled dependency files to the paths expected by the estimation scripts. Existing files with different checksums are reported. The `--force` option replaces those files with the frozen copies.

## Run the principal models

Use Stata/MP 18 with the supplied version-17 syntax. In Stata, change the working directory to `main_models`, then run the following command.

```stata
do run_all.do
```

After estimation, run `python main_models/audit_results.py` from the repository directory. The seven specifications cover M1–M3 and models A–D on their frozen final samples.

## Additional analyses

- `appendix_models` contains the 80 ordinary appendix specifications and final-support flags. Its frozen panel is restored to `appendix_models/data/regression_panel.dta`.
- `reporting_checks` contains the baseline and eight pre-event reporting restrictions, including the trade-role checks and matched-sample comparisons.
- `new_checks` contains historical pseudo-events, joint Wald tests and supplier-importance interactions.
- `source_checks` contains reporting-source and estimated-net-weight restrictions.
- `strict_refinement` and `strict_pair_trends` contain the sparse pair-trend solver, frozen inputs, cold-start logs, covariance diagnostics and independent numerical audits.
- `summary_statistics` reproduces supplier-share percentiles and equal-pair political-history statistics.
- `figures` reproduces the matched physical-flow aggregates and the two figures.

The strict pair-trend results use the independently audited custom solver. The standard `ppmlhdfe` implementation has an unresolved numerical limitation for that specification, documented in the manuscript appendix. The scope and stopping criteria are recorded with the solver outputs.

`SHA256.json` records the files supplied in the original replication package. Third-party software licences are retained in the relevant `licenses` directories. `restore_data.py --verify-only` checks both restored data and the original replication files. Verify the frozen package before estimation, and rerun the models in a separate working copy because the estimation scripts replace their output files. `.gitattributes` preserves the archived file bytes when cloning on different operating systems.
