version 17
args root
if `"`root'"'=="" local root `"`c(pwd)'"'
clear all
set more off
set processors 2
set linesize 160
cd `"`root'"'
capture mkdir "outputs"
log using "outputs/run.log",text replace
sysdir set PLUS `"`root'/ado/"'
adopath ++ `"`root'/ado"'
ppmlhdfe,version
tempname h
postfile `h' str8 model str32 term double b double se double p long N byte converged using "outputs/coefficients.dta",replace
use "data/M1.dta",clear
isid ex im year
assert _N==352005
ppmlhdfe tradevalue politicaldistance_l1 ln_distance contig comlang_off colony,absorb(ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/M1.ster",replace
foreach term in politicaldistance_l1 ln_distance contig comlang_off colony {
post `h' ("M1") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "data/M2.dta",clear
isid ex im year
assert _N==83563
ppmlhdfe tradevalue pd2021_post2022 distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/M2.ster",replace
foreach term in pd2021_post2022 distance_post2022 {
post `h' ("M2") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "data/M3.dta",clear
isid ex im year
assert _N==82760
ppmlhdfe tradevalue politicaldistance_l1 pdl1_post2022 distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/M3.ster",replace
foreach term in politicaldistance_l1 pdl1_post2022 distance_post2022 {
post `h' ("M3") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "data/ABCD.dta",clear
isid ex im year
assert _N==83563
ppmlhdfe tradevalue meanpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/A.ster",replace
foreach term in meanpd5_post distance_post2022 {
post `h' ("A") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "data/ABCD.dta",clear
isid ex im year
assert _N==83563
ppmlhdfe tradevalue pri5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/B.ster",replace
foreach term in pri5_post distance_post2022 {
post `h' ("B") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "data/ABCD.dta",clear
isid ex im year
assert _N==83563
ppmlhdfe tradevalue meanpd5_post pri5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/C.ster",replace
foreach term in meanpd5_post pri5_post distance_post2022 {
post `h' ("C") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "data/ABCD.dta",clear
isid ex im year
assert _N==83563
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/D.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("D") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
postclose `h'
use "outputs/coefficients.dta",clear
export delimited using "outputs/coefficients.csv",replace
display "MAIN_MODELS_COMPLETE"
log close
