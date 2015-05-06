*! v0.1 Brian Quistorff <bquistorff@gmail.com>
*! A merge pass-through function with additions:
*! 1) Allows merging when key variables are named differently. (using_match_vars())
*! 2) Shows the full match stats (even when using keep())
*! 3) Maintains sort (using ", stable")
*! 4) return in r() the tab of _merge
program bmerge, rclass
	version 12 //use version 12 instead of 11 because of better -rename-
	
	* This parsing was ripped from -merge-
	gettoken mtype 0 : 0, parse(" ,")
	gettoken token : 0, parse(" ,")
	if ("`token'"=="_n") {
		gettoken token 0 : 0, parse(" ,")
	}
	else{
		loc token ""
	}
	* add here using_match_vars()
	syntax [varlist(default=none)] using/ [, using_match_vars(string) ///
		ASSERT(string) GENerate(name) FORCE KEEP(string) KEEPUSing(string) ///
		noLabel NOGENerate noNOTEs REPLACE noREPort SORTED UPDATE]
	*weird, aparently "nogenerate" and "generate" get set (unlike normal no-option locs)
	qui describe, varlist
	local svars `r(sortlist)'

	local matchvars "`varlist'"
	if "`using_match_vars'"!=""{
		rename (`varlist') (`using_match_vars')
		local matchvars "`using_match_vars'"
	}
	
	local gen_var _merge
	if "`nogenerate'"!="nogenerate" & "`generate'"!="" local gen_var `generate'
	
	merge `mtype' `token' `matchvars' using "`using'", assert(`assert') generate(`gen_var') ///
		`force' keepusing(`keepusing') `label' `notes' `replace' `report' `sorted' `update'
	
	if "`using_match_vars'"!="" rename (`using_match_vars') (`varlist')
	
	loc keep_keyword_order = "master using match match_update match_conflict"
	
	*Output return values
	* First zero-out
	foreach ktype in `keep_keyword_order'{
		return scalar `ktype' = 0
	}
	tempname cell_mat row_mat
	qui tab `gen_var', matcell(`cell_mat') matrow(`row_mat')
	forval row_i =1/`=rowsof(`row_mat')'{
		local ktype_ind = `row_mat'[`row_i',1]
		local ktype : word `ktype_ind' of `keep_keyword_order'
		local ktype_count = `cell_mat'[`row_i',1]
		return scalar `ktype' = `ktype_count'
	}
	
	if "`keep'"!=""{
		foreach ktype in `keep' {
			if "`ktype'"=="master" 			loc keep_list "`keep_list',1"
			if "`ktype'"=="using" 			loc keep_list "`keep_list',2"
			if "`ktype'"=="match" 			loc keep_list "`keep_list',3"
			if "`ktype'"=="match_update" 	loc keep_list "`keep_list',4"
			if "`ktype'"=="match_conflict" 	loc keep_list "`keep_list',5"
		}
		keep if inlist(`gen_var' `keep_list')
	}
	
	if "`nogenerate'"=="nogenerate" drop `gen_var'
	
	if "`svars'"!="" sort `svars', stable
end
