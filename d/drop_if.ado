*! v0.2
*! like -drop if- but appends the if condition to the # dropped msg
*! Helpful if used inside a loop or program where you wouldn't see the command echoed.
program drop_if, rclass
	version 10
	*version is a guess
	syntax anything(equalok everything)
	qui count if `anything'
	local num=`r(N)'
	qui drop if `anything'
	di `"(`num' observations deleted: `anything')"'
	return scalar n_dropped = `num'
end
