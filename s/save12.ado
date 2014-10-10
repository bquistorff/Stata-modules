*! version 0.0.3
*! In environments where stata12 and 13 are possible, always save in v12 format
* Note: Won't work possibly for stata versions <12 or >13
program save12
	syntax anything [, replace preserve_convert_restore]
	
	if "`preserve_convert_restore'"==""{
		if `c(stata_version)'>=13 {
			saveold `anything', `replace'
		}
		else {
			save `anything', `replace'
		}
	}
	else{
		if `c(stata_version)'>=13 {
			preserve
			use `anything', clear
			saveold `anything', `replace'
			restore
		}
	}
end
