*! version 1.0
*! Auto wraps a long line to broken up ones (that graph commands turn into different lines)
*! Usage: 
*! wrap_text , unwrappedtext("`longtext'")
*! local wrapped `"`s(wrappedtext)'"'
*! Wrapped has the "" quotes
*! twoway ..., note(`s(wrappedtext)')/note(`wrapped')
* With simple testing 100 chars is about the width of a note in twoway at "normal sizes".
program wrap_text, sclass
    version 12
	syntax , unwrappedtext(string)  [width(integer 100)]
    
	local num_words : word count `unwrappedtext'
	forval i = 1/`num_words' {
		local line : piece `i' `width' of "`unwrappedtext'"
		if "`line'"==""{
			continue, break
		}
		local wrappedtext `"`wrappedtext' "`line'""'
	}
    
	sreturn local wrappedtext `"`wrappedtext'"'
end
