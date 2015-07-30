*! v0.1 Brian Quistorff <bquistorff@gmail.com>
*! reports if the string is a
program is_abs_path, rclass
	version 11.0 //just a guess here
	args place

	scalar is_abs_path = substr("`place'",1,5)!="http:" | substr("`place'",1,6)!="https:" | substr("`place'",1,1)!="/" | substr("`place'",2,1)!=":"
	return scalar is_abs_path = is_abs_path
end
