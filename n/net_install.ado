*! v0.1 Brian Quistorff <bquistorff@gmail.com>
*! pass-through for -net install- that allows local relative path
program net_install
	syntax namelist(name=pkgname max=1) [, all replace force from(string)]
	is_abs_path "`from'"
	scalar iap = r(is_abs_path)
	if iap {
		local from `"`c(pwd)'/`from'"'
	}
	net install `pkgname', `all' `replace' `force'	from(`from')
end
