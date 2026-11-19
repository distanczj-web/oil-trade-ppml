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
log using "outputs/run.log",text replace
sysdir set PLUS "../main_models/ado/"
adopath ++ "../main_models/ado"
use annualendpoint_post dist23 distance_post2022 eg2017 eg2018 eg2019 eg2020 eg2022 eg2023 eg2024 em2017 em2018 em2019 em2020 em2022 em2023 em2024 endpoint_post ep2017 ep2018 ep2019 ep2020 ep2022 ep2023 ep2024 et2017 et2018 et2019 et2020 et2022 et2023 et2024 ex ex_year im im_year importnetwgt mean23 meanpd10_post meanpd5_post pair_id pri10_post pri23 pri5_post rawmean_post rawpri_post rawtrend_post sdpd5_post tradepretrend_post tradevalue trend23 trendpd10_post trendpd5_post year using `"`mother'"',clear
isid ex im year
tempfile mothercopy
save `mothercopy'
tempname h
postfile `h' str32 group str40 model str32 term double b double se double p long N byte converged using "outputs/coefficients.dta",replace
use "supports/replay.dta",clear
keep if cert_DynamicD_replay==1
keep ex im year
isid ex im year
assert _N==83563
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==83563
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/replay__DynamicD_replay.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("replay") ("DynamicD_replay") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/endpoint.dta",clear
keep if cert_TrendOnly==1
keep ex im year
isid ex im year
assert _N==83563
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==83563
ppmlhdfe tradevalue trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/endpoint__TrendOnly.ster",replace
foreach term in trendpd5_post distance_post2022 {
post `h' ("endpoint") ("TrendOnly") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/endpoint.dta",clear
keep if cert_EndpointOnly==1
keep ex im year
isid ex im year
assert _N==83563
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==83563
ppmlhdfe tradevalue endpoint_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/endpoint__EndpointOnly.ster",replace
foreach term in endpoint_post distance_post2022 {
post `h' ("endpoint") ("EndpointOnly") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/endpoint__TrendJoint.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("endpoint") ("TrendJoint") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/endpoint.dta",clear
keep if cert_EndpointJoint==1
keep ex im year
isid ex im year
assert _N==83563
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==83563
ppmlhdfe tradevalue meanpd5_post pri5_post endpoint_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/endpoint__EndpointJoint.ster",replace
foreach term in meanpd5_post pri5_post endpoint_post distance_post2022 {
post `h' ("endpoint") ("EndpointJoint") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
ppmlhdfe tradevalue meanpd5_post pri5_post annualendpoint_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/endpoint__EndpointAnnual.ster",replace
foreach term in meanpd5_post pri5_post annualendpoint_post distance_post2022 {
post `h' ("endpoint") ("EndpointAnnual") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/pairtrend__BeforePairTrend.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("pairtrend") ("BeforePairTrend") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/pretrade.dta",clear
keep if cert_BeforePreTrade==1
keep ex im year
isid ex im year
assert _N==42544
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==42544
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/pretrade__BeforePreTrade.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("pretrade") ("BeforePreTrade") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022 tradepretrend_post,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/pretrade__WithPreTrade.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 tradepretrend_post {
post `h' ("pretrade") ("WithPreTrade") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/weight__ValueMatched.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("weight") ("ValueMatched") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/weight.dta",clear
keep if cert_WeightMatched==1
keep ex im year
isid ex im year
assert _N==80445
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80445
ppmlhdfe importnetwgt meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/weight__WeightMatched.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("weight") ("WeightMatched") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/measurement__IdealMatched.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("measurement") ("IdealMatched") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/measurement__RawMatched.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("measurement") ("RawMatched") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/loco_ALL.dta",clear
keep if cert_LOCO_IP_ALL==1
keep ex im year
isid ex im year
assert _N==83563
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==83563
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_ALL__LOCO_IP_ALL.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_ALL") ("LOCO_IP_ALL") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_ALL__DualIP_ALL.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("dual_ALL") ("DualIP_ALL") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
ppmlhdfe tradevalue rawmean_post rawpri_post rawtrend_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/dual_ALL__DualRaw_ALL.ster",replace
foreach term in rawmean_post rawpri_post rawtrend_post distance_post2022 {
post `h' ("dual_ALL") ("DualRaw_ALL") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
use "supports/loco_AGO.dta",clear
keep if cert_LOCO_IP_AGO==1
keep ex im year
isid ex im year
assert _N==82015
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==82015
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_AGO__LOCO_IP_AGO.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_AGO") ("LOCO_IP_AGO") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_ARE.dta",clear
keep if cert_LOCO_IP_ARE==1
keep ex im year
isid ex im year
assert _N==80223
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80223
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_ARE__LOCO_IP_ARE.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_ARE") ("LOCO_IP_ARE") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_CAN.dta",clear
keep if cert_LOCO_IP_CAN==1
keep ex im year
isid ex im year
assert _N==80016
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80016
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_CAN__LOCO_IP_CAN.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_CAN") ("LOCO_IP_CAN") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_CHN.dta",clear
keep if cert_LOCO_IP_CHN==1
keep ex im year
isid ex im year
assert _N==79337
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==79337
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_CHN__LOCO_IP_CHN.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_CHN") ("LOCO_IP_CHN") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_DEU.dta",clear
keep if cert_LOCO_IP_DEU==1
keep ex im year
isid ex im year
assert _N==79959
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==79959
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_DEU__LOCO_IP_DEU.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_DEU") ("LOCO_IP_DEU") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_ESP.dta",clear
keep if cert_LOCO_IP_ESP==1
keep ex im year
isid ex im year
assert _N==79826
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==79826
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_ESP__LOCO_IP_ESP.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_ESP") ("LOCO_IP_ESP") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_GBR.dta",clear
keep if cert_LOCO_IP_GBR==1
keep ex im year
isid ex im year
assert _N==79378
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==79378
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_GBR__LOCO_IP_GBR.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_GBR") ("LOCO_IP_GBR") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_IND.dta",clear
keep if cert_LOCO_IP_IND==1
keep ex im year
isid ex im year
assert _N==80603
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80603
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_IND__LOCO_IP_IND.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_IND") ("LOCO_IP_IND") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_IRQ.dta",clear
keep if cert_LOCO_IP_IRQ==1
keep ex im year
isid ex im year
assert _N==82350
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==82350
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_IRQ__LOCO_IP_IRQ.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_IRQ") ("LOCO_IP_IRQ") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_ITA.dta",clear
keep if cert_LOCO_IP_ITA==1
keep ex im year
isid ex im year
assert _N==80143
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80143
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_ITA__LOCO_IP_ITA.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_ITA") ("LOCO_IP_ITA") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_JPN.dta",clear
keep if cert_LOCO_IP_JPN==1
keep ex im year
isid ex im year
assert _N==81011
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==81011
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_JPN__LOCO_IP_JPN.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_JPN") ("LOCO_IP_JPN") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_KOR.dta",clear
keep if cert_LOCO_IP_KOR==1
keep ex im year
isid ex im year
assert _N==80338
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80338
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_KOR__LOCO_IP_KOR.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_KOR") ("LOCO_IP_KOR") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_KWT.dta",clear
keep if cert_LOCO_IP_KWT==1
keep ex im year
isid ex im year
assert _N==82543
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==82543
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_KWT__LOCO_IP_KWT.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_KWT") ("LOCO_IP_KWT") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_NGA.dta",clear
keep if cert_LOCO_IP_NGA==1
keep ex im year
isid ex im year
assert _N==81496
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==81496
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_NGA__LOCO_IP_NGA.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_NGA") ("LOCO_IP_NGA") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_NLD.dta",clear
keep if cert_LOCO_IP_NLD==1
keep ex im year
isid ex im year
assert _N==78414
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==78414
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_NLD__LOCO_IP_NLD.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_NLD") ("LOCO_IP_NLD") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_NOR.dta",clear
keep if cert_LOCO_IP_NOR==1
keep ex im year
isid ex im year
assert _N==81780
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==81780
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_NOR__LOCO_IP_NOR.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_NOR") ("LOCO_IP_NOR") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_RUS.dta",clear
keep if cert_LOCO_IP_RUS==1
keep ex im year
isid ex im year
assert _N==80969
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==80969
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_RUS__LOCO_IP_RUS.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_RUS") ("LOCO_IP_RUS") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_SAU.dta",clear
keep if cert_LOCO_IP_SAU==1
keep ex im year
isid ex im year
assert _N==82138
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==82138
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_SAU__LOCO_IP_SAU.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_SAU") ("LOCO_IP_SAU") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/loco_USA.dta",clear
keep if cert_LOCO_IP_USA==1
keep ex im year
isid ex im year
assert _N==77501
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==77501
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/loco_USA__LOCO_IP_USA.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_USA") ("LOCO_IP_USA") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/sensitivity_Votes30.dta",clear
keep if cert_Votes30==1
keep ex im year
isid ex im year
assert _N==82266
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==82266
ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/sensitivity_Votes30__Votes30.ster",replace
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("sensitivity_Votes30") ("Votes30") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/sensitivity_AltSD.dta",clear
keep if cert_AltSD==1
keep ex im year
isid ex im year
assert _N==83563
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==83563
ppmlhdfe tradevalue meanpd5_post sdpd5_post trendpd5_post distance_post2022,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/sensitivity_AltSD__AltSD.ster",replace
foreach term in meanpd5_post sdpd5_post trendpd5_post distance_post2022 {
post `h' ("sensitivity_AltSD") ("AltSD") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "supports/event.dta",clear
keep if cert_AnnualEvent==1
keep ex im year
isid ex im year
assert _N==19208
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==19208
ppmlhdfe tradevalue em2017 ep2017 et2017 eg2017 em2018 ep2018 et2018 eg2018 em2019 ep2019 et2019 eg2019 em2020 ep2020 et2020 eg2020 em2022 ep2022 et2022 eg2022 em2023 ep2023 et2023 eg2023 em2024 ep2024 et2024 eg2024,absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-11) use_exact_solver(1) maxiter(500)
assert e(converged)==1 & e(N)==_N
assert e(sample)==1
estimates save "outputs/event__AnnualEvent.ster",replace
foreach term in em2017 ep2017 et2017 eg2017 em2018 ep2018 et2018 eg2018 em2019 ep2019 et2019 eg2019 em2020 ep2020 et2020 eg2020 em2022 ep2022 et2022 eg2022 em2023 ep2023 et2023 eg2023 em2024 ep2024 et2024 eg2024 {
post `h' ("event") ("AnnualEvent") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
}
postclose `h'
use "outputs/coefficients.dta",clear
export delimited using "outputs/coefficients.csv",replace
display "APPENDIX_ORDINARY_MODELS_COMPLETE"
log close
