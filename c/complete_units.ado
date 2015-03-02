*! Makes sure
*! Marks obs with which are complete
*! Can handle normal variables and time subscripted variables (e.g. pop(1980))
program complete_units
	syntax anything, generate(string)
	
	
	cap tsset, noquery
	if _rc==0 {
		local pvar = "`r(panelvar)'"
		local tvar = "`r(timevar)'"
	}

	generate byte `generate'=1
	
	foreach var in `anything'{
		if regexm("`var'", "(.+)\(([0-9]+)\)")!=0{
			local had_subscripted_var 1
			assert_msg "`tvar'"!="", message("Subscripting variable but not tsset.")
			local var = regexs(1)
			local timepart = regexs(2)
			qui replace `generate'=0 if `var'>=. & `tvar'==`timepart'
		}
		else{
			qui replace `generate'=0 if `var'>=.
		}
	}
	
	if "`had_subscripted_var'"!="" {
			tempvar todrop
			bys `pvar': egen `todrop' = min(`generate')
			qui replace `generate' = `todrop'
	}
end
