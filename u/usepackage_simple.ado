*!  usepackage_simple.ado -- Stata module to download and install user packages necessary to run a do-file
*!                                    include the net(loc) option if you want to install the package from non-SSC sources (the default)
*! A simplified version of usepackage.ado
*! Usage:
*! . uspackage parallel
*! . uspackage parallel, location(https://raw.githubusercontent.com/gvegayon/parallel/master/)

*This is not simple as the output from neither -ado dir- nor -ado describe- can be used programmatically
*Don't use which as sometimes functions don't match to packages
*Return code is like that of findfile (0 if found, 601 otherwise)
program define findpackage_simple
args pkg
version 9.2
	qui cap findfile `pkg'.ado
	if _rc qui cap findfile l`pkg'.mlib
	if _rc qui cap findfile `pkg'.hlp
	if _rc qui cap findfile `pkg'.sthlp
end

program define usepackage_simple
syntax anything [, location(string) ]
version 9.2
	foreach _f in `anything' {
		**check to see if exists:
		findpackage_simple `_f'
		if _rc==0  {
			continue
		}

		**doesnt exist, first try SSC:	
		if "`location'"=="" {
			qui cap ssc install `_f'
			if !_rc {
				di in yellow as smcl `"   Package {stata ado describe `_f': `_f'} installed from SSC"'
			}
			else{
				di in red as smcl `"   Package {stata ado describe `_f': `_f'} NOT installed from SSC"'
			}
		}
		else{
			qui cap net install `_f', from("`location'")
			if !_rc {
				di in yellow as smcl `"   Package {stata ado describe `_f': `_f'} installed from net"'
			}
			else{
				di in red as smcl `"   Package {stata ado describe `_f': `_f'} NOT installed from net"'
			}			
		}


	}
	*di in yellow `"Done"'
end

