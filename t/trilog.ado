*! version 1.0 Brian Quistorff <bquistorff@gmail.com>
*! Makes compressed scales (like log scales) when both positive and negative numbers exist.
*!  It makes a linear patch in the middle.
*! Usage:
*!  trilog , source(orig_var) generate(new_var)
*!  trilog , labels(-100 -10 -1 0 1 10 100)
*!  local new_labels `"`r(retlabel)'"'
*!  twoway (line new_var x), ylabels(`new_labels')
program trilog, rclass
	version 11.0
	*Just a guess at the version
	
	syntax , [source(string) generate(string) labels(string)]
	if "`source'"!=""{
		generate `generate' = `source'/exp(1)
		qui replace `generate' =  ln(   `source') if `source'>   exp(1)
		qui replace `generate' = -ln(-1*`source') if `source'<-1*exp(1)
	}

	if "`labels'"!=""{
		foreach label in `labels'{
			local translabel = `label'/exp(1)
			if `label'>   exp(1) local translabel =  ln(   `label')
			if `label'<-1*exp(1) local translabel = -ln(-1*`label')
			local retlabel `"`retlabel' `translabel' "`label'""'
		}
		return local retlabel `"`retlabel'"'
	}
end
