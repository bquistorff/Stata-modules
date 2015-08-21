*! version 1.0 Brian Quistorff bquistorff@gmail.com
*! Makes a multiline label for a variable to be used in a tex table.
*! Usage: latex_multiline_var_label , lines("line 1" "line 2")
program latex_multiline_var_label
	version 10.0 //guess
	syntax ,  lines(string asis) [local(string) var2label(string) noindent nomultirow n_rows(string)]
	
	if "`indent'"!="noindent" loc indent_str " \enskip{}"
	
	local n_lines : word count `lines'
	forval i=1/`n_lines'{
		local line : word `i' of `lines'
		if `i'>1 local inside `"`inside'\\ `indent_str'"'
		local inside `"`inside'`line'"'
	}
	latex_multiline_cell `inside', loc_out(inside_broken)
	if "`n_rows'"==" loc n_rows `n_lines'
	local full `"\multirow{`n_lines'}{*}{`inside_broken'}"'
	
	if "`var2label'"!="" label variable `var2label' `"`full'"'
	if "`local'"    !="" c_local `local' `"`full'"'
end
