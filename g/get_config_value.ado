*! v1.2 Brian Quistorff <bquistorff@gmail.com>
*! If you like to store your config values in a csv file
*! (with headers "key" and "value") then this can retrieve those
*! Will default to local of the name `key'
*! if testing=1 will check for key-testing first
*! binding quotes will be removed (Stata style)
*! if you want to encode:"yes no","wow wow"
*! Then you should write:`""yes no","wow wow""'
program get_config_value
	version 11.0 //just a guess here
	syntax namelist(max=1 name=key) [, local(string) global(string) filepath(string) default(string)]
	
	if "`filepath'"=="" local filepath "${main_root}code/config.project.csv"
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
		* If double quotes are just binding, then remove (like you need to enclose a ",")
		* Don't use -import delimited, stripquotes(default)- because that converts other quotes
		if (length(`"`val'"')>1 & `:word count `val''==1) local val `val'
		di `"get_config_value: `key'=`val'"'
	}
	else{
		local val `"`default'"'
		di `"get_config_value (default): `key'=`val'"'
	}
	restore
	
	if "`global'"!="" global `global' `"`val'"'
	else{
		if "`local'"=="" local local `key'
		c_local `local' `"`val'"'
	}
end
