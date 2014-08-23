*! Version 1.0
*! Creates a string list from a string variable (and if clause)
program list_from_var, sclass
	syntax varname [if]
	tempname tmatname
	mkmat `varlist' `if', matrix(`tmatname') rownames(`varlist')
	local rnames : rownames `tmatname'
	sreturn local olist `"`rnames'"'
end

