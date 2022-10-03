*! version 1.0 Brian Quistorff <bquistorff@gmail.com>
*! Stata bindings for R's ranger package for random forest. Fits and generate predictions (either in standard or out-of-bag)
*!    ranger varlist(fv) [if] [pw/], [predict(string) predict_oob(string) num_trees(int 500)]
* predict_oob will do out-of-bag for estimation sample (if)
* predict will do predictions for whole sample
program ranger, eclass
	version 12.0 //guess
	*TODO: Allow different sample for predict then fit
	*TODO: Could additionally make predictions for obs missing value in variables specified in estimation, but not used any trees in the forest. (though ensure that ranger doesn't error out for that.)
	syntax varlist(fv) [if/] [pw/], [predict(string) predict_oob(string) num_trees(int 500) respect_unordered_factors(string) seed(string) debug importance(string)]
	if "`respect_unordered_factors'"=="" loc respect_unordered_factors "order"
	if "`importance'"!="" {
		loc importance_opt `", importance="`importance'" "'
		loc importance_code `"var_imp = t(as.matrix(rf_fit[["variable.importance"]]));"'
	}
	if "`seed'"=="" loc seed "NULL"
	if "`c(mode)'"=="batch" & "`c(os)'"=="Windows" {
		loc shell shell(bshell cmd /c)
	}
	tempvar id_varname
	
	gettoken outcome Xs : varlist
	
	*Main difference with regression is need to work around fv
	foreach token of local Xs  {
		loc v = subinstr("`token'","i.","",1)
		if "`v'"!="`token'" loc as_f `as_f' `v'
		loc ctrl_vars `ctrl_vars' `v'
	}
	loc est_vars `outcome' `ctrl_vars' `exp'
	
	gen long `id_varname'=_n
	preserve
	if "`if'"!="" {
		tempvar if_est
		gen byte `if_est' = `if'
		loc est_logic `"& df[["`if_est'"]]"'
	}
	keep `id_varname' `est_vars' `if_est'
	
	if "`pw'"!="" loc w_opt `", case.weights=df[["`exp'"]]"'
	if "`predict'`predict_oob'"!="" {
		tempfile pred_file
		loc pred_file = subinstr("`pred_file'", "\", "/", .)
		loc pred_code `"df_save = df[cc,c("`id_varname'"), drop=FALSE]; "'
		loc pred_vars ", df_save"
		loc pred_code2 `"save.dta13(df_save, "`pred_file'");"'
	}
	if "`predict'"!="" {
		loc pred_code `"`pred_code' df_save[["`predict'"]]=predict(rf_fit, df[cc,])[["predictions"]]; "'
	}
	if "`predict_oob'"!="" {
		loc pred_code `"`pred_code' df_est[["`predict_oob'"]]=rf_fit[["predictions"]]; df_save=merge(df_save, df_est[,c("`id_varname'", "`predict_oob'")], all=TRUE); "'
	}
	
	*rcall_check rpart>=4.0, rversion(3.5.0)
	rcall vanilla `shell' `debug': suppressWarnings(suppressPackageStartupMessages(library(ranger))); df <- st.data(); for(vname in strsplit("`as_f'", " ")[[1]]){ if(!is.factor(df[[vname]])) df[[vname]] = as.factor(df[[vname]]);}; cc = complete.cases(df); df_est=df[cc `est_logic',]; form=as.formula(paste0("`outcome' ~", gsub(" ", " + ", "`ctrl_vars'"))); rf_fit=ranger(form, df_est, num.trees=`num_trees', respect.unordered.factors="`respect_unordered_factors'", seed=`seed' `w_opt' `importance_opt'); `pred_code' `pred_code2' `importance_code' rm(cc, df, rf_fit, form, df_est `pred_vars'); 
	if "`importance'"!="" {
		tempname vi
		mat `vi' = r(var_imp)
		ereturn post `vi'
		ereturn local depvar = "`outcome'"
		ereturn local cmd = "ranger"
	}
	restore
	if "`predict'`predict_oob'"!="" {
		qui merge 1:1 `id_varname' using `pred_file', keep(master match) nogenerate
		sort `id_varname'
	}
	drop `id_varname'
end
