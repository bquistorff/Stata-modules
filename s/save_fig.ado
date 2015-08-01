*! v1.0 bquistorff@gmail.com
*! saving text versions of title & notes (including wrapping for gph output) as well as the gph_file.
program save_fig
	version 12.0 //just a guess
	*Strip off and deal with my suboptions
	gettoken 0 remainder : 0, parse(":")
	syntax , title_file(string) caption_file(string) gph_file(string) [width(string)]
	gettoken colon 0 : remainder, parse(":")

	/* If had to load from already written file (but then can' unwrap caption well)
	graph use "`gph_file'", name(`toexport')
	qui graph describe
	local 0 `"`r(command)'"'
	*/
	syntax anything(equalok everything name=gph_cmd) [, title(string) note(string asis) *]

	if "`title_file'"!="" & length(`"`title'"')>0{
		file open fhandle using "`title_file'", write text replace
		file write fhandle "`title'"
		file close fhandle
	}
	
	if "`caption_file'"!="" & length(`"`note'"')>0{
		file open fhandle using "`caption_file'", write text replace
		if substr(`"`note'"',1,1)==""{
			forval i=1/`: word count `note''{
				file write fhandle `"`: word `i' of `note''"'
			}
		}
		else{
			file write fhandle `"`note'"'
		}
		file close fhandle
	}
	
	if "`width'"!=""{
		cap which wrap_text
		if _rc==0 wrap_text , unwrappedtext(`note') wrapped_out_loc(note) width(`width')
	}
	
	`gph_cmd', `options' title("`title'") note(`note') saving("`gph_file'", replace)
end
