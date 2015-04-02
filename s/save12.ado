*! version 0.0.5
*! Can try to save in either dataset version 114 or 115 which
*! is readable by Stata v11-13 (use $try_stata12)
* version map: Stata (dataset): v11 (114) v12(115) v13 (117).
* Stata can always read earlier dataset formats. Additionally, v11
* can read v115 datasets.
* Note: Won't work possibly for stata versions <12 or >13
program save12
	syntax anything [, replace datasig]
	
	if "`datasig'"!="" datasig set, reset
	
	if `c(stata_version)'>=13 & "$try_stata12"=="1" {
		if `c(stata_version)'>=14 di "save12 untested for Stata v>=14"
		saveold `anything', `replace'
	}
	else {
		if `c(stata_version)'<11 & "$try_stata12"=="1" di "save12 untested for Stata v<11"
		save `anything', `replace'
	}
end

