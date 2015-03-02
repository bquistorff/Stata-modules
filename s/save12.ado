*! version 0.0.4
*! Will try to save in either dataset version 114 or 115 which
*! is readable by Stata v11-13
* version map: Stata (dataset): v11 (114) v12(115) v13 (117).
* Stata can always read earlier dataset formats. Additionally, v11
* can read v115 datasets.
* Note: Won't work possibly for stata versions <12 or >13
* If you are in "testing" mode where $extra_f_suff (extra filename suffix)
*  is not "" then save and load will silently add that to the basefilename 
*  (for use12 it will only add it to files that have previously been saved with save12).
program save12
	syntax anything [, replace]
	
	*normalize the filename
	if substr("`anything'", length("`anything'")-3,4)!=".dta"{
		local anything `anything'.dta
	}
	
	*Testing stuff. Track and silently edit
	global saved_files "$saved_files `anything'"
	local anything `=substr("`anything'",1,length("`anything'")-4)'${extra_f_suff}.dta

	if `c(stata_version)'>=13 {
		if `c(stata_version)'>=14 di "save12 untested for Stata v>=14"
		saveold "`anything'", `replace'
	}
	else {
		if `c(stata_version)'<11 di "save12 untested for Stata v<11"
		save "`anything'", `replace'
	}
end

