*Adds a fake variable. Useful for adding new rows to a table using esttab/estout
*Needs erepost
program add_fake_coeff_to_e, eclass
	args cname cval
	
	tempname eb eb2 eV eV2
	mat `eb' = e(b)
	local eb_names : colnames `eb'
	mat `eb2' = `eb', `cval'
	matrix colnames `eb2' = `eb_names' `cname'
	
	*Need the dimensions of V to match b
	mat `eV' = e(V)
	local num_eb : word count `eb_names'
	
	mat `eV2' = I(`=`num_eb'+1')
	mat `eV2'[1,1] = `eV'
	matrix colnames `eV2' = `eb_names' `cname'
	matrix rownames `eV2' = `eb_names' `cname'
	
	erepost b=`eb2' V=`eV2'
end
