*! Graphs the prediction errors
*! Required globals: dir_base
program graph_PEs
	version 11.0 //just a guess here
	syntax , start(int) file_suff(string) title(string) notes(string) ///
			tper_spec(int) y_diff(string) y_diffs(string) ///
			[ytitle(string) tval_labels(string) xlabels(string) main_label(string)]
	tempname y_diff_all
	tempfile initdata
	qui save `initdata'
	drop _all
	
	if "`main_label'"==""{
		local main_label "Main"
	}

	mat `y_diff_all' = `y_diff', `y_diffs'
	local ncols = colsof(`y_diff_all')
	qui svmat `y_diff_all', names(D)
	
	qui gen year = _n+`start'-1
	label variable year "Year"
	if trim("`tval_labels'")!=""{
		local num_years : word count `tval_labels'
		forval i=1/`num_years'{
			local year : word `i' of `tval_labels'
			local recodestr = "`recodestr' (`i'=`year')"
		}
		qui recode year `recodestr'
	}
	wrap_text , unwrappedtext("`notes'") width(90)
	local wrapped `"`s(wrappedtext)'"'
	
	local grph_perm_cmds = ""
	forval d=2/`ncols'{
		local grph_perm_cmds "`grph_perm_cmds' (line D`d' year, lcolor(gs10) lwidth(medthin) lpattern(solid) )"
	}
	twoway `grph_perm_cmds' (connected D1 year, lpattern(solid) lwidth(thick) msymbol(S) mcolor(black)), ///
		xline(`tper_spec', lpattern(shortdash)) legend(order(`ncols' "`main_label'" 1 "Permutations")) ///
		ytitle("Pred Errors: `ytitle'") ylabel(minmax) xlabels(`xlabels') title("`title'") ///
		note(`wrapped') name(`=strtoname("PEs_`file_suff'",1)', replace)
	qui save_fig "PEs_`file_suff'"
	
	use `initdata', clear
end
