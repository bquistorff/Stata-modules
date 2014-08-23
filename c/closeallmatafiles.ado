*! Version 1.0
*! Closes all files that were open in mata
*! -clear all- doesn't close mata open files!
* From http://www.stata.com/statalist/archive/2006-10/msg00794.html
program closeallmatafiles
		version 9

		forvalues i=0(1)50 {
				capture mata: fclose(`i')
		}
end
