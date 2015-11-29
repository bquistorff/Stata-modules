*! version 0.0.8 Brian Quistorff <bquistorff@gmail.com>
*! Can try to save in either dataset version 114 or 115 which
*! is readable by Stata v11-13
* version map: Stata (dataset): v11 (114) v12(115) v13 (117) v14 (118).
* Stata can always read earlier dataset formats. Additionally, v11
* can read v115 datasets as the 114 and 115 are almost the same (just business dates).
program save12
	syntax anything [, replace datasig compress]
	
	if "`compress'"!="" compress
	
	if "`datasig'"!="" {
		datasig set, reset
		*remove dates so dta file is the same across runs (normalized)
		* but this does break -datasig report- though not -datasig confirm-
		char _dta[datasignature_dt]
	}
	
	cap unab temp: _*
	if `:list sizeof temp'>0 di "Warning: Saving with temporary (_*) vars"
	
	if `c(stata_version)'>=13{
		if `c(stata_version)'>=15 di "save12 untested for Stata v>=15"
		if `c(stata_version)'>=14 local v_opt "version(12)"
		saveold `anything', `replace' `v_opt'
	}
	else {
		if `c(stata_version)'<11 di "save12 untested for Stata v<11"
		save `anything', `replace'
	}
end

