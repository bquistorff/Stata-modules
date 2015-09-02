sysdir set PERSONAL "../../"
sysdir set PLUS "../../"
clear_all, closealllogs
log using "test.log", replace name(test)

version 13

local init_seed 467 //from exampleofstratifying
set seed `init_seed'
local ngroups 6
local strat_vars = "variableA variableB variableC variableD"
local ttypes = "obalance reduction full_obalance full missing"

*setup data
use BlogStrataExample.dta, clear
egen byte int_strat = group(variableC variableD)
qui do exampleofstratifying.do //does bm treatment
local all_ttypes = "`ttypes' mb"

*generate assignments
foreach t in `ttypes'{
	set seed `init_seed'
	assign_treatment `strat_vars', generate(treatment_`t') num_treatments(`ngroups') handle_misfit(`t')
}

*All achieve cell-level balance (a must)
foreach t in `all_ttypes'{
	*tab strata treatment_`t'
	cell_count_diff_per_t strata treatment_`t'
	_assert r(max)<=1, msg("t=`t' failed cell-level balance")
}

*Balance at intermediate levels
foreach t in `all_ttypes'{
	*tab int_strat treatment_`t'
	cell_count_diff_per_t int_strat treatment_`t'
	if "`t'"!="missing" di "Intermediate diff=" r(max) " for t=`t'"
	if inlist("`t'","missing") _assert r(max)<=1, msg("t=`t' failed intermediate-level balance")
}

*Balance overall (could be off by as much as num_cells)
foreach t in `all_ttypes'{
	*tab treatment_`t'
	cell_count_diff_per_t treatment_`t'
	if "`t'"!="missing" di "Overall diff=" r(max) " for t=`t'"
	if inlist("`t'","obalance","missing") _assert r(max)<=1, msg("t=`t' failed overall balance")
}

**************** Distribution tests ***********************

local ttypes2 = "obalance reduction full_obalance full"
local all_ttypes2 = "`ttypes2' mb"
local num_reps 1000
tempfile rfile
postfile rep_file int(diff_mb diff_obalance diff_reduction diff_full_obalance diff_full diff_int_mb diff_int_obalance diff_int_reduction diff_int_full_obalance diff_int_full) using `rfile', replace
forval i=1/`num_reps'{
	capture noisily print_dots `i' `num_reps'
	keep obsno variable* int_strat
	qui do exampleofstratifying.do

	foreach t in `ttypes2'{
		assign_treatment `strat_vars', generate(treatment_`t') num_treatments(`ngroups') handle_misfit(`t')
	}
	
	foreach t in `all_ttypes2'{
		cell_count_diff_per_t treatment_`t'
		local diff_`t' = r(max)
		cell_count_diff_per_t int_strat treatment_`t'
		local diff_int_`t' = r(max)
	}
	post rep_file (`diff_mb') (`diff_obalance') (`diff_reduction') (`diff_full_obalance') (`diff_full') ///
		 (`diff_int_mb') (`diff_int_obalance') (`diff_int_reduction') (`diff_int_full_obalance') (`diff_int_full')
}
postclose rep_file

*The MB and Full method effectively give the same distribution for this summary stat.
use `rfile', clear

*The 'obalance', 'reduction', and 'full_obalance' methods are the only ones that keep overall balance
*The 'reduction' is the only that does well at intermediate levels of stratification.
summ

*Look at the summary statistics to show that mb==full
rename (diff_mb diff_full) (diff1 diff2)
keep diff1 diff2
gen int id = _n
reshape long diff, i(id) j(t)
ksmirnov diff , by(t)
local pval = r(p_cor)
di "P-value of test of H0 that the distributions are equal: `pval'"

/* Old testing code for mata utils
impossible = (1,1 \ 2,2 \ 3,1 \ 4,2 \ 5,1)
possible = (1,1 \ 2,2 \ 3,1 \ 4,2)
full_obalance(2, impossible)
full_obalance(2, possible)
full_obalance(2, possible)
full_obalance(2, possible)
full_obalance(2, possible)
*/ 

log close test
