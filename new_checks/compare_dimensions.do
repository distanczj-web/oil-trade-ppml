version 17
args root
if `"`root'"'=="" local root `"`c(pwd)'"'
clear all
set more off
cd `"`root'"'
capture mkdir "维度比较"
log using "维度比较/run.log",text replace
local source "stored_estimates"
tempname h
postfile `h' str12 model str40 comparison double p statistic df N ll using "维度比较/joint_tests.dta",replace
foreach name in A B C D {
    estimates use "`source'/`name'.ster"
    local N=e(N)
    local ll=e(ll)
    if "`name'"=="A" test meanpd5_post
    if "`name'"=="B" test pri5_post
    if "`name'"=="C" test meanpd5_post pri5_post
    if "`name'"=="D" test meanpd5_post pri5_post trendpd5_post
    post `h' ("`name'") ("All political dimensions jointly zero") (r(p)) (r(chi2)) (r(df)) (`N') (`ll')
    if "`name'"=="D" {
        test meanpd5_post pri5_post
        post `h' ("D") ("Level and instability conditional on trend") (r(p)) (r(chi2)) (r(df)) (`N') (`ll')
        test trendpd5_post
        post `h' ("D") ("Adding trajectory to model C") (r(p)) (r(chi2)) (r(df)) (`N') (`ll')
    }
}
postclose `h'
use "维度比较/joint_tests.dta",clear
export delimited using "维度比较/joint_tests.csv",replace
display "DIMENSION_COMPARISON_COMPLETE"
log close
