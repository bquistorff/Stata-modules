*! version 1.0
*! helpful if you want to put variable names in matrix row/colnames
program abbrev_all, sclass
	syntax , str_list(string asis) [length(int 32)]

	forval i=1/`:word count `str_list''{
		local part = abbrev("`: word `i' of `str_list''",`length')
		if `i'==1{
			local abbreved `""`part'""'
		}
		else{
			local abbreved `"`abbreved' "`part'""'
		}

	}
	
	sreturn local abbreved `"`abbreved'"'
end
