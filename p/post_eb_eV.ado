*! Post your own matrices to e(b) and e(V)
prog define post_eb_eV, eclass
	version 8.0
	args beta vari
	eret post `beta' `vari'
	eret loc cmd="post_eb_eV"
end
