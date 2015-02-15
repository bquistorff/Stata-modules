*! pass-through for -net get- that allows local relative path
program net_get
	syntax namelist(name=pkgname max=1) [, all replace force from(string)]
	is_abs_path "`from'"
	if r(is_abs_path) {
		local from `"`c(pwd)'/`from'"'
	}
	net get `pkgname', `all' `replace' `force'	from(`from')
end
