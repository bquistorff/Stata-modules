*! Compares the prediction errors from the normal setup with a placebo test one period before
program compare_pred_errors
	syntax , depvar(string) tr_unit_codes(string) file_suff(string) perms(int) ge_suff(string) ///
		early_predictors(string) late_predictors(string) precise_tyear(int) ///
		first_treatmentyear(int) last_pre_year(int) tper(int) [plac_late_start(string) ///
		donor_limit_for_match_cmd(string)]
	local placebo_tper = `tper'-1
	
	di "Comparing predictive errors"
	*Do a one decade earlier placebo (1 post)
	eval_synth_model, depvar(`depvar') tr_unit_codes(`trunints') predictors(`early_predictors') ///
		justall(1) noplot_tc_ci nooutput_vmat nooutput_wmat nooutput_permn nooutput_pvals nooutput_X0_X1 nooutput_graph_data ${do_nest} ///
		file_suff(`file_suff'_pret_sub`ge_suff') ttime(`last_pre_year') end(`last_pre_year') perms(`perms') ///
		donor_limit_for_match_cmd(`donor_limit_for_match_cmd')

	*Do the normal (1 post) but with
	eval_synth_model, depvar(`depvar') tr_unit_codes(`trunints') predictors(`late_predictors') ///
		justall(1) noplot_tc_ci nooutput_vmat nooutput_wmat nooutput_permn nooutput_pvals nooutput_X0_X1 nooutput_graph_data ${do_nest} ///
		file_suff(`file_suff'_pret_sub2`ge_suff') ttime(`precise_tyear') end(`first_treatmentyear') ///
		perms(`perms') start(`plac_late_start') donor_limit_for_match_cmd(`donor_limit_for_match_cmd')
	
    tempfile initdata
    qui save `initdata'
	*Get rid of the treatment
	foreach subtype in sub sub2 {
		use    "${dir_base}/data/estimates/gen_perm_br_`file_suff'_pret_`subtype'`ge_suff'.dta", clear
		qui keep if unit_type==${Unit_type_donor}
		qui drop unit_type
		qui save12 "${dir_base}/data/estimates/gen_perm_br_`file_suff'_pret_`subtype'`ge_suff'.dta", replace
	}
	
	*Graph them
	use "${dir_base}/data/estimates/gen_perm_br_`file_suff'_pret_sub`ge_suff'.dta", clear
	keep PE`placebo_tper' codigo
	rename PE`placebo_tper' earlyPE
	merge 1:1 codigo using "${dir_base}/data/estimates/gen_perm_br_`file_suff'_pret_sub2`ge_suff'.dta", ///
		keep(match) keepusing(PE`tper') nogenerate noreport
	rename PE`tper' latePE
	local longtext "Kernel density of prediction errors from separate synthetic controls, each using six pre-treatment periods of population."
	wrap_text , unwrappedtext("`longtext'")
	local wrapped `"`s(wrappedtext)'"'
	twoway (kdensity earlyPE /*if abs(earlyPE)<0.5*/) (kdensity latePE /*if abs(latePE)<0.6*/), ///
		xtitle("Prediction Errors") title("Density") legend(order(1 "Treatment=1950" 2 "Treatment=1960")) ///
		name(`=strtoname("PE_normal_v_plac_`file_suff'`ge_suff'",1)', replace)  ///
		note(`wrapped')
	qui save_fig "pred_errors_normal_earlyplacebo_`file_suff'`ge_suff'"
	drop latePE
	rename earlyPE PE8
	gen byte early = 1
	append using "${dir_base}/data/estimates/gen_perm_br_`file_suff'_pret_sub2`ge_suff'.dta", keep(PE8 codigo)
	replace early = 0 if early==.
	rename PE8 PE
	di "The combined p-value is for the null of equality (so high p-value means can't reject that the same)"
	ksmirnov PE, by(early)
	local p_cor : display %5.3f `r(p_cor)' 
	writeout_txt `p_cor' "KS_pval_compre_pred_errors_`file_suff'`ge_suff'"
    use `initdata', clear
end
