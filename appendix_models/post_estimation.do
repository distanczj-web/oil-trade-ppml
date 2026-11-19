version 17
args root
if `"`root'"'=="" local root `"`c(pwd)'"'
cd `"`root'"'
clear all
set more off
log using "outputs/post_estimation.log",text replace
estimates use "outputs/event__AnnualEvent.ster"
tempname h
postfile `h' str32 test double chi2 double df double p long N using "outputs/annual_tests.dta",replace
test et2017 et2018 et2019 et2020
post `h' ("trajectory_pre_joint") (r(chi2)) (r(df)) (r(p)) (e(N))
test (et2022=et2023) (et2023=et2024)
post `h' ("trajectory_post_equality") (r(chi2)) (r(df)) (r(p)) (e(N))
postclose `h'
use "outputs/annual_tests.dta",clear
export delimited using "outputs/annual_tests.csv",replace
display "ANNUAL_TESTS_COMPLETE"
log close
