*! v0.2
*! like -drop if- but:
*! 1) appends the if condition to the # dropped msg (nice for loops/programs where commands aren't echoed)
*! 2) returns r(n_dropped)
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
