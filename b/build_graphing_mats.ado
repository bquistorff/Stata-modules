*! Builds the matrices needed by the graphing programs
*! Works if the unit is one of the donors a permuation estimation was done on.
program build_graphing_mats, rclass
	syntax anything, depvar(string) startper(int) perms_file(string)
	
	qui tsset, noquery
	local pvar = "`r(panelvar)'"
	
	tempname roBr y_diffs_t tc_mat CI_mat y_diff
	mkmat `depvar' if `pvar'==`anything', matrix(`roBr')
	mat `roBr' = `roBr'[`startper'...,1]
	tempfile initdata
	qui save `initdata'
	use "`perms_file'", clear
	keep if unit_type==${Unit_type_donor}
	drop unit_type
	mkmat PE* if `pvar'==`anything', mat(`y_diffs_t')
	use `initdata', clear
	mat `y_diff' = `y_diffs_t''
	mat `tc_mat' = (`roBr', `roBr'-`y_diff')
	
	return matrix tc_outcome = `tc_mat'
	return matrix y_diff = `y_diff'
end
