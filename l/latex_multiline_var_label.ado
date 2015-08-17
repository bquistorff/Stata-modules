program latex_multiline_var_label
	version 10.0 //guess
	syntax varname,  lines(string asis)
	
	local n_lines : word count `lines'
	forval i=1/`n_lines'{
		local line : word `i' of `lines'
		if `i'>1 local inside `"`inside'\\  \enskip{}"'
		local inside `"`inside'`line'"'
	}
	latex_multiline_cell `inside', loc_out(inside_broken)
	label variable `varlist' `"\multirow{`n_lines'}{*}{`inside_broken'}"'
end
