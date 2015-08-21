*! Purpose: Right now just check if inside the upper-/lower-envelope
*! Also graphs the raw data a bit
* To do: maybe eventually use the Gary King program
program check_in_convex_hull
	version 11.0 //just a guess here
	syntax varname, first_pre(int) last_pre(int) trunit(int) file_suff(string) ///
		[gph_tvar(string)  main_label(string) end(string) xlabels(string) tper_spec(string) ]
	qui tsset, noquery
	local tvar = "`r(timevar)'"
	local pvar = "`r(panelvar)'"
	
	if "`gph_tvar'"==""{
		local gph_tvar "`tvar'"
	}
	if "`main_label'"==""{
		local main_label "Main"
	}
	/*if "`xlabels'"==""{
		foreach labl in `xlabels'{
			if `labl'<`tper_spec' {
				local xlabels_short "`xlabels_short' `labl'"
			}
		}
	}*/
	if "`xlabels'"!=""{
		local xla "xlabel(`xlabels')"
	}
	
	qui levelsof `gph_tvar' if `pvar'==`trunit', local(tvals)
	summ `gph_tvar' if `pvar'==`trunit', meanonly
	local tvar_min = r(min)
	local gph_min_t : word `=`first_pre'-`tvar_min'+1' of `tvals'
	local gph_max_t : word `=`last_pre'-`tvar_min'+1' of `tvals'
	
	di "Checking if we're in the convex hull"
	forval tval =`first_pre'/ `last_pre'{
		qui summ `varlist' if `pvar'==`trunit' & `tvar'==`tval'
		local tr_lvl = r(mean)
		
		qui summ `varlist' if `pvar'!=`trunit' & `tvar'==`tval'
		local dp_min = r(min)
		local dp_max = r(max)
		
		local inrange = (`tr_lvl' >= `dp_min' & `tr_lvl' <= `dp_max')
		autofmt, input(`tr_lvl' `dp_min' `dp_max') dec(3)
		di "Inrange=`inrange'. Depvar=`varlist', tvar=`tval'. Treatment Level=`r(output1)'." ///
			"Donor pool range=[`r(output2)', `r(output3)']"
	}
	
	local grph_pre_cmds = ""
	qui levelsof `pvar' if `tvar'==`first_pre', local(units)
	local nunits : word count `units'
	foreach unit in `units' {
		local grph_pre_cmds "`grph_pre_cmds' (line `varlist' `gph_tvar' if `pvar'==`unit' & `gph_tvar'<=`gph_max_t' &  `gph_tvar'>=`gph_min_t', lcolor(gs10) lwidth(medthin) lpattern(solid) )"
	}
	
	twoway `grph_pre_cmds' (connected `varlist' `gph_tvar' if `pvar'==`trunit' & `gph_tvar'<=`gph_max_t' & `gph_tvar'>=`gph_min_t', lpattern(solid) lwidth(thick) mcolor(black) msymbol(S)), ///
		legend(order(`=`nunits'+1' "`main_label'" 1 "Donors")) name(`=strtoname("pre_trends_`file_suff'",1)', replace) ///
		/*ylabel(minmax)*/ xlabel(minmax /*xlabels_short*/) title("Pre-treatment trends")
	qui save_fig "pre-trends_`file_suff'"
	
	
	if "`end'"!=""{
		local gph_end_t : word `=`end'-`tvar_min'+1' of `tvals'
		foreach unit in `units' {
			local grph_total_cmds "`grph_total_cmds' (line `varlist' `gph_tvar' if `pvar'==`unit' & `gph_tvar'<=`gph_end_t' &  `gph_tvar'>=`gph_min_t', lcolor(gs10) lwidth(medthin) lpattern(solid) )"
		}
		twoway `grph_total_cmds' (connected `varlist' `gph_tvar' if `pvar'==`trunit' & `gph_tvar'<=`gph_end_t' & `gph_tvar'>=`gph_min_t', lpattern(solid) lwidth(thick) mcolor(black) msymbol(S)), ///
			xline(`tper_spec', lpattern(shortdash)) ///
			legend(order(`=`nunits'+1' "`main_label'" 1 "Donors")) name(`=strtoname("all_trends_`file_suff'",1)', replace) ///
			/*ylabel(minmax)*/ `xla' title("Raw Trends")
		qui save_fig "all-trends_`file_suff'"
	}
end
