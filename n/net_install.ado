*! v0.1 Brian Quistorff <bquistorff@gmail.com>
*! pass-through for -net install- that allows local relative path
program net_install
	version 11.0 //just a guess here
	syntax namelist(name=pkgname max=1) [, all replace force from(string)]
	
	is_abs_path "`from'", local(iap)
	if `iap' {
		local from `"`c(pwd)'/`from'"'
	}
	net install `pkgname', `all' `replace' `force'	from(`from')
end
