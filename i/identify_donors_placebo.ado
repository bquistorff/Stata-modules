*! Identifies uncontaminated donors with a temporal placebo test
program identify_donors_placebo
	version 11.0 //just a guess here
	syntax , depvar(varname) predictors(string) tr_unit_codes(numlist integer) ///
		early_predictors(string) precise_tyear(int) last_pre_year(int) tper(int) ///
		file_suff(string) perms(int) first_treatmentyear(int) ///
		[skip_gen_early_placebo keepunits(numlist integer) width(int 5) onlyonce ///
		donor_limit_for_match_cmd(string)] 
		
	di "Starting to determine other treated units by comparing early placebo to normal. Width=`width'"
	qui do code/synth_consts.do
	*pause
	*Do the early placebo to get a good distribution
	if "`skip_gen_early_placebo'"!="" {
		di "Doing an early placebo (pre-drop)"
		eval_synth_model, depvar(`depvar') tr_unit_codes(`tr_unit_codes') predictors(`early_predictors') ///
			justall(1) noplot_tc_ci nooutput_vmat nooutput_wmat nooutput_permn nooutput_pvals nooutput_X0_X1 nooutput_graph_data ${do_nest} ///
			file_suff(`file_suff'_pret_sub_predrop) ttime(`last_pre_year') end(`last_pre_year') perms(`perms') ///
			donor_limit_for_match_cmd(`donor_limit_for_match_cmd')
	}

	count if codigo==codigo[1]
	local nyears = r(N)
	
    tempfile initdata
    qui save `initdata'
	use "${dir_base}/data/estimates/gen_perm_br_`file_suff'_pret_sub_predrop.dta", clear
	cap keep if unit_type==${Unit_type_donor}
	cap drop unit_type
	local placebo_tper = `tper'-1
	qui summ PE`placebo_tper', detail
	local p_low = "`r(p`width')'"
	local p_high = "`r(p`=100-`width'')'"
	di "Removing MCAs with deviations larger less than `p_low' and larger than `p_high'"
    use `initdata', clear

	*Now repeatedly do synth (just 1 post-t year) but clearing away any donors that are above
	*might throw out some donors, but that's OK. 
	*Hopefully I get to a stable set
	local last_N = "."
	local trim_i = 1
	local keepers_commaed = subinstr(trim("`tr_unit_codes' `keepunits'"), " ", ", ", .)
	while _N!=`last_N' {
		local last_N = _N
		di "Starting trim iteration `trim_i'. We have `=`last_N'/`nyears'' units (`last_N' obs) left"
		
		eval_synth_model, depvar(`depvar') predictors(`predictors') perms(`perms') ttime(`precise_tyear') ///
			file_suff("`file_suff'_trial`trim_i'") tr_unit_codes(`tr_unit_codes') ${do_nest} ///
			noplot_tc_ci nooutput_vmat nooutput_wmat nooutput_permn nooutput_X0_X1 nooutput_pvals nooutput_graph_data ///
			end(`first_treatmentyear') donor_limit_for_match_cmd(`donor_limit_for_match_cmd')
		
		*Update the todrop file
		tempfile inner
		qui save `inner'
		use "${dir_base}/data/estimates/gen_perm_br_`file_suff'_trial`trim_i'.dta", replace
		keep if unit_type==${Unit_type_donor}
		drop unit_type
		qui keep if (PE`tper'<`p_low' | PE`tper'>`p_high')
		gen reason = ${Synth_PE_low}
		replace reason = ${Synth_PE_high} if (PE`tper'>`p_high')
		keep codigo reason
		cap append using "${dir_base}/data/estimates/todrop_`file_suff'.dta"
		qui save "${dir_base}/data/estimates/todrop_`file_suff'.dta", replace
		use `inner', clear
		
		*Remove the contaminated ones
		merge m:1 codigo using "${dir_base}/data/estimates/todrop_`file_suff'.dta", keep(master match) keepusing(codigo) noreport
		di "Dropping for a loop of -identify_donors_placebo-"
		drop if _merge==3 & !inlist(codigo, `keepers_commaed')
		drop _merge
		local trim_i = `trim_i'+1
		
		if "`onlyonce'"!=""{
			continue, break
		}
	}
	
	di "Finished determining other treated units"
end
