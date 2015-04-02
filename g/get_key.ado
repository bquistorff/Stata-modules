*! version 1.0
*! Retrieves the key
program get_key, sclass
	version 11 //guess
	
	loc key : char _dta[key]
	di "key: `key'"
	sreturn local key "`key'"
end
