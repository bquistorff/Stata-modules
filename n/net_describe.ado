*! pass-through for -net describe- that allows local relative path
program net_describe
	syntax namelist(name=pkgname max=1) [, from(string)]
	is_abs_path "`from'"
	if r(is_abs_path) {
		local from `"`c(pwd)'/`from'"'
	}
	net describe `pkgname', from(`from')
end
