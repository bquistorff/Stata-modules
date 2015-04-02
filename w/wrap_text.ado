*! version 1.1
*! Auto wraps a long line to broken up ones (that graph commands turn into different lines)
*! Wrapped has the "" quotes
*! Usage: 
*! wrap_text , unwrappedtext(`longtext') wrapped_out_loc(wrapped)
*! twoway ..., note(`wrapped')
* With simple testing 100 chars is about the width of a note in twoway at "normal sizes".
program wrap_text
	version 12
	syntax , unwrappedtext(string) wrapped_out_loc(string)  [width(integer 100)]
    
	local num_words : word count `unwrappedtext'
	forval i = 1/`num_words' {
		local line : piece `i' `width' of "`unwrappedtext'"
		if "`line'"==""{
			continue, break
		}
		local wrappedtext `"`wrappedtext' "`line'""'
	}
  
	c_local `wrapped_out_loc' `"`wrappedtext'"'
end
