*! version 0.1 Brian Quistorff
*! in the anything part puts line1\\line2
*There are several ways
*1) Using packages
*1a) \usepackage{makecell}
*1b) \usepackage{pbox} (have to specifying a max width) (better than parbox)
*1c) minipage (have to specifying a width)
*1d) shortstack
* 2) Plain Latex
* 2a) insert a 1 column table
* 2b) You can make vbox of hboxes (but have to parse and insert separately the lines)
*
* Refs: 
*  http://tex.stackexchange.com/questions/2441/
*  http://tex.stackexchange.com/questions/38924/

program latex_multiline_cell
	syntax anything(equalok everything), loc_out(string)
	
	*local out `"\begin{tabular}[x]{@{}c@{}}`anything'\end{tabular}"' //t=vcentering (t,b,c); hcenter: l@ or r@
	*local out `"\pbox{20cm}{`anything'}"'
	local out `"\makecell{`anything'}"'
	c_local `loc_out' `"`out'"'
end
