*! v0.1 Brian Quistorff <bquistorff@gmail.com>
*! pass-through for -net from- that allows local relative path
program net_from
	args place
	is_abs_path "`place'"
	if r(is_abs_path) {
		local place `"`c(pwd)'/`place'"'
	}
	net from `place'
end
