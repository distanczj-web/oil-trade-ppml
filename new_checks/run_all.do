version 17
args root
if `"`root'"'=="" local root `"`c(pwd)'"'
cd `"`root'"'
tempname state
file open `state' using "run_state.csv",write text replace
file write `state' "state,run_type" _n "started,new_checks" _n
file close `state'
do `"`root'/run_placebos.do"' `"`root'"'
do `"`root'/run_dependence.do"' `"`root'"'
do `"`root'/compare_dimensions.do"' `"`root'"'
cd `"`root'"'
file open `state' using "run_state.csv",write text replace
file write `state' "state,run_type" _n "complete,new_checks" _n
file close `state'
display "NEW_CHECKS_PORTABLE_COMPLETE"
