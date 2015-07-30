*! eval_synth_model: For given predictors, treatment time, donors, treated units, and placebo units. 
*!              Computes the model, does RI, produces graphs & tables, converts to delta_t=1
* 
*Required globals: dir_base
* Needs the data to be in a strongly balanced panel
program eval_synth_model, rclass
	version 11.0 //just a guess here
	syntax , depvar(varname) predictors(string) ttime(int) perms(int) ///
		[file_suff(string) tr_unit_codes(numlist integer) tr_unit_titles(string) tc_gph_opts(string) notes(string) ///
		obs_weight_char_ds(string) justall(int 0) alpha(string) full_xlabels(string) donor_limit_for_match_cmd(string) ///
		end(string) start(string) nested placebo_unit_codes(numlist) placebo_unit_titles(string) ///
		savepermweights checkhull connect_treat plot_pe plot_tc output_mean_post_RMSPE_donors ///
		noplot_tc_ci nooutput_vmat nooutput_wmat nooutput_pvals nooutput_permn ///
		nooutput_diffs nooutput_X0_X1 nooutput_graph_data connect_ci_to_pre_t]

	*Check arguments
	local num_placebo_units : word count `placebo_unit_codes'
	assert_msg (`num_placebo_units'==`: word count `placebo_unit_titles''), message("Placebo unit info lenghts !=")
	
	qui do code/synth_consts.do
	
	tempfile initdatafile
	qui save "`initdatafile'", replace
	
	di "start eval_model. Depvar=`depvar'"
	
	if "`file_suff'"==""{
		local file_suff = "`depvar'"
	}
	if `"`tr_unit_titles'"'==""{
		local tr_unit_titles = "`tr_unit_codes'"
	}
	
	qui tsset, noquery
	local pvar = "`r(panelvar)'"
	local tvar = "`r(timevar)'"
	local orig_tvar = "`r(timevar)'"
	
	local num_trunits : word count `tr_unit_codes'
	
	
	if "`output_diffs'"=="nooutput_diffs"{
		tempfile diffsfile
	}
	else {
		local diffsfile "${dir_base}/data/estimates/gen_perm_br_`file_suff'.dta"
	}
	
	local random_unit : word 1 of `tr_unit_codes'
	if `num_trunits'==0{
		* Likely called from cross-validation, so pick a donor at random
		local random_unit = `pvar'[1]
	}
	qui summ `tvar' if `pvar'==`random_unit' & `depvar'!=.
	if "`end'"=="" {
		local end = r(max)
	}
	if "`start'"=="" {
		local start = r(min)
	}
	
	*Remove units that have missing data
	
	*Do I need to recode the time var as periods?
	if r(N)<r(max)-r(min)+1{
		sort `pvar' `tvar'
		
		qui levelsof `tvar' if `pvar'==`random_unit', local(times)
		local num_times : word count `times'
		tempname per_year
		egen period = group(`tvar')
		
		qui tsset `pvar' period
		local tvar = "period"
		local endtime = `end'
		local starttime = `start'
		forval per=`num_times'(-1)1{
			local time : word `per' of `times'
			local vallabelstr = `"`per' "`time'" `vallabelstr'"'
			
			if `time'>`endtime'{
				continue
			}
			if `time'==`endtime'{
				local end = `per'
			}
			if `time'==`starttime'{
				local start = `per'
			}
			if `time'<`ttime'{
				local pre_tvar_labels = "`time' `pre_tvar_labels'"
			}
			else{
				local post_tvar_labels = "`time' `post_tvar_labels'"
				local tper = `per' //catch the last one
			}

			local predictors : subinstr local predictors "(`time')" "(`per')", all
		}
		label define `per_year' `vallabelstr'
		label values period `per_year'
		local tperlabel = `ttime'
	}
	else {
		local tper = `ttime'
		forval per=`start'/`=`ttime'-1'{
			local pre_tvar_labels = "`pre_tvar_labels' `per'"
		}
		forval per=`ttime'/`end'{
			local post_tvar_labels = "`post_tvar_labels' `per'"
		}
		local tperlabel = `ttime'
	}
	
	local last_pre = `tper'-1
	**mac dir
	local ytitle : variable label `depvar'
	
	tempname Vdiag weights weights_unr x_bal pred_mat y_diff_perm X1 X0
	
	if "`donor_limit_for_match_cmd'"!=""{
		local donor_limit_for_match_cmd "`donor_limit_for_match_cmd' \`trun'"
	}
	
	forval i = 1/`num_trunits'{
		*Initial
		if `i'==1{
			cap postclose postdiff
			matrix_post_lines , matrix(`y_diff_perm') varstub(PE) varnumstart(`start') varnumend(`end')
			local ps_posting "`s(ps_posting)'"
			qui postfile postdiff `s(ps_init)' int `pvar' byte unit_type using "`diffsfile'", replace 
		}
		local title : word `i' of `tr_unit_titles'
		local trun : word `i' of `tr_unit_codes'
		local file_ind = `i'-1
		tempname tc_outcome`trun' y_diff`trun'
		
		
		tempfile intm1
		qui save `intm1'
		foreach trun2 in `tr_unit_codes'{
			if `trun2'!=`trun'{
				qui drop if `pvar'==`trun2'
			}
		}
		`donor_limit_for_match_cmd'
		if "`checkhull'"!=""{
			if "`orig_tvar'"!="`tvar"{
				local gph_tvar_opt "gph_tvar(`orig_tvar')"
			}
			check_in_convex_hull `depvar', first_pre(`start') last_pre(`last_pre') ///
				end(`end') trunit(`trun') file_suff(t`file_ind'_`file_suff') ///
				`gph_tvar_opt' xlabels(`full_xlabels') main_label(`title') tper_spec(`tperlabel')
		}
		
		if "`nested'"!=""{
			di "Starting synth estimation on treated=`trun'"
		}
		*Note : trperiod is first year under treatment
		qui synth `depvar' `predictors', trunit(`trun') `nested' ///
			mspeperiod(`start'(1)`last_pre') resultsperiod(`tper'(1)`end') trperiod(`tper')
		if "`nested'"!=""{
			di "Finished synth estimation on treated=`trun'"
		}
		
		qui use `intm1', clear
		if _rc ==1 {
			error 1
		}
		if _rc !=0{
			local tr_err_codes "`tr_err_codes' `trun'"
			local tr_err_titles `"`tr_err_titles' `title'"'
			continue
		}
		
		mat `Vdiag' = (vecdiag(e(V_matrix)))'
		mat `weights' = e(W_weights) 
		mat `weights_unr' = e(W_weights_unr)
		mat `tc_outcome`trun'' = e(Zbal) \ e(Ybal)
		mat `x_bal' = e(X_balance)
		mat `X0' = e(X0_normalized)
		mat `X1' = e(X1_normalized)
		mat `y_diff`trun'' = (`tc_outcome`trun''[1...,1]-`tc_outcome`trun''[1...,2])
		mat `y_diff_perm' = `y_diff`trun''
		
		post postdiff `ps_posting' (`trun') (${Unit_type_treated})

		if "`output_vmat'"!="nooutput_vmat"{
			mat `pred_mat' = `Vdiag', `x_bal'
			matrix colnames `pred_mat' = weight treated control
			output_pred_mat , mattype("v-weights") year_replace_period_list("`pre_tvar_labels'") ///
				file_suff("t`file_ind'_`file_suff'") mat(`pred_mat')
		}
		*The rounded weights are good for display
		if "`output_wmat'"!="nooutput_wmat"{
			output_unit_matches , numb(10) file_suff(t`file_ind'_`file_suff') match_file(`obs_weight_char_ds') ///
				weights_unr(`weights_unr') weights(`weights')
		}
		
		if "`plot_tc'"!=""{
			graph_tc , start(`start')  xlabels(`full_xlabels') file_suff("t`file_ind'_`file_suff'") title("`title'") ///
				notes("`notes'") tper_spec(`tperlabel') ytitle("`ytitle'") tc_outcome(`tc_outcome`trun'') ///
				tval_labels("`pre_tvar_labels' `post_tvar_labels'") tc_gph_opts(`tc_gph_opts')  main_label(`title')
		}
		
		if "`output_X0_X1'"!="nooutput_X0_X1"{
			forval j=0/1{
				mat `X`j'' = `X`j'''
				local cnames : colnames `X`j''
				local cnames = subinstr("`cnames'",")","",.)
				local cnames = subinstr("`cnames'","(","__",.)
				mat colnames `X`j'' = `cnames'
				matsave `X`j'', replace path("${dir_base}/data/generated/synth_mats/X`j'_t`file_ind'_`file_suff'.dta")
			}
		}
		*Final
		if `i'==`num_trunits'{
			postclose postdiff
		}
	}
	local tr_noerr_codes : list tr_unit_codes - tr_err_codes
	local tr_noerr_titles : list tr_unit_titles - tr_err_titles
	local num_trunits_noerr : word count `tr_noerr_codes'
	discard //good measure
	if `perms'==0 {
		qui use "`initdatafile'", clear
		exit = 0
	}

	tempfile just_donors_file permsdiff intm2 intm3
	
	qui save `intm2'
	*Limit to just potential donors
	foreach trun in `tr_unit_codes'{
		qui drop if `pvar'==`trun'
	}
	
	
	qui save "`just_donors_file'", replace
	
	qui count if `tvar'==`start'
	local nunits =  `r(N)'
	
	tempname donor_order donors_touse y_diffs y_diffs_t p_vals outmat
	tempvar rand
	gen `rand' = uniform()
	if `num_placebo_units'>0 {
		local placebo_unit_codes_commas = subinstr(trim("`placebo_unit_codes'"), " ", ", ", .)
		qui replace `rand'=0 if inlist(`pvar',`placebo_unit_codes_commas')
	}
	sort `rand'
	mkmat `pvar' if `tvar'==`start', matrix(`donor_order')
	use `intm2', clear
	
	if `perms'==-1 | `perms'>`nunits'{
		local perms = `nunits'
	}
	mat `donors_touse' = `donor_order'[1..`perms',1]
	
	*The predictors str makes the whole string too long for parallel to process so pass as global
	global fargs "predictors(`predictors')"
	if "`savepermweights'"!=""{
		local permweightsfile "${dir_base}/data/estimates/weights/permweights_`file_suff'.dta"
		cap erase "`permweightsfile'"
	}
	
	* Run permuations estimations
	qui save `intm3'
	if "${numclusters}"=="" | "${numclusters}"=="1"{
		mata: donors_touse = st_matrix("`donors_touse'")
		gen_perm_donors , donor_mat(donors_touse) outfile("`permsdiff'") ///
			start(`start') tper(`tper') end(`end') depvar(`depvar') `nested' ///
			infile("`just_donors_file'") permweightsfile("`permweightsfile'") donor_limit_for_match_cmd(`donor_limit_for_match_cmd')
	}
	else{
		parallel_justout_helper , donor_mat(`donors_touse') cmd_base(gen_perm_donors) outfile("`permsdiff'")  ///
			permweightsfile(`permweightsfile') ///
			cmd_options(`"start(`start') tper(`tper') end(`end') depvar(`depvar') infile("`just_donors_file'") `nested' donor_limit_for_match_cmd(`donor_limit_for_match_cmd')"')
	}
	use "`permsdiff'", clear
	sort `pvar'
	* Filter out the optimization errors
	qui keep if PE`start'==.
	keep `pvar'
	gen reason = ${Synth_opt_error}
	cap append using "${dir_base}/data/estimates/todrop_`file_suff'.dta"
	qui save12 "${dir_base}/data/estimates/todrop_`file_suff'.dta", replace
	
	use "`permsdiff'", clear
	sort `pvar'
	qui drop if PE`start'==.
	
	local perms_actual = _N
	mkmat PE*, mat(`y_diffs_t')
	mat `y_diffs' = `y_diffs_t''
	
	if `num_trunits'>=1{
		append using "`diffsfile'"
	}
	qui save12 "`diffsfile'", replace
	
	if "`permweightsfile'"!=""{
		use "`permweightsfile'", clear
		qui save12 "`permweightsfile'", replace
	}
	
	use `intm3', clear
	
	local pre_len =`tper'-`start' 
	if "`output_mean_post_RMSPE_donors'"!=""{
		tempname mean_post_RMSPE_donors
		mata: mean_post_RMSPEs("`y_diffs'", `pre_len')
		scalar `mean_post_RMSPE_donors' = r(mean_post_RMSPEs)
		return scalar mean_post_RMSPE_donors = `mean_post_RMSPE_donors'
	}
	
	if "`tperlabel'"=="" {
		if "`post_tvar_labels'"==""{
			local tperlabel = `tper'
		}
		else {
			local tperlabel : word 1 of `post_tvar_labels'
		}
	}
	forval i = 1/`num_placebo_units' {
		local placebo_unit_code : word `i' of `placebo_unit_codes'
		tempname tc_outcome`placebo_unit_code' y_diff`placebo_unit_code'
		cap build_graphing_mats `placebo_unit_code', depvar(`depvar') startper(`start') perms_file("`diffsfile'")
		if _rc !=0{
			local placebo_err_codes "`placebo_err_codes' `placebo_unit_code'"
			local placebo_err_titles `"`placebo_err_titles' `: word `i' of `placebo_unit_titles''"'
			continue
		}
		matrix `tc_outcome`placebo_unit_code'' = r(tc_outcome)
		matrix `y_diff`placebo_unit_code'' = r(y_diff)
	}
	local placebo_noerr_codes : list placebo_unit_codes - placebo_err_codes
	local placebo_noerr_titles : list placebo_unit_titles - placebo_err_titles
	local eval_unit_codes =trim("`tr_noerr_codes' `placebo_noerr_codes'")
	local eval_unit_titles =trim(`"`tr_noerr_titles' `placebo_noerr_titles'"')
	local num_eval_units : word count `eval_unit_codes'
	
	* Outputs involving permutations
	forval i = 1/`num_eval_units'{
		local eval_unit : word `i' of `eval_unit_codes'
		local title : word `i' of `eval_unit_titles'
		tempname CIs`eval_unit'

		local file_ind = `i'-1
		
		if "`plot_pe'"!=""{
			graph_PEs, start(`start') file_suff("t`file_ind'_`file_suff'") main_label(`title') ///
				title("`title'") notes("`notes'") tper_spec(`tperlabel') ytitle("`ytitle'") xlabels(`full_xlabels') ///
				tval_labels("`pre_tvar_labels' `post_tvar_labels'") y_diff(`y_diff`eval_unit'') y_diffs(`y_diffs')
		}
		
		mata: eval_placebo("`y_diff`eval_unit''", "`y_diffs'", `pre_len', `justall', "`post_tvar_labels'")
		local perc_perms_match_better`eval_unit' : display %2.0f 100*r(howgood_match)
		mat `p_vals' = r(p_vals)
		di "good_match (`title'): `perc_perms_match_better`eval_unit''% of the permutation tests had lower pre-treatment RMSPEs."
		
		if "`output_pvals'"!="nooutput_pvals"{
			di "P-values (permutation, `title')"
			output_pval_table , matrix(`p_vals') file_base("p-vals_t`file_ind'_`file_suff'") ///
				note("P-values from `perms_actual' permutation tests. `perc_perms_match_better`eval_unit''\% of the permutation tests had lower pre-treatment RMSPEs.")
		}
		
		mata: makeCIs(`pre_len', "`y_diff`eval_unit''", "`y_diffs'", "`tc_outcome`eval_unit''", `alpha')
		mat `CIs`eval_unit'' = r(CIs)
		local ci_num : display %2.0f 100*(1-r(CI_pval))
		return scalar ci_num = `ci_num'
		if "`plot_tc_ci'"!="noplot_tc_ci"{
			graph_tc_ci , file_suff("t`file_ind'_`file_suff'")  tc_gph_opts(`tc_gph_opts') title("`title'") ///
				notes("`notes'") num_reps(`perms_actual') tc_outcome(`tc_outcome`eval_unit'') cis(`CIs`eval_unit'') ///
				perc_perms_match_better(`perc_perms_match_better`eval_unit'') `connect_treat' ci_num(`ci_num') ///
				tper_spec(`tperlabel') ytitle("`ytitle'") tval_labels("`pre_tvar_labels' `post_tvar_labels'") ///
				xlabels(`full_xlabels') start(`start') main_label(`title') `connect_ci_to_pre_t'
		}
		if "`output_graph_data'"!="nooutput_graph_data"{
			mat `outmat' = `tc_outcome`eval_unit'', `CIs`eval_unit''
			mat colnames `outmat' = Treatment Control CI_low CI_high
			matsave `outmat', replace path("${dir_base}/data/estimates/graph_data_`file_suff'_u`eval_unit'.dta")
		}
	}
	if "`output_permn'"!="nooutput_permn"{
		qui writeout_txt `perms_actual' "num_perm_`file_suff'"
	}
	
	*Remember can exit in the middle if no perms
	qui use "`initdatafile'", clear
	return scalar num_perm_act = `perms_actual'
	return local eval_noerr_codes "`eval_unit_codes'"
	foreach eval_unit in `eval_unit_codes'{
		return scalar perc_perms_match_better`eval_unit' = `perc_perms_match_better`eval_unit''
		return matrix tc_outcome`eval_unit' = `tc_outcome`eval_unit''
		return matrix cis`eval_unit' = `CIs`eval_unit''
	}
end
