*! version 1.1 Brian Quistorff <bquistorff@gmail.com>
*! A simple way to advance the Stata RNG state by a fixed amount
*! Will also fill a variable with a sequence of such states
*! (first obs gets current state, user capture state after function for continuing).
program rng_advance
	version 12
	syntax anything [, var(string) amount(string)]
	
	if "`anything'"=="replace" rng_advance_replace, var(`var')
	if "`anything'"=="step" rng_advance_step, amount(`amount')
end

mata:
void m_rng_advance_replace(string scalar varn){
	N= st_nobs()
	seed_nums = runiform(N,1)*c("maxlong")
	seed_sts  = J(N,1,"")
	final_rng_st = c("seed")
	for(i=1; i<=N; i++){
		rseed(seed_nums[i,1])
		seed_sts[i,1] = rseed()
	}
	st_sstore(.,varn,seed_sts) 
	rseed(final_rng_st)
}
end

program rng_advance_replace
	version 12
	syntax , var(string)
	replace `var'="`c(seed)'" if _n==1 //just to widen the string.
	mata: m_rng_advance_replace("`var'")
end

* Deprecated. Takes time and requires user to know 
*  the amount to advance by for each loop (which may not be known ahead of time)
program rng_advance_replace_inline
	version 12
	syntax , var(string) amount(int)
	forvalues i=1/`=_N' {
		replace `var'="`c(seed)'" in `i'
		rng_advance_step, amount(`amount')
	}
end

program rng_advance_step
	version 12
	syntax , amount(int)

	tempname tmp_mat
	while `amount'>`c(matsize)' {
		*mata's runiform is way faster than matuniform
		qui mata: runiform(`c(matsize)',1)
		local amount = `amount' - `c(matsize)'
	}
	qui mata: runiform(`amount',1)
end
