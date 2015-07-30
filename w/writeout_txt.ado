*! version 0.1 bquistorff@gmail.com
*! Writes out a string to a file
program writeout_txt
	version 11 //guess
	syntax anything(name=towrite equalok everything), filename(string)
	local filepath `"`filename'"'
	file open fhandle using `"`filepath'"', write text replace
	file write fhandle `"`towrite'"'
	file close fhandle
end
