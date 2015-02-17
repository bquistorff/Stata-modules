*! Version 1.1
*! Creates a string list from a string variable (and if clause)
*! if the main var is not a numeric var you need to pass one in.
*! if the main var is a str var it may get mangled (spaces -> underscores, and trimmed)
program list_from_var, sclass
    version 12
	syntax varname [if] [, numvar(string)]
	
	if "`numvar'"=="" local numvar="`varlist'"
	tempname tmatname
	mkmat `numvar' `if', matrix(`tmatname') rownames(`varlist')
	local rnames : rownames `tmatname'
	sreturn local olist `"`rnames'"'
end

