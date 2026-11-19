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
log using "outputs/batch_1/run.log",text replace
sysdir set PLUS "../main_models/ado/"
adopath ++ "../main_models/ado"
use annualendpoint_post dist23 distance_post2022 eg2017 eg2018 eg2019 eg2020 eg2022 eg2023 eg2024 em2017 em2018 em2019 em2020 em2022 em2023 em2024 endpoint_post ep2017 ep2018 ep2019 ep2020 ep2022 ep2023 ep2024 et2017 et2018 et2019 et2020 et2022 et2023 et2024 ex ex_year im im_year importnetwgt mean23 meanpd10_post meanpd5_post pair_id pri10_post pri23 pri5_post rawmean_post rawpri_post rawtrend_post sdpd5_post tradepretrend_post tradevalue trend23 trendpd10_post trendpd5_post year using `"`mother'"',clear
isid ex im year
tempfile mothercopy
save `mothercopy'
tempname h
postfile `h' str32 group str40 model str32 term double b double se double p long N byte converged using "outputs/batch_1/coefficients.dta",replace
use "supports/replay.dta",clear
keep if cert_DynamicD_replay==1
keep ex im year
isid ex im year
assert _N==83563
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==83563
estimates use "outputs/replay__DynamicD_replay.ster"
assert e(N)==_N & e(converged)==1
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("replay") ("DynamicD_replay") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/endpoint.dta",clear
keep if cert_TrendJoint==1
keep ex im year
isid ex im year
assert _N==83563
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==83563
estimates use "outputs/endpoint__TrendJoint.ster"
assert e(N)==_N & e(converged)==1
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("endpoint") ("TrendJoint") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/pairtrend.dta",clear
keep if cert_BeforePairTrend==1
keep ex im year
isid ex im year
assert _N==78109
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78109
estimates use "outputs/pairtrend__BeforePairTrend.ster"
assert e(N)==_N & e(converged)==1
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("pairtrend") ("BeforePairTrend") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/weight.dta",clear
keep if cert_ValueMatched==1
keep ex im year
isid ex im year
assert _N==80445
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80445
estimates use "outputs/weight__ValueMatched.ster"
assert e(N)==_N & e(converged)==1
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("weight") ("ValueMatched") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/measurement.dta",clear
keep if cert_RawMatched==1
keep ex im year
isid ex im year
assert _N==82252
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==82252
estimates use "outputs/measurement__RawMatched.ster"
assert e(N)==_N & e(converged)==1
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("measurement") ("RawMatched") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_ALL.dta",clear
keep if cert_DualRaw_ALL==1
keep ex im year
isid ex im year
assert _N==82252
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==82252
estimates use "outputs/dual_ALL__DualRaw_ALL.ster"
assert e(N)==_N & e(converged)==1
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_ALL") ("DualRaw_ALL") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_AGO.dta",clear
keep if cert_DualRaw_AGO==1
keep ex im year
isid ex im year
assert _N==80704
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80704
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_AGO__DualRaw_AGO.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_AGO") ("DualRaw_AGO") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_ARE.dta",clear
keep if cert_DualRaw_ARE==1
keep ex im year
isid ex im year
assert _N==78981
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78981
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_ARE__DualRaw_ARE.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_ARE") ("DualRaw_ARE") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_CAN.dta",clear
keep if cert_DualRaw_CAN==1
keep ex im year
isid ex im year
assert _N==78730
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78730
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_CAN__DualRaw_CAN.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_CAN") ("DualRaw_CAN") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_CHN.dta",clear
keep if cert_DualRaw_CHN==1
keep ex im year
isid ex im year
assert _N==78104
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78104
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_CHN__DualRaw_CHN.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_CHN") ("DualRaw_CHN") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_DEU.dta",clear
keep if cert_DualRaw_DEU==1
keep ex im year
isid ex im year
assert _N==78693
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78693
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_DEU__DualRaw_DEU.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_DEU") ("DualRaw_DEU") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_ESP.dta",clear
keep if cert_DualRaw_ESP==1
keep ex im year
isid ex im year
assert _N==78543
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78543
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_ESP__DualRaw_ESP.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_ESP") ("DualRaw_ESP") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_GBR.dta",clear
keep if cert_DualRaw_GBR==1
keep ex im year
isid ex im year
assert _N==78158
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78158
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_GBR__DualRaw_GBR.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_GBR") ("DualRaw_GBR") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_IND.dta",clear
keep if cert_DualRaw_IND==1
keep ex im year
isid ex im year
assert _N==79345
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==79345
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_IND__DualRaw_IND.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_IND") ("DualRaw_IND") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_IRQ.dta",clear
keep if cert_DualRaw_IRQ==1
keep ex im year
isid ex im year
assert _N==81039
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==81039
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_IRQ__DualRaw_IRQ.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_IRQ") ("DualRaw_IRQ") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_ITA.dta",clear
keep if cert_DualRaw_ITA==1
keep ex im year
isid ex im year
assert _N==78878
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78878
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_ITA__DualRaw_ITA.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_ITA") ("DualRaw_ITA") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_JPN.dta",clear
keep if cert_DualRaw_JPN==1
keep ex im year
isid ex im year
assert _N==79725
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==79725
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_JPN__DualRaw_JPN.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_JPN") ("DualRaw_JPN") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_KOR.dta",clear
keep if cert_DualRaw_KOR==1
keep ex im year
isid ex im year
assert _N==79054
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==79054
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_KOR__DualRaw_KOR.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_KOR") ("DualRaw_KOR") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_KWT.dta",clear
keep if cert_DualRaw_KWT==1
keep ex im year
isid ex im year
assert _N==81232
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==81232
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_KWT__DualRaw_KWT.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_KWT") ("DualRaw_KWT") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_NGA.dta",clear
keep if cert_DualRaw_NGA==1
keep ex im year
isid ex im year
assert _N==80215
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80215
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_NGA__DualRaw_NGA.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_NGA") ("DualRaw_NGA") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_NLD.dta",clear
keep if cert_DualRaw_NLD==1
keep ex im year
isid ex im year
assert _N==77144
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==77144
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_NLD__DualRaw_NLD.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_NLD") ("DualRaw_NLD") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_NOR.dta",clear
keep if cert_DualRaw_NOR==1
keep ex im year
isid ex im year
assert _N==80494
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80494
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_NOR__DualRaw_NOR.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_NOR") ("DualRaw_NOR") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_RUS.dta",clear
keep if cert_DualRaw_RUS==1
keep ex im year
isid ex im year
assert _N==79658
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==79658
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_RUS__DualRaw_RUS.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_RUS") ("DualRaw_RUS") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_SAU.dta",clear
keep if cert_DualRaw_SAU==1
keep ex im year
isid ex im year
assert _N==80827
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80827
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_SAU__DualRaw_SAU.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_SAU") ("DualRaw_SAU") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/dual_USA.dta",clear
keep if cert_DualRaw_USA==1
keep ex im year
isid ex im year
assert _N==76263
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==76263
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_USA__DualRaw_USA.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_USA") ("DualRaw_USA") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/sensitivity_Window10.dta",clear
keep if cert_Window10==1
keep ex im year
isid ex im year
assert _N==83563
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==83563
ppmlhdfe tradevalue meanpd10_post pri10_post trendpd10_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/sensitivity_Window10__Window10.ster",replace
foreach term in meanpd10_post pri10_post trendpd10_post distance_post2022 {
post `h' ("sensitivity_Window10") ("Window10") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/sensitivity_Drop2022.dta",clear
keep if cert_Drop2022==1
keep ex im year
isid ex im year
assert _N==79072
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==79072
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/sensitivity_Drop2022__Drop2022.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("sensitivity_Drop2022") ("Drop2022") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
postclose `h'
use "outputs/batch_1/coefficients.dta",clear
export delimited using "outputs/batch_1/coefficients.csv",replace
display "APPENDIX_BATCH_1_COMPLETE"
log close
