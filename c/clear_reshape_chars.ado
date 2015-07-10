*! version 1.0 Brian Quistorff
* Reshape leaves a bunch of cars around so that it can be undone.
*  in interactive mode this is nice, but otherwise they are messy.
program clear_reshape_chars
	char _dta[ReS_str]
	char _dta[ReS_j]
	char _dta[ReS_ver]
	char _dta[ReS_i]
	char _dta[ReS_Xij]
	
	local poss_chars : char _dta[]
	foreach poss_char of local poss_chars{
		if regexm("`poss_char'","__Xij") char _dta[`poss_char']
	}
end
