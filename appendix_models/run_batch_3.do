version 17
args root mother
if `"`root'"'=="" local root `"`c(pwd)'"'
clear all
set more off
set processors 2
set linesize 160
cd `"`root'"'
if `"`mother'"'=="" local mother "../../../01_回归数据/扩展检验母样本_2000至2024.dta"
capture mkdir "outputs"
log using "outputs/batch_3/run.log",text replace
sysdir set PLUS "../main_models/ado/"
adopath ++ "../main_models/ado"
use annualendpoint_post dist23 distance_post2022 eg2017 eg2018 eg2019 eg2020 eg2022 eg2023 eg2024 em2017 em2018 em2019 em2020 em2022 em2023 em2024 endpoint_post ep2017 ep2018 ep2019 ep2020 ep2022 ep2023 ep2024 et2017 et2018 et2019 et2020 et2022 et2023 et2024 ex ex_year im im_year importnetwgt mean23 meanpd10_post meanpd5_post pair_id pri10_post pri23 pri5_post rawmean_post rawpri_post rawtrend_post sdpd5_post tradepretrend_post tradevalue trend23 trendpd10_post trendpd5_post year using `"`mother'"',clear
isid ex im year
tempfile mothercopy
save `mothercopy'
tempname h
postfile `h' str32 group str40 model str32 term double b double se double p long N byte converged using "outputs/batch_3/coefficients.dta",replace
use "supports/endpoint.dta",clear
keep if cert_EndpointOnly==1
keep ex im year
isid ex im year
assert _N==83563
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==83563
estimates use "outputs/endpoint__EndpointOnly.ster"
assert e(N)==_N & e(converged)==1
foreach term in endpoint_post distance_post2022 {
post `h' ("endpoint") ("EndpointOnly") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/endpoint.dta",clear
keep if cert_EndpointAnnual==1
keep ex im year
isid ex im year
assert _N==83563
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==83563
estimates use "outputs/endpoint__EndpointAnnual.ster"
assert e(N)==_N & e(converged)==1
foreach term in meanpd5_post pri5_post annualendpoint_post distance_post2022 {
post `h' ("endpoint") ("EndpointAnnual") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/pretrade.dta",clear
keep if cert_WithPreTrade==1
keep ex im year
isid ex im year
assert _N==42544
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==42544
estimates use "outputs/pretrade__WithPreTrade.ster"
assert e(N)==_N & e(converged)==1
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 tradepretrend_post {
post `h' ("pretrade") ("WithPreTrade") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/measurement.dta",clear
keep if cert_IdealMatched==1
keep ex im year
isid ex im year
assert _N==82252
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==82252
estimates use "outputs/measurement__IdealMatched.ster"
assert e(N)==_N & e(converged)==1
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("measurement") ("IdealMatched") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_ALL.dta",clear
keep if cert_DualIP_ALL==1
keep ex im year
isid ex im year
assert _N==82252
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==82252
estimates use "outputs/dual_ALL__DualIP_ALL.ster"
assert e(N)==_N & e(converged)==1
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_ALL") ("DualIP_ALL") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_AGO.dta",clear
keep if cert_DualIP_AGO==1
keep ex im year
isid ex im year
assert _N==80704
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80704
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_AGO__DualIP_AGO.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_AGO") ("DualIP_AGO") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_ARE.dta",clear
keep if cert_DualIP_ARE==1
keep ex im year
isid ex im year
assert _N==78981
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78981
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_ARE__DualIP_ARE.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_ARE") ("DualIP_ARE") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_CAN.dta",clear
keep if cert_DualIP_CAN==1
keep ex im year
isid ex im year
assert _N==78730
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78730
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_CAN__DualIP_CAN.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_CAN") ("DualIP_CAN") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_CHN.dta",clear
keep if cert_DualIP_CHN==1
keep ex im year
isid ex im year
assert _N==78104
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78104
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_CHN__DualIP_CHN.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_CHN") ("DualIP_CHN") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_DEU.dta",clear
keep if cert_DualIP_DEU==1
keep ex im year
isid ex im year
assert _N==78693
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78693
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_DEU__DualIP_DEU.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_DEU") ("DualIP_DEU") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_ESP.dta",clear
keep if cert_DualIP_ESP==1
keep ex im year
isid ex im year
assert _N==78543
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78543
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_ESP__DualIP_ESP.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_ESP") ("DualIP_ESP") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_GBR.dta",clear
keep if cert_DualIP_GBR==1
keep ex im year
isid ex im year
assert _N==78158
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78158
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_GBR__DualIP_GBR.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_GBR") ("DualIP_GBR") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_IND.dta",clear
keep if cert_DualIP_IND==1
keep ex im year
isid ex im year
assert _N==79345
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==79345
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_IND__DualIP_IND.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_IND") ("DualIP_IND") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_IRQ.dta",clear
keep if cert_DualIP_IRQ==1
keep ex im year
isid ex im year
assert _N==81039
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==81039
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_IRQ__DualIP_IRQ.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_IRQ") ("DualIP_IRQ") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_ITA.dta",clear
keep if cert_DualIP_ITA==1
keep ex im year
isid ex im year
assert _N==78878
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78878
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_ITA__DualIP_ITA.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_ITA") ("DualIP_ITA") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_JPN.dta",clear
keep if cert_DualIP_JPN==1
keep ex im year
isid ex im year
assert _N==79725
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==79725
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_JPN__DualIP_JPN.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_JPN") ("DualIP_JPN") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_KOR.dta",clear
keep if cert_DualIP_KOR==1
keep ex im year
isid ex im year
assert _N==79054
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==79054
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_KOR__DualIP_KOR.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_KOR") ("DualIP_KOR") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_KWT.dta",clear
keep if cert_DualIP_KWT==1
keep ex im year
isid ex im year
assert _N==81232
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==81232
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_KWT__DualIP_KWT.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_KWT") ("DualIP_KWT") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_NGA.dta",clear
keep if cert_DualIP_NGA==1
keep ex im year
isid ex im year
assert _N==80215
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80215
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_NGA__DualIP_NGA.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_NGA") ("DualIP_NGA") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_NLD.dta",clear
keep if cert_DualIP_NLD==1
keep ex im year
isid ex im year
assert _N==77144
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==77144
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_NLD__DualIP_NLD.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_NLD") ("DualIP_NLD") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_NOR.dta",clear
keep if cert_DualIP_NOR==1
keep ex im year
isid ex im year
assert _N==80494
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80494
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_NOR__DualIP_NOR.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_NOR") ("DualIP_NOR") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_RUS.dta",clear
keep if cert_DualIP_RUS==1
keep ex im year
isid ex im year
assert _N==79658
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==79658
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_RUS__DualIP_RUS.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_RUS") ("DualIP_RUS") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_SAU.dta",clear
keep if cert_DualIP_SAU==1
keep ex im year
isid ex im year
assert _N==80827
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80827
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_SAU__DualIP_SAU.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_SAU") ("DualIP_SAU") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_USA.dta",clear
keep if cert_DualIP_USA==1
keep ex im year
isid ex im year
assert _N==76263
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==76263
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_USA__DualIP_USA.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_USA") ("DualIP_USA") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/sensitivity_Votes50.dta",clear
keep if cert_Votes50==1
keep ex im year
isid ex im year
assert _N==80931
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80931
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/sensitivity_Votes50__Votes50.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("sensitivity_Votes50") ("Votes50") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/sensitivity_Post2023.dta",clear
keep if cert_Post2023==1
keep ex im year
isid ex im year
assert _N==83563
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==83563
ppmlhdfe tradevalue mean23 pri23 trend23 dist23,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/sensitivity_Post2023__Post2023.ster",replace
foreach term in mean23 pri23 trend23 dist23 {
post `h' ("sensitivity_Post2023") ("Post2023") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
postclose `h'
use "outputs/batch_3/coefficients.dta",clear
export delimited using "outputs/batch_3/coefficients.csv",replace
display "APPENDIX_BATCH_3_COMPLETE"
log close
