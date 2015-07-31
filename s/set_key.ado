*! v1.2 Brian Quistorff <bquistorff@gmail.com>
*! Does tasks you normally want to do when you establish a key
program set_key
	version 11 //guess
	
	syntax varlist [, sort order xtset tsset]
	
	isid `varlist'
	char _dta[key] `varlist'
	
	if "`xtset'"!="" xtset `varlist'
	if "`tsset'"!="" tsset `varlist'
	
	if "`sort'"!="" sort `varlist'
	if "`order'"!="" order `varlist', first
end
