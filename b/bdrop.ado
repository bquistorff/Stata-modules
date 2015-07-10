*! v0.1 Brian Quistorff <bquistorff@gmail.com>
*! allows things like -drop emp*, except(emp)-
program bdrop
	version 11
	syntax varlist [, except(string)]
	
	unab varlist_full : `varlist'
	local to_drop : list varlist_full - except
	drop `to_drop'
end
