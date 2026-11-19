version 17
args root
clear all
set more off
set processors 2
set linesize 180
cd `"`root'"'
capture mkdir "outputs"
capture mkdir "outputs/standard"
log using "outputs/standard/run.log", text replace
sysdir set PLUS `"`root'/ado/"'
adopath ++ `"`root'/ado"'
ppmlhdfe, version
tempname h
postfile `h' str12 model str32 term double b se p long N using "outputs/standard/coefficients.dta", replace
foreach model in Baseline I3 I4 I5 B3 B4 B5 RoleI3 RoleB3 {
use "data/`model'.dta", clear
isid ex im year
local expected=_N
capture mkdir "outputs/standard/`model'"
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022, absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==`expected'
assert e(sample)==1
estimates save "outputs/standard/`model'/estimates.ster", replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("`model'") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N))
}
save "outputs/standard/`model'/analysis_ready.dta", replace
}
postclose `h'
use "outputs/standard/coefficients.dta", clear
export delimited using "outputs/standard/coefficients.csv", replace
display "EXPERIMENT_COMPLETE_standard"
log close
