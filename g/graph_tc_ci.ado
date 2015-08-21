*! Graphs Treatment and Control with Confidence Intervals
*! Required globals: dir_base
program graph_tc_ci
	version 11.0 //just a guess here
	syntax , file_suff(string) title(string) ///
			tper_spec(int) num_reps(int) tc_outcome(string) cis(string)  ///
			[start(int 1) ci_num(string) tval_labels(string) tc_gph_opts(string) ///
			graph_logs xlabels(string) connect_treat logs ytitle(string) notes(string) ///
			perc_perms_match_better(string) ylabel_scale(string) main_label(string) ///
			connect_ci_to_pre_t extra_cmd(string) extra_names(string) extra_legend(string) ///
			control_str(string)]
	tempname all_to_graph
	tempfile initdata
	qui save `initdata'
	drop _all
	mat `all_to_graph' = `tc_outcome', `cis'
	qui svmat `all_to_graph', names(N)
	rename (N*) (Treated Synthetic LowCI HighCI `extra_names')
	
	if "`connect_ci_to_pre_t'"!=""{
		qui count if LowCI==.
		local last_per_pre_t = r(N)
		qui replace LowCI = Synthetic in `last_per_pre_t'
		qui replace HighCI = Synthetic in `last_per_pre_t'
	}
	
	
	if ("`main_label'"=="") local main_label "Main"
	if ("`control_str'"=="") local control_str "Control (Synth)"
	if ("`control_str'"!="Omit") local control_opt `"3 "`control_str'""'
	
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
	

	if ("`ci_num'"!="") local ci_string = "`ci_num'% CIs"
	else                local ci_string "CIs"
	
	if `num_reps'!=0{
		local notes "`notes' Confidence intervals for control from `num_reps' permutation tests."
	}
	if "`perc_perms_match_better'"!=""{
		local notes "`notes' `perc_perms_match_better'% of the permutation tests had lower pre-treatment RMSPEs."
	}
		
	local treat_type "line"
	if "`connect_treat'"!="" {
		local treat_type "connected"
	}
	
	if "`graph_logs'"!="" {
		log_axis_ticks , vars(LowCI HighCI Treated Synthetic) label_scale(`ylabel_scale')
		local yaxislogopt = `"yscale(log) ymtick(`s(minor_ticks)') ylabel(`s(major_ticks)', angle(horizontal))"'
	}
	
	wrap_text , unwrappedtext("`notes'") width(90)
	local wrapped `"`s(wrappedtext)'"'
	twoway (rarea LowCI HighCI  year, color(gs12) fcolor(gs12)) ///
		(`treat_type' Treated year, lpattern(solid)) ///
		(line Synthetic year, lpattern(dash)) ///
		`extra_cmd', ///
		title("`title'") ytitle("`ytitle'") /* ylabel(minmax)*/ ///
		xline(`tper_spec', lpattern(shortdash)) `tc_gph_opts'  xlabels(`xlabels') ///
		legend(order(2 "`main_label'" `control_opt' 1 "`ci_string'" `extra_legend') cols(3)) ///
		note(`wrapped') `yaxislogopt' name(`=strtoname("TC_CIs_`file_suff'",1)', replace)
	qui save_fig "TC_CIs_`file_suff'"

	use `initdata', clear
end


