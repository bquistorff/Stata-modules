*! Version 1.0
*! Saves the output form a shell command
*TODO: Anyway to fix-up line wrapping?
program save_cmd_output
    version 12
	syntax, outfile(string) command(string)
	
	*First get the raw log output
	*Set linesize to max so little wrapping
	local orig_linesize = `c(linesize)'
	local orig_trace "`c(trace)'"
	set linesize 255 //max
	set trace off
	tempfile firstout
	*Can't quiet the below line
	log using "`firstout'", replace text name(profile)
	`command'
	log close profile
	set linesize `orig_linesize'
	set trace `orig_trace'
	
	*Now strip the bad top and bottom
	tempname infh outfh
	file open `infh' using "`firstout'", read text
	qui file open `outfh' using "`outfile'", write text replace
	*Skip first five lines
	forval i=1/5{
		file read `infh' line
	}
	file read `infh' line
	while r(eof)==0 {
		if `"`line'"'=="      name:  profile"{
			continue, break
		}
		file write `outfh' "`line'" _n
		file read `infh' line
	}

	file close `infh'

end
