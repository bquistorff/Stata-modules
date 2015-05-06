*! version 1.0 Brian Quistorff <bquistorff@gmail.com>
*! Generates a unique id for each pair (like egen ... group())
*! but makes sure they don't have leading 0s
program gen_robust_id
	version 11.0
	*Just a guess at the version
	
	syntax varlist, generate(string)
	
	tempvar tv
	egen `tv' = group(`varlist')
	summ `tv', meanonly
	local nitems = `r(max)'
	local ndigits = floor(log10(`nitems')) + 1
	local base = 10^(`ndigits'-1)
	if `nitems'+`base'>=10^`ndigits'{
		local base = 10^`ndigits'
	}
	gen long `generate' = `tv'+`base'
	compress `generate'
end
