*! version 0.1 Brian Quistorff
*! Cross-fitting a model to product honest predictions/residuals and fit statistics:
*!   crossfit newvar [, k(int 5) by(varname) residuals outcome(varname) nodots] : est_cmd
*! est_cmd needs to fit the basic "syntax" format (we sneak in a new 'if' clause)
*! Simple usage: crossfit price_hat_oos, k(5) outcome(price): reg price mpg
*! This will generate out-of-sample predictions price_hat_oos and provide fit metrics: R2, MSE, MAE
program crossfit, eclass
	version 12.0 //guess
	* I could've allowed est_cmd to be unrestircted, but then I would've had to preserve, filter, restore a bunch and 
	*  this would also kill [in] as the sample changes.
	*TODO: Could keep track of the individual estimations (and e(sample)?) and then allow predict on a potentially new/modified sample.
	*      This could switch to -crossfit- and then -predict- steps.
	_on_colon_parse `0'
	loc 0 `s(before)'
	loc est_cmd_all `s(after)'
	syntax anything(name=newvar) [, k(int 5) by(varname) residuals outcome(varname) nodots]
	loc 0 `est_cmd_all'
	syntax anything(equalok name=est_cmd) [if/] [in] [fw aw pw iw/] [, *]
	
	if "`if'"!="" loc if_and "& `if'"
	
	*get groups
	if "`by'"=="" {
		tempvar rand by
		gen `rand' = runiform()
		gen int `by' = floor(`rand'*`k') +1
	}
	else {
		_assert "`k'"!="", msg("k or by() required")
		summ `by', meanonly
		loc k `r(max)'
	}
	
	*sort real from temp vars
	if "`residuals'"!="" {
		_assert "`outcome'"!="", msg("-, outcome()- required with -, residuals-")
		loc res `newvar'
		tempvar pred
	}
	else {
		loc pred `newvar'
		if "`outcome'"!="" tempvar res
	}
	if "`weight'"!="" loc weight_str [`weight'=`exp']
	
	tempvar i_pred
	qui gen `pred'=.
	if "`dots'"!="nodots" _dots 0, title(Folds) reps(`k')
	forv i=1/`k' {
		qui `est_cmd' if `by'!=`i' `if_and' `in' `weight_str', `options'
		qui predict `i_pred', xb
		qui replace `pred'=`i_pred' if `by'==`i' `if_and'
		drop `i_pred'
		if "`dots'"!="nodots" _dots `i' 0
	}
	if "`dots'"!="nodots" di _n
	
	if "`res'"!="" {
		ereturn clear
		qui corr `outcome' `pred'
		ereturn scalar r2 = r(rho)^2
		
		gen `res' = `outcome' - `pred'
		tempvar res2 abs_res
		gen `res2' = `res'^2
		summ `res2', meanonly
		ereturn scalar mse = `r(mean)'
		gen `abs_res' = abs(`res')
		summ `abs_res', meanonly
		ereturn scalar mae = `r(mean)'
	}
end

/*
* Tests
sysuse auto
crossfit price_hat_oos, k(5): reg price mpg

*/
