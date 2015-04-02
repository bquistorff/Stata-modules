*!  Given a set of predictors, and treatment time:
*!  -drops units without complete info
*!   -will limit sample size if testing
*!  -GE:
*! --will identify donors via GE concerns
*!  --will compare predicttion errors with and without GE containated removed
*!  -Main estimation (including placebo units)
*!  -will check the fit for a t-1 placebo test

*  -TODO: re-estimate without the top match
*  -TODO: Should I generalize the transformation graphs (dmln->ln, ga->ln)?
*  -TODO: Error gracefully when there was an optimization error when estimating on a keeper
program broad_eval_synth_model, rclass
	syntax varname, tr_unit_codes(numlist) tr_unit_titles(string) precise_tyear(int) perms(int) ///
		[predictors(string) cust_predictors_note(string) ///
		ge_mode(int 0) ge_custom_cmd(string) ///
		predictors_plac_remove(string) predictors_plac_add_early(string) predictors_plac_add_late(string) ///
		placebo_unit_codes(numlist) placebo_unit_titles(string) limit_donors(string) base_suff(string) ///
		savepermweights checkhull plot_pe pred_suff(string) obs_weight_char_ds(string) ///
		checklastperiod compare_prederrors full_xlabels(string) tc_gph_opts(string) output_mean_post_RMSPE_donors ///
		noplot_tc_ci nooutput_wmat nooutput_X0_X1 nooutput_vmat nooutput_pvals plot_tc ///
		redo_without_topmatch donor_limit_for_match_cmd(string) connect_ci_to_pre_t ///
		nooutput_diffs nooutput_graph_data]
	
	local depvar "`varlist'"	 
	qui tsset, noquery
	local pvar = "`r(panelvar)'"
	local tvar = "`r(timevar)'"
	
	* Check inputs
	local num_tr_units : word count `tr_unit_codes'
	local num_placebo_units : word count `placebo_unit_codes'
	
	di "start run_synths with: depvar=`depvar', perms=`perms', ge_mode=`ge_mode'"
	qui do code/synth_consts.do
		
	local keeper_codes = "`tr_unit_codes' `placebo_unit_codes'"
	local num_keepers = `num_tr_units' + `num_placebo_units'
	local keeper_codes_commas = subinstr(trim("`keeper_codes'"), " ", ", ", .)
	local tr_unit_codes_commas = subinstr(trim("`tr_unit_codes'"), " ", ", ", .)

	*Get the full list of years
	local random_unit : word 1 of `keeper_codes'
	if `num_keepers'==0{
		* Likely called from cross-validation, so pick a donor at random
		local random_unit = `pvar'[1]
	}
	qui levelsof `tvar' if `pvar'==`random_unit' & `depvar'!=., local(years_tot)
	local num_years : word count `years_tot'
	
	*Get the last pret year
	forval per=1/`num_years'{
		local thisyear : word `per' of `years_tot'
		if `thisyear'>`precise_tyear'{
			local tper = `per'
			continue, break
		}
	}
	local last_pre_year : word `=`tper'-1' of `years_tot'
	local first_treatmentyear : word `tper' of `years_tot'
		
	if "`predictors'"==""{
		local pred_suff = "full"
		*Generate standard (lagged response) variable predictors
		forval per=1/`=`tper'-1'{
			local thisyear : word `per' of `years_tot'
			local predictors = "`predictors' `depvar'(`thisyear')"
		}
		local note "Predictors: all pre-treatment response variables."
	}
	else {
		if "`cust_predictors_note'"!=""{
			local note "Predictors: `cust_predictors_note'."
		}
		else{
			local note "Predictors: `predictors'."
		}
	}
	return local note "`note'"
	
	if `ge_mode'!=${GE_mode_nothing}{
		local ge_suff = "_ge`ge_mode'"
	}
	
	local file_suff "`base_suff'`depvar'_`pred_suff'`ge_suff'${extra_f_suff}"
	return local file_suff "`file_suff'"
	
	cap erase "${dir_base}/data/estimates/todrop_`file_suff'.dta"
	
	*Drop incomplete obs
	tempvar complete_case
	complete_units `predictors', generate(`complete_case')
	di "Dropping incomplete cases"
	drop if !`complete_case'
	drop `complete_case'
	*XXX note in dropfile
	
	if "`limit_donors'"!= ""{
		tempvar keeper1 keeper2
		qui count if `tvar'==`last_pre_year'
		gen `keeper1' = runiform()*r(N)
		bys `pvar': gen `keeper2' = `keeper1'[1]
		di "Dropping because limiting donors"
		keep if (`keeper2' < `limit_donors') | inlist(`pvar', `keeper_codes_commas')
		drop `keeper1' `keeper2'
		*XXX note in dropfile
	}
	
	qui count if `tvar'==`last_pre_year'
	di "Running estimation with `r(N)' units"
	
	local predictors_plac_base : list predictors - predictors_plac_remove
	local early_predictors : list predictors_plac_base | predictors_plac_add_early
	local late_predictors  : list predictors_plac_base | predictors_plac_add_late

	if "`compare_prederrors'"!="" { //pre-drop
		compare_pred_errors , depvar(`depvar') tr_unit_codes(`tr_unit_codes') ///
			file_suff(`file_suff') perms(`perms') ge_suff(_predrop) ///
			early_predictors(`early_predictors') late_predictors(`late_predictors') last_pre_year(`last_pre_year') ///
			precise_tyear(`precise_tyear') first_treatmentyear(`first_treatmentyear') tper(`tper') ///
			donor_limit_for_match_cmd(`donor_limit_for_match_cmd')
	}
	
	*Drop the units that through general equilibrium might be affected by real treatment
	*Nothing if `ge_mode'==${GE_mode_nothing}
	if `ge_mode'==${GE_mode_custom_cmd}{
		di "Dropping due to custom drop command: `ge_custom_cmd'"
		`ge_custom_cmd' , treatment_units(`tr_unit_codes')
	}
	if `ge_mode'==${GE_mode_trim_early_placebo}{
		if "`compare_prederrors'"==""{
			local skip_gen_early_placebo "skip_gen_early_placebo"
		}
		identify_donors_placebo , depvar(`depvar') tr_unit_codes(`tr_unit_codes') predictors(`predictors') ///
			file_suff(`file_suff') last_pre_year(`last_pre_year') ///
			perms(`perms') `skip_gen_early_placebo' early_predictors(`early_predictors') tper(`tper') ///
			precise_tyear(`precise_tyear') first_treatmentyear(`first_treatmentyear') keepunits(`placebo_unit_codes') ///
			onlyonce donor_limit_for_match_cmd(`donor_limit_for_match_cmd')
	}
		
	*Main estimation
	di "Main estimation"
	eval_synth_model, depvar(`depvar') predictors("`predictors'") ///
		perms(`perms') tc_gph_opts(`tc_gph_opts') ttime(`precise_tyear') ///
		file_suff("`file_suff'") `savepermweights' `plot_tc_ci' full_xlabels(`full_xlabels') ///
		tr_unit_codes(`tr_unit_codes') tr_unit_titles(`"`tr_unit_titles'"') ///
		notes("`note'") placebo_unit_codes(`placebo_unit_codes') placebo_unit_titles(`placebo_unit_titles') ///
		obs_weight_char_ds(`obs_weight_char_ds') connect_treat ${do_nest} `plot_pe' ///
		`checkhull' `output_wmat' `output_vmat' `output_pvals' `output_mean_post_RMSPE_donors' ///
		`output_X0_X1' donor_limit_for_match_cmd(`donor_limit_for_match_cmd') `connect_ci_to_pre_t' ///
		`plot_tc' `output_diffs' `output_graph_data'
	tempname cis
	return local eval_noerr_codes "`r(eval_noerr_codes)'"
	if `perms'!=0{
		return scalar main_ci_num = `r(ci_num)'
		return scalar num_perm_act = `r(num_perm_act)'
		foreach unit in `r(eval_noerr_codes)' {
			return scalar perc_perms_match_better`unit' = `r(perc_perms_match_better`unit')'
			mat `cis' = r(cis`unit')
			return matrix cis`unit' = `cis'
		}
	}
	tempname tc_outcome
	foreach unit in `r(eval_noerr_codes)' {
		mat `tc_outcome' = r(tc_outcome`unit')
		return matrix tc_outcome`unit' = `tc_outcome'
	}
	if "`output_mean_post_RMSPE_donors'"!=""{
		tempname mean_post_RMSPE_donors
		scalar `mean_post_RMSPE_donors' = r(mean_post_RMSPE_donors)
		return scalar mean_post_RMSPE_donors = `mean_post_RMSPE_donors'
	}
	
	*Add in nice details to todrop file
    tempfile initdata
    qui save `initdata'
	use "${dir_base}/data/estimates/todrop_`file_suff'.dta", clear
	rename `pvar' set
	if "`obs_weight_char_ds'"!=""{
		merge 1:1 set using "`obs_weight_char_ds'", keep(match) nogenerate
	}
	qui do code/synth_consts.do
	label values reason dr_reasons
	qui save12 "${dir_base}/data/estimates/todrop_`file_suff'.dta", replace
    use `initdata', clear

	*See the p-values testing in the final pre-treatment periods
	if "`checklastperiod'"!=""{
		di "Checking fit on last pre-treatment period"
		eval_synth_model, depvar(`depvar') tr_unit_codes(`tr_unit_codes') predictors(`early_predictors') ///
			justall(1) noplot_tc_ci nooutput_vmat nooutput_wmat nooutput_permn nooutput_graph_data nooutput_X0_X1 ${do_nest} ///
			file_suff(`file_suff'_checklast) ttime(`last_pre_year') end(`last_pre_year') perms(`perms') ///
			donor_limit_for_match_cmd(`donor_limit_for_match_cmd')
	}
	
end
