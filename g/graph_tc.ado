*! Graphs the treatment and control
*! Required globals: dir_base
* To do: Need to convert the xlab code to like it is in graph_tc_ci
program graph_tc
	syntax , start(int) file_suff(string) title(string) notes(string) ///
				tper_spec(int) ytitle(string) tc_outcome(string) ///
				[tval_labels(string)  tc_gph_opts(string) xlabels(string) main_label(string)]
	tempfile initdata
	qui save `initdata'
	drop _all
	qui svmat `tc_outcome', names(N)
	rename (N*) (Treated Synthetic)
	
	if "`main_label'"==""{
		local main_label "Main"
	}
	
	qui gen year = _n+`start'-1
	label variable year "Year"
	if "`tval_labels'"!=""{
		local num_years : word count `tval_labels'
		forval i=1/`num_years'{
			local year : word `i' of `tval_labels'
			local recodestr = "`recodestr' (`i'=`year')"
		}
		qui recode year `recodestr'
	}
	
	wrap_text , unwrappedtext("`notes'") width(90)
	local wrapped `"`s(wrappedtext)'"'
	
	twoway (line Treated year) (line Synthetic year, lpattern(longdash)), ///
		xline(`tper_spec', lpattern(shortdash)) `tc_gph_opts' ytitle("`ytitle'") ylabel(minmax) ///
		title("`title'") note(`wrapped') legend(order(1 "`main_label'" 2 "Control (Synth)")) ///
		name(`=strtoname("TC_`file_suff'",1)', replace)  xlabels(`xlabels')
		
	qui save_fig "TC_`file_suff'"
	
	use `initdata', clear
end
