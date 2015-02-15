*! reports if the string is a
program is_abs_path, rclass
	args place

	scalar is_abs_path = substr("`place'",1,5)!="http:" | substr("`place'",1,6)!="https:" | substr("`place'",1,1)!="/" | substr("`place'",2,1)!=":"
	return scalar is_abs_path = is_abs_path
end
