version 17
args root
if `"`root'"'=="" local root `"`c(pwd)'"'
clear all
set more off
set processors 2
cd `"`root'"'
log using "历史安慰剂/stata_run.log", text replace
local pack "."
sysdir set PLUS `"`root'/`pack'/ado/"'
adopath ++ `"`root'/`pack'/ado"'
ppmlhdfe, version
do "code/oil_local_core.do"
tempname h
postfile `h' str12 model str32 term double b se p N converged using "历史安慰剂/results.dta",replace
foreach name in PL2015 PL2017 {
    use "历史安慰剂/`name'_input.dta",clear
    isid ex im year
    local expected=_N
    ppmlhdfe tradevalue meanpd5_post pri5_post trendpd5_post distance_post2022, absorb(pair_id ex_year im_year) vce(cluster pair_id) separation(fe simplex) tolerance(1e-10) maxiter(500) use_exact_solver(1) d(__fe)
    assert e(N)==`expected' & e(converged)==1
    gen byte estimation_sample=e(sample)
    assert estimation_sample==1
    estimates save "历史安慰剂/`name'.ster",replace
    predict double fitted,mu
    gen double predictor=ln(fitted)
    save "历史安慰剂/`name'_estimated.dta",replace
    foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
        post `h' ("`name'") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
    }
    test meanpd5_post pri5_post trendpd5_post
    matrix FullV=e(V)
    matrix colnames FullV=meanpd5_post pri5_post trendpd5_post distance_post2022 constant
    preserve
    clear
    svmat double FullV,names(col)
    save "历史安慰剂/`name'_covariance.dta",replace
    restore
    egen long __op_p=group(pair_id)
    egen long __op_e=group(ex_year)
    egen long __op_i=group(im_year)
    gen double op_eta=.
    gen double op_mu=.
    local oldpwd `"`c(pwd)'"'
    capture mkdir "历史安慰剂/`name'_local"
    cd "历史安慰剂/`name'_local"
    oil_sparse_ppml,trend(0) maxiter(150)
    assert e(N)==`expected' & e(converged)==1 & e(local_margin_relative_error)<1e-8
    estimates save "local.ster",replace
    foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
        post `h' ("`name'_local") ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N)) (e(converged))
    }
    save "validated_predictions.dta",replace
    matrix LocalV=e(V)
    clear
    svmat double LocalV,names(col)
    save "covariance.dta",replace
    cd `"`oldpwd'"'
}
postclose `h'
use "历史安慰剂/results.dta",clear
export delimited using "历史安慰剂/results.csv",replace
display "HISTORICAL_PLACEBOS_COMPLETE"
log close
