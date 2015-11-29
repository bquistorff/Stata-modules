*! version 0.3 bquistorff@gmail.com
*! Writes out a string to a file
*! LaTeX automatically adds an extra space after \input (cf http://tex.stackexchange.com/questions/18017/)
*! Use rm_final_space_tex if you don't want this 
*! (e.g. you're inserting numbers and a symbol should immediately follow)
program writeout_txt
	version 11 //guess
	syntax anything(name=towrite equalok everything), filename(string) [rm_final_space_tex format(string)]

	if "`rm_final_space_tex'"!="" local pct_char = "%"
	if "`format'"!="" local towrite =string(`towrite', "`format'")
	tempname fhandle
	file open `fhandle' using `"`filename'"', write text replace
	file write `fhandle' `"`towrite'`pct_char'"'
	file close `fhandle'
end
