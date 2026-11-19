version 17
args project
clear all
set more off
capture set processors 2
cd `"`project'"'
capture mkdir "outputs"
capture mkdir "outputs/mirror"
log using "outputs/mirror/run.log",text replace
sysdir set PLUS `"`project'/ado/"'
adopath ++ `"`project'/ado"'
use "data/mirror_2024.dta",clear
isid ex im year
assert importvalue>0 & mirrorexportvalue>0
local oneN=_N
expand 2,generate(reporter)
gen double stacked_value=cond(reporter==0,importvalue,mirrorexportvalue)
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
    gen double d_`term'=reporter*`term'
}
egen long source_pair=group(reporter pair_id)
egen long source_exyear=group(reporter ex_year)
egen long source_imyear=group(reporter im_year)
ppmlhdfe stacked_value meanpd5_post pri5_post trendpd5_post distance_post2022 d_meanpd5_post d_pri5_post d_trendpd5_post d_distance_post2022, absorb(source_pair source_exyear source_imyear) vce(cluster pair_id) tolerance(1e-10) use_exact_solver(1) maxiter(300)
assert e(N)==2*`oneN' & e(converged)==1
assert e(sample)==1
estimates save "outputs/mirror/estimates.ster",replace
tempname h
postfile `h' str32 contrast double b double se double p double ci_low double ci_high long N long pairs using "outputs/mirror/tests.dta",replace
lincom trendpd5_post
post `h' ("import") (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (e(N)) (e(N_clust))
lincom trendpd5_post+d_trendpd5_post
post `h' ("export") (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (e(N)) (e(N_clust))
lincom d_trendpd5_post
post `h' ("export_minus_import") (r(estimate)) (r(se)) (r(p)) (r(lb)) (r(ub)) (e(N)) (e(N_clust))
postclose `h'
keep ex im year reporter
save "outputs/mirror/sample_flags.dta",replace
use "outputs/mirror/tests.dta",clear
export delimited using "outputs/mirror/tests.csv",replace
display "PORTABLE_MIRROR_COMPLETED"
log close
