*! version 1.0 Brian Quistorff <bquistorff@gmail.com>
*! Stata bindings for R's ranger package for random forest. Fits and generate predictions (either in standard or out-of-bag)
*!    ranger varlist(fv) [if] [pw/], [predict(string) predict_oob(string) num_trees(int 500)]
program ranger
	version 12.0 //guess
	*TODO: Allow different sample for predict then fit
	*TODO: Could additionally make predictions for obs missing value in variables specified in estimation, but not used any trees in the forest. (though ensure that ranger doesn't error out for that.)
	syntax varlist(fv) [if] [pw/], [predict(string) predict_oob(string) num_trees(int 500) respect_unordered_factors(string) debug]
	if "`respect_unordered_factors'"=="" loc respect_unordered_factors "order"
	tempvar id_varname
	_assert "`predict'`predict_oob'"!="", msg("-predict()- or -predict_oob()- required.")
	
	gettoken outcome Xs : varlist
	
	*Main difference with regression is need to work around fv
	foreach token of local Xs  {
		loc v = subinstr("`token'","i.","",1)
		if "`v'"!="`token'" loc as_f `as_f' `v'
		loc ctrl_vars `ctrl_vars' `v'
	}
	loc est_vars `outcome' `ctrl_vars' `exp'
	tempfile pred_file
	loc pred_file = subinstr("`pred_file'", "\", "/", .)
	
	gen long `id_varname'=_n
	preserve
	if "`if'"!="" keep `if'
	keep `id_varname' `est_vars'
	
	if "`pw'"!="" loc w_opt `", case.weights=df[["`exp'"]]"'
	if "`predict'"!="" {
		loc pred_code `"df_est[["`predict'"]]=predict(rf_fit, df_est)[["predictions"]];"'
		loc final_vars `", "`predict'""'
	}
	if "`predict_oob'"!="" {
		loc pred_code `"`pred_code' df_est[["`predict_oob'"]]=rf_fit[["predictions"]];"'
		loc final_vars `"`final_vars', "`predict_oob'""'
	}
	
	*rcall_check rpart>=4.0, rversion(3.5.0)
	rcall vanilla `debug': suppressWarnings(suppressPackageStartupMessages(library(ranger))); df <- st.data(); for(vname in strsplit("`as_f'", " ")[[1]]){ if(!is.factor(df[[vname]])) df[[vname]] = as.factor(df[[vname]]);}; cc = complete.cases(df); df_est=df[cc,]; form=as.formula(paste0("`outcome' ~", gsub(" ", " + ", "`ctrl_vars'"))); rf_fit=ranger(form, df_est, num.trees=`num_trees', respect.unordered.factors="`respect_unordered_factors'" `w_opt'); `pred_code' df_est = df_est[,c("`id_varname'" `final_vars')]; save.dta13(df_est, "`pred_file'"); rm(cc, df, rf_fit, form, df_est); 
	restore
	qui merge 1:1 `id_varname' using `pred_file', keep(master match) nogenerate
	
	drop `id_varname'
end
