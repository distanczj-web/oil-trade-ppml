version 17
args root
cd `"`root'"'
do `"`root'/compare_dimensions.do"' `"`root'"'
tempname state
file open `state' using "run_state.csv",write text replace
file write `state' "state,run_type" _n "complete,new_checks" _n
file close `state'
display "NEW_CHECKS_PORTABLE_COMPLETE"
