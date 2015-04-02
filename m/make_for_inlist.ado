*! version 0.1
*! Will put commas in between words in a list (so can be used in foreach loop)
*! This uses a word=based matching which works if the words are quoted string
*!  (where a simple " "->"," won't work)
program make_for_inlist
	version 11.0
	*Just a guess at the version
	
	syntax anything(everything), local(string)
	local nwords : word count `anything'
	
	local ret `""`: word 1 of `anything''""'
	if `nwords'>1 {
		forval i=2/`nwords' {
			local ret `"`ret',"`:word `i' of `anything''""'
		}
	}
	
	c_local local `"`ret'"'
end
