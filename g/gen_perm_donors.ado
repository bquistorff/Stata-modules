*! gen_perm_donors: Runs permutation estimations on donors
*! Needs dataset to be with delta_t=1 and with only donors
*
* Required globals: fargs, dir_base
* Suboptions: fargs = predictors(string)
program gen_perm_donors
	syntax , donor_mat(string) depvar(string) infile(string) ///
			start(int) tper(int) end(int) outfile(string) ///
			[nested permweightsfile(string) logfile(string) donor_limit_for_match_cmd(string)]
	local 0 ", ${fargs}"
	syntax , predictors(string)
	if "`logfile'"!=""{
		log using "`logfile'${pll_instance}.log", replace name(gen_perm_donors) //not using log_open.
	}

	*This stuff doesn't get copied over
	if "${pll_instance}"!=""{
		qui include proj_prefs.do 
	}
	if "${testing}"=="1"{
		*mat dir
		*mac dir
		*local set_trace "set trace on"
		*local unset_trace "set trace off"
	}
	`set_trace'
	
	di "Generating permuation results."
	
	if "`donor_limit_for_match_cmd'"!=""{
		local donor_limit_for_match_cmd "`donor_limit_for_match_cmd' \`curr_tru'"
	}

	tempname mydonorsmat tc_outcome y_diff_perm weights_unr
	mata: st_matrix("`mydonorsmat'", `donor_mat'${pll_instance})

	use "`infile'" , clear
	qui tsset, noquery
	local tvar = "`r(timevar)'"
	local pvar = "`r(panelvar)'"
	
	matrix_post_lines , matrix(`y_diff_perm') varstub(PE) varnumstart(`start') varnumend(`end')
	local ps_init "`s(ps_init)'"
	local ps_posting "`s(ps_posting)'"

	cap postclose postperm
	qui postfile postperm `ps_init' int `pvar' byte unit_type using "`outfile'${pll_instance}", replace 
	local last_pre_per = `tper'-1
	local pre_len = `tper'-`start'
	
	local reps = rowsof(`mydonorsmat')

	forvalues i = 1/`reps'{
		print_dots `i' `reps'
		local curr_tru = `mydonorsmat'[`i', 1]
		
		use "`infile'" , clear
		`donor_limit_for_match_cmd'
		cap synth `depvar' `predictors', trunit(`curr_tru') mspeperiod(`start'(1)`last_pre_per') ///
			resultsperiod(`tper'(1)`end') `nested' trperiod(`tper')  skipchecks
		if _rc ==1 {
			error 1
		}
		if _rc != 0{
			mat `tc_outcome' = J(`=`end'-`start'+1',2,.)
		}
		else {
			mat `tc_outcome' = e(Zbal) \ e(Ybal)
		}
		
		mat `y_diff_perm' = (`tc_outcome'[1...,1]-`tc_outcome'[1...,2])
		post postperm `ps_posting' (`curr_tru') (${Unit_type_donor})
		
		* Check for quad-programming error
		if `tc_outcome'[1,2]==. {
			continue
		}
		
		if "`permweightsfile'"!=""{
			mat `weights_unr' = e(W_weights_unr)
			drop _all
			qui svmat `weights_unr', names(w)
			rename (w*) (counit weight)
			qui compress counit
			gen int trunit = `curr_tru'
			cap append using "`permweightsfile'${pll_instance}"
			qui save "`permweightsfile'${pll_instance}", replace
		}
	}
	postclose postperm
	`unset_trace'

	cap log close gen_perm_donors
end
