*! v1.1 Brian Quistorff <bquistorff@gmail.com>
*! Does tasks you normally want to do when you establish a key
*! stock_cmd is usually 'xtset' or 'tsset' and si passed the varlist
program set_key
	version 11 //guess
	
	syntax varlist [, sort order stock_cmd(string)]
	
	isid `varlist'
	char _dta[key] `varlist'
	if "`stock_cmd'"!="" `stock_cmd' `varlist'
	if "`sort'"!="" sort `varlist'
	if "`order'"!="" order `varlist', first
end
