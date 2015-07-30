*! Outputs a tex p-value table
program output_pval_table
	version 11.0 //just a guess here
	syntax , note(string) file_base(string) matrix(string)
	
	local orig_linesize = "`c(linesize)'"
	set linesize 160
	frmttable using "${dir_base}/tab/tex/`file_base'_temp.tex", ///
		replace statmat(`matrix') tex fragment note("`note'")
	set linesize `orig_linesize'
	
	qui filefilter "${dir_base}/tab/tex/`file_base'_temp.tex" ///
		           "${dir_base}/tab/tex/`file_base'_temp2.tex" , ///
					from("& 0.00") to("& \BStextless{}0.01") replace
				   
	local finalfile "${dir_base}/tab/tex/`file_base'.tex"
	qui filefilter "${dir_base}/tab/tex/`file_base'_temp2.tex" ///
		           "`finalfile'" , ///
					from("smallskip} ") to("smallskip}Null distribution ") replace
	qui erase "${dir_base}/tab/tex/`file_base'_temp.tex"
	qui erase "${dir_base}/tab/tex/`file_base'_temp2.tex"
	
end
