*! If you like to store your config values in a csv file
*! (with headers "key" and "value") then this can retrieve those
*! if testing=1 will check for key-testing first
program get_config_value
	syntax namelist(max=1 name=key) [, local(string) global(string) filepath(string) default(string)]
	
	if "`filepath'"=="" local filepath "code/config.project.csv"
	preserve
	*qui insheet using "`filepath'", comma names clear
	*import is better with handling double-quotes
	qui import delimited "`filepath'", varnames(1) stripquote(no) clear 
	qui count if key=="testing"
	if `r(N)'>0{
		gen byte is_testing = (key=="testing")
		sort is_testing
		local t = value[_N]
		if "`t'"=="1"{
			qui count if key=="`key'-testing"
			if `r(N)'>0 loc key "`key'-testing"
		}
	}
	qui keep if key=="`key'"
	if _N>0{
		local val = value[1]
		di `"get_config_value: `key'=`val'"'
	}
	else{
		local val `"`default'"'
		di `"get_config_value (default): `key'=`val'"'
	}
	restore
	
	if "`local'" !="" c_local `local' `"`val'"'
	if "`global'"!="" global `global' `"`val'"'
end
