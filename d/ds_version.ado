*! v0.1 Brian Quistorff <bquistorff@gmail.com>
*! Shows the version of the Stata dataset whose filename is passed in.
program ds_version, rclass
	args fname
	file open fhandle using `fname', read binary
	file read  fhandle %1s firstbytechar
	file close fhandle
	if "`firstbytechar'"=="<"{
		*In the future there will be more versions, so have to read ahead
		scalar v=117
	}
	else {
		mata: st_numscalar("v", ascii("`firstbytechar'"))
	}
	di "Version " v
	return scalar version = v
end
