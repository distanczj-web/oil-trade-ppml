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
log using "outputs/batch_2/run.log",text replace
sysdir set PLUS "../main_models/ado/"
adopath ++ "../main_models/ado"
use annualendpoint_post dist23 distance_post2022 eg2017 eg2018 eg2019 eg2020 eg2022 eg2023 eg2024 em2017 em2018 em2019 em2020 em2022 em2023 em2024 endpoint_post ep2017 ep2018 ep2019 ep2020 ep2022 ep2023 ep2024 et2017 et2018 et2019 et2020 et2022 et2023 et2024 ex ex_year im im_year importnetwgt mean23 meanpd10_post meanpd5_post pair_id pri10_post pri23 pri5_post rawmean_post rawpri_post rawtrend_post sdpd5_post tradepretrend_post tradevalue trend23 trendpd10_post trendpd5_post year using `"`mother'"',clear
isid ex im year
tempfile mothercopy
save `mothercopy'
tempname h
postfile `h' str32 group str40 model str32 term double b double se double p long N byte converged using "outputs/batch_2/coefficients.dta",replace
use "supports/endpoint.dta",clear
keep if cert_TrendOnly==1
keep ex im year
isid ex im year
assert _N==83563
merge 1:1 ex im year using `mothercopy',keep(master match)
assert _merge==3
drop _merge
assert _N==83563
estimates use "outputs/endpoint__TrendOnly.ster"
assert e(N)==_N & e(converged)==1
foreach term in trendpd5_post distance_post2022 {
post `h' ("endpoint") ("TrendOnly") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
estimates use "outputs/endpoint__EndpointJoint.ster"
assert e(N)==_N & e(converged)==1
foreach term in meanpd5_post pri5_post endpoint_post distance_post2022 {
post `h' ("endpoint") ("EndpointJoint") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
estimates use "outputs/pretrade__BeforePreTrade.ster"
assert e(N)==_N & e(converged)==1
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("pretrade") ("BeforePreTrade") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
estimates use "outputs/weight__WeightMatched.ster"
assert e(N)==_N & e(converged)==1
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("weight") ("WeightMatched") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
estimates use "outputs/loco_ALL__LOCO_IP_ALL.ster"
assert e(N)==_N & e(converged)==1
foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
post `h' ("loco_ALL") ("LOCO_IP_ALL") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
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
use "outputs/batch_2/coefficients.dta",clear
export delimited using "outputs/batch_2/coefficients.csv",replace
display "APPENDIX_BATCH_2_COMPLETE"
log close
