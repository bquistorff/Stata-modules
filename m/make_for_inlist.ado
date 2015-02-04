*! version 0.1
*! Will put commas in between words in a list (so can be used in foreach loop)
program make_for_inlist, sclass
	version 11.0
	*Just a guess at the version
	
	syntax anything(everything)
	local nwords : word count `anything'
	
	local ret `""`: word 1 of `anything''""'
	if `nwords'>1 {
		forval i=2/`nwords' {
			local ret `"`ret',"`:word `i' of `anything''""'
		}
	}
	
	sreturn local for_inlist `"`ret'"'
end
