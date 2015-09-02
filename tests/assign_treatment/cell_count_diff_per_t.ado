*Returns the maximum difference of the count of cells in each treatment group
* can omit cell_var (first arg will then be treat_var)
program cell_count_diff_per_t, rclass
	args cell_var treat_var
	
	if "`treat_var'"==""{
		local treat_var = "`cell_var'"
		tempvar cell_var
		gen byte `cell_var' = 1
	}
	
	summ `cell_var', meanonly
	local cell_var_max = r(max)
	preserve
	contract `treat_var' `cell_var'
	local currmax = 0
	local currsum = 0
	qui drop if mi(`treat_var')
	forval g=1/`cell_var_max'{
		summ _freq if `cell_var'==`g', meanonly
		local currdiff = cond(mi(r(max))& mi(r(min)),0,r(max) - r(min))
		if `currdiff'>`currmax' local currmax = `currdiff'
		local currsum = `currsum' + `currdiff'
	}
	restore
	
	return scalar max = `currmax'
	return scalar mean = `currsum'/`cell_var_max'
end
