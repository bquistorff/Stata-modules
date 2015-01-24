program make_for_inlist, sclass
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
