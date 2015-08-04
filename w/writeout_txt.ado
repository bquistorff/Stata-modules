*! version 0.1 bquistorff@gmail.com
*! Writes out a string to a file
program writeout_txt
	version 11 //guess
	syntax anything(name=towrite equalok everything), filename(string)

	tempname fhandle
	file open `fhandle' using `"`filename'"', write text replace
	file write `fhandle' `"`towrite'"'
	file close `fhandle'
end
