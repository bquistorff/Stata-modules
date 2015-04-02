*! version 1.1
*! helpful if you want to put variable names in matrix row/colnames
program abbrev_all
	syntax , str_list(string asis) out_loc(string) [length(int 32)]

	forval i=1/`:word count `str_list''{
		local part = abbrev("`: word `i' of `str_list''",`length')
		
		if `i'==1 local abbreved `""`part'""'
		if `i'> 1 local abbreved `"`abbreved' "`part'""'
	}
	
	c_local `out_loc' `"`abbreved'"'
end
