*! v0.1 Brian Quistorff <bquistorff@gmail.com>
*! pass-through for -net get- that allows local relative path
program net_get
	version 11.0 //just a guess here
	syntax namelist(name=pkgname max=1) [, all replace force from(string)]
	is_abs_path "`from'"
	if r(is_abs_path) {
		local from `"`c(pwd)'/`from'"'
	}
	net get `pkgname', `all' `replace' `force'	from(`from')
end
