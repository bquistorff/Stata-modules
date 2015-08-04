*! version 1.2 Brian Quistorff <bquistorff@gmail.com>
*! Auto wraps a long line to broken up ones (that graph commands turn into different lines)
*! Wrapped has the "" quotes to separate lines
*! Usage: 
*! wrap_text , unwrappedtext(`longtext') wrapped_out_loc(wrapped)
*! twoway ..., note(`wrapped')
* With simple testing 100 chars is about the width of a note in twoway at "normal sizes".
program wrap_text
	version 12
	syntax , unwrappedtext(string asis) wrapped_out_loc(string)  [width(integer 100)]
  *di `"input: `unwrappedtext'"'
	
	*get rid of outer quotes of only one set
	local unwrappedtext = trim(`"`unwrappedtext'"')
	if substr(`"`unwrappedtext'"',1,1)!=`"""' local unwrappedtext `""`unwrappedtext'""'
  *di `"std: `unwrappedtext'"'
	*if first char is not ", then wrap
	foreach oline in `unwrappedtext'{
		*di `"line: `oline'"'
		local num_words : word count `oline'
		if `num_words'==0 local wrappedtext `"`wrappedtext'`space'"`oline'""' //pass whitespace through
		forval i = 1/`num_words' {
			local line : piece `i' `width' of "`oline'"
			if "`line'"==""{
				continue, break
			}
			local wrappedtext `"`wrappedtext'`space'"`line'""'
			local space " "
		}
	}
  
	*di `"output: `wrappedtext'"'
	c_local `wrapped_out_loc' `"`wrappedtext'"'
end
