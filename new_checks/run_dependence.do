version 17
args root
if `"`root'"'=="" local root `"`c(pwd)'"'
clear all
set more off
set processors 2
cd `"`root'/供应关系异质性"'
log using "run.log",text replace
do "six_regressor_core.do"
use "input.dta",clear
egen long __op_p=group(pair_id)
egen long __op_e=group(ex_year)
egen long __op_i=group(im_year)
gen double op_eta=.
gen double op_mu=.
oil_sparse_ppml,trend(0) maxiter(150)
assert e(converged)==1 & e(N)==_N & e(local_margin_relative_error)<1e-8
estimates save "model.ster",replace
tempname h
postfile `h' str32 term double b se p N using "results.dta",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 dependence_post trend_dependence_post {
    post `h' ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N))
}
postclose `h'
save "validated_predictions.dta",replace
matrix FullV=e(V)
clear
svmat double FullV,names(col)
save "covariance.dta",replace
use "results.dta",clear
export delimited using "results.csv",replace
local ado "`root'/ado"
adopath ++ `"`ado'"'
use "input.dta",clear
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022 dependence_post trend_dependence_post,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-10) use_exact_solver(1) maxiter(500)
assert e(N)==_N & e(converged)==1
tempname h2
postfile `h2' str32 term double b se p N using "standard_results.dta",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 dependence_post trend_dependence_post {
    post `h2' ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N))
}
postclose `h2'
use "standard_results.dta",clear
export delimited using "standard_results.csv",replace
display "DEPENDENCE_COMPLETE"
log close
