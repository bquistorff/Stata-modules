*! Output (in dta and tex formats) a matrix of some quality of the predictors
* Required globals: dir_base
program output_pred_mat
	version 11.0 //just a guess here
	syntax , file_suff(string) mat(string) mattype(string) [year_replace_period_list(string) nosort]
	
	*Output to a dta file
	tempname matw
	mat `matw' = `mat'[1...,1]
	matsave `matw', replace path("${dir_base}/data/estimates/weights/`mattype'_`file_suff'.dta")
	
	* replace (period) with (year) if necessary
	if "`year_replace_period_list'"!="" {
		local rnames : rownames `mat'
		local year_num : word count `year_replace_period_list'
		forval i = 1 / `year_num' {
			local year : word `i' of `year_replace_period_list'
			local rnames : subinstr local rnames "(`i')" "(`year')", all
		}
		abbrev_all , str_list(`rnames') out_loc(rnames_new)
		mat rownames `mat' = `rnames_new'
	}
	
	*replace var name with var label
	local rnames : rownames `mat'
	local rnames_orig "`rnames'"
	foreach rname in `rnames_orig'{
		local vname "`rname'"
		local year_lab ""
		local paren_ind = strpos("`rname'","(")
		if `paren_ind'>0{
			local vname =substr("`rname'",1,`=`paren_ind'-1')
			local year_lab =substr("`rname'",`paren_ind',.)
		}
		local vname_lab : variable label `vname'
		if "`vname_lab'"!=""{
			local rnames : subinstr local rnames "`rname'" `""`vname_lab'`year_lab'""', all
		}
	}
	abbrev_all , str_list(`rnames') out_loc(rnames_new)
	mat rownames `mat' = `rnames_new'
	if "`sort'"!="nosort"{
		matrixsort `mat' -1
	}
	qui frmttable using "${dir_base}/tab/tex/`mattype'_`file_suff'.tex", replace statmat(`mat') tex fragment sdec(3)
	
end
