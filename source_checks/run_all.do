* Cold-start numerical refinement of ordinary three-way FE PPML only.
version 17
args project mode
clear all
set more off
set processors 2
set linesize 180
if `"`project'"'=="" local project `"`c(pwd)'"'
cd `"`project'"'
local project `"`c(pwd)'"'
capture mkdir "outputs"
log using "outputs/run_`mode'.log",text replace
do "oil_local_core.do"
local models "NoConflictZero ReporterCoverage WeightAmount WeightKg"

foreach model in `models' {
    use "data/`model'.dta",clear
    isid ex im year
    egen long __op_p=group(pair_id)
    egen long __op_e=group(ex_year)
    egen long __op_i=group(im_year)
    gen double op_eta=.
    gen double op_mu=.
    capture mkdir "outputs/`model'"
    cd "outputs/`model'"
    oil_sparse_ppml,trend(0) maxiter(150)
    assert e(N)==_N & e(converged)==1 & e(local_margin_relative_error)<1e-8
    assert e(sample)==1
    estimates save "estimates.ster",replace
    matrix FullV=e(V)
    tempname result
    postfile `result' str32 term double(b se p) long N using "coefficients.dta",replace
    foreach term in meanpd5_post pri5_post trendpd5_post distance_post2022 {
        post `result' ("`term'") (_b[`term']) (_se[`term']) (2*normal(-abs(_b[`term']/_se[`term']))) (e(N))
    }
    postclose `result'
    preserve
    save "analysis_ready.dta",replace
    restore
    clear
    svmat double FullV,names(col)
    save "covariance.dta",replace
    cd `"`project'"'
}
display "LOCAL_MARGIN_RUN_COMPLETED `mode'"
log close
