program bappend
	syntax [anything(everything)] [, GENerate(name) * ]
	gettoken using orig_filenames : anything
	if (`"`using'"' != "using") {
		di as err "using required"
		exit 100
	
	}
	foreach filename of local orig_filenames {
		*normalize the filename
		if substr("`filename'", length("`filename'")-3,4)!=".dta"{
			local filename `filename'.dta
		}
		
		*See if should use testing version
		if strpos("$saved_dtas", "`filename'"){
			local filename `=substr("`filename'",1,length("`filename'")-4)'${extra_f_suff}.dta
		}
		local new_filenames `"`new_filenames' "`filename'${extra_f_suff}""'
	}
	append using `new_filenames', generate(`generate') `options'
end
