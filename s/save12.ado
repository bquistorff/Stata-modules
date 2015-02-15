*! version 0.0.3
*! Will try to save in either dataset version 114 or 115 which
*! is readable by Stata v11-13
* version map: Stata (dataset): v11 (114) v12(115) v13 (117).
* Stata can always read earlier dataset formats. Additionally, v11
* can read v115 datasets.
* Note: Won't work possibly for stata versions <12 or >13
program save12
	syntax anything [, replace preserve_convert_restore]
	
	if ("`preserve_convert_restore'"!="" & `c(stata_version)'< 13) exit
	
	if ("`preserve_convert_restore'"!=""){
			preserve
			use `anything', clear
	}
	
	if `c(stata_version)'>=13 {
		if `c(stata_version)'>=14 di "save12 untested for Stata v>=14"
		saveold `anything', `replace'
	}
	else {
		if `c(stata_version)'<11 di "save12 untested for Stata v<11"
		save `anything', `replace'
	}
	
	if ("`preserve_convert_restore'"!="") restore
	
end
