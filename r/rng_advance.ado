*! version 1.0
*! A simple way to advance the Stata RNG state by a fixed amount
*! Will also fill a variable with a sequence of such states
*! (first obs gets current state, user capture state after function for continuing).
program rng_advance
	version 12
	syntax anything [, var(string) amount(int 500)]
	
	rng_advance_`anything', var(`var') amount(`amount')
end

program rng_advance_replace
	version 12
	syntax , var(string) [amount(int 500)]
	forvalues i=1/`=_N' {
		replace `var'="`c(seed)'" in `i'
		rng_advance_step, amount(`amount')
	}
end

program rng_advance_step
	version 12
	syntax [, amount(int 500)]

	tempname tmp_mat
    while `amount'>`c(matsize)' {
        mat tmp_mat = matuniform(`c(matsize)',1)
        local amount = `amount' - `c(matsize)'
    }
	mat tmp_mat = matuniform(`amount',1)
end
