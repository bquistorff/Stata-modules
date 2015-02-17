*! v0.1
*! A merge pass-through function with 2 additions
*! 1) Allows merging when key variables are named differently. (using_match_vars())
*! 2) Shows the full match stats (even when using keep())
program bmerge
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

	local matchvars "`varlist'"
	if "`using_match_vars'"!=""{
		rename (`varlist') (`using_match_vars')
		local matchvars "`using_match_vars'"
	}
	
	merge `mtype' `token' `matchvars' using "`using'", assert(`assert') generate(`generate') ///
		`force' keepusing(`keepusing') `label' `notes' `replace' `report' `sorted' `update'
	
	if "`using_match_vars'"!="" rename (`using_match_vars') (`varlist')
	
	if "`generate'"=="" loc generate _merge
	
	if "`keep'"!=""{
		foreach ktype in `keep' {
			if "`ktype'"=="master" 			loc keep_list "`keep_list',1"
			if "`ktype'"=="using" 			loc keep_list "`keep_list',2"
			if "`ktype'"=="match" 			loc keep_list "`keep_list',3"
			if "`ktype'"=="match_update" 	loc keep_list "`keep_list',4"
			if "`ktype'"=="match_conflict" 	loc keep_list "`keep_list',5"
		}
		keep if inlist(`generate' `keep_list')
	}
	
	
	if "`nogenerate'"!="" drop `generate'
end
