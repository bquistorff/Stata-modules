*! version 0.1
*! Brian Quistorff
*! Usage:
*! change_line using table.tex, ln(10) insert("blah")
*! change_line using table.tex, ln(10) delete
*! change_line using table.tex, ln(10) replace("blah")
program change_line
	version 11 //a guess
	syntax using/, ln(int) [insert(string) delete replace(string)]
	
	tempfile newfile
	tempname fh fh_new
	file open `fh' using `"`using'"', read text
	file open `fh_new' using `newfile', write text replace
	
	file read `fh' line
	local linenum = 0
	while r(eof)==0 {
		local linenum = `linenum' + 1
		
		if `ln'==`linenum'{
			if `"`insert'"'!=""{
				file write `fh_new' `"`insert'"' _newline
				file write `fh_new' `"`line'"' _newline
			}
			else{
				if "`replace'"!=""   file write `fh_new' `"`replace'"' _newline
			}
		}
		else{
			file write `fh_new' `"`line'"' _newline
		}
		
		file read `fh' line
	}
	file close `fh'
	file close `fh_new'
	
	copy `newfile' `using', replace

end
