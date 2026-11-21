version 17
args root rep
if `"`root'"'=="" local root `"`c(pwd)'"'
if `"`rep'"'=="" local rep `"`root'/.."'
clear all
set more off
set processors 2
cd `"`root'"'
capture mkdir outputs
log using "outputs/positive_relations.log",text replace
adopath ++ `"`rep'/new_checks/ado"'
use `"`rep'/new_checks/供应关系异质性/input.dta"',clear
keep if dependence>0 & dependence<.
isid ex im year
local candidates=_N
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022 dependence_post trend_dependence_post, absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1
keep if e(sample)
save "outputs/positive_input.dta",replace
tempname std
postfile `std' str32 term double b double se double p long N using "outputs/positive_standard.dta",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 dependence_post trend_dependence_post {
    post `std' ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N))
}
postclose `std'
preserve
use "outputs/positive_standard.dta",clear
export delimited using "outputs/positive_standard.csv",replace
restore
do "six_regressor_core.do"
egen long __op_p=group(pair_id)
egen long __op_e=group(ex_year)
egen long __op_i=group(im_year)
gen double op_eta=.
gen double op_mu=.
cd outputs
oil_sparse_ppml,trend(0) maxiter(150)
assert e(converged)==1 & e(N)==_N & e(local_margin_relative_error)<1e-8
save "positive_predictions.dta",replace
tempname custom
postfile `custom' str32 term double b double se double p long N using "positive_custom.dta",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 dependence_post trend_dependence_post {
    post `custom' ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N))
}
postclose `custom'
matrix FullV=e(V)
clear
svmat double FullV,names(col)
save "positive_covariance.dta",replace
export delimited using "positive_covariance.csv",replace
use "positive_custom.dta",clear
export delimited using "positive_custom.csv",replace
display "POSITIVE_RELATIONS_COMPLETE candidates=`candidates'"
log close
