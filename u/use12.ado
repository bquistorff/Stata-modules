*! version 0.0.4
* If you are in "testing" mode where $extra_f_suff (extra filename suffix)
*  is not "" then will silently add that to the basefilename 
*  (it will only add it to files that have previously been saved with save12).
program use12
	syntax anything [, clear]
	
	*normalize the filename
	if substr("`anything'", length("`anything'")-3,4)!=".dta"{
		local anything `anything'.dta
	}
	
	*Testing stuff. Track and silently edit
	if strpos("$saved_files", "`anything'"){
		local anything `=substr("`anything'",1,length("`anything'")-4)'${extra_f_suff}.dta
	}
	
	use "`anything'", `clear'
end
