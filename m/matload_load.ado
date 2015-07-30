*! Version 1.2
*! Originally from: version 1.1.9  02feb2005  by Marc-Andreas Muendler: muendler@ucsd.edu
program define matload_simple
	version 11.0 //just a guess here
	syntax anything [, Path(string) ROWname(string) OVERwrite]
	
	global err_mssg = ""
	local rc 0
	local matname= subinstr("`anything'",",","",1)
	local currN = _N
	local file = "`path'"
	confirm file "`file'"
	tempname chk
	capture local `chk' = colsof(`matname')
	if _rc==0 & "`overwrite'"=="" {
		disp as err "no; matrix " in yellow "`matname'" in red " would be lost"
		exit 4 
	}
	local saved 0
	if `currN'>0 {
		tempfile tmp
		quietly save `tmp'
		local saved 1
		drop _all
	}

	capture use "`file'", clear
	if "`rowname'"=="" {
		capture confirm variable _rowname
		if _rc~=0 {
			local rc = _rc
			global err_mssg = "_rowname not found"
		}
		qui count
		if `r(N)'==0 {
			local rc = _rc
			global err_mssg = "Data set empty or not Stata format"
		}
	}
	else {
		capture confirm variable `rowname'
		if _rc~=0 {
			local rc = _rc
			global err_mssg = "`rowname' not found"
		}
		else {
			rename `rowname' _rowname
		}
		qui count
		if `r(N)'==0 {
			local rc = _rc
			global err_mssg = "Data set empty or not Stata format"
		}
	}
	capture confirm new variable `matname'
	if _rc~=0 {
		local rc = _rc
		global err_mssg = "matrix `matname' contains variable `matname'"
	}
	if _rc==0 {
		capture {
			local j 1
			while `j' <= _N {
				local rownm`j'=_rowname[`j']
				local j = `j'+1
			}
			drop _rowname
		}
		
		if _rc~=0 & "${err_mssg}" == "" {
			local rc = _rc
			global err_mssg = "error (before mkmat was applied)"
		}
		capture mkmat _all, matrix(`matname')
		if _rc~=0 & "${err_mssg}" == "" {
			local rc = _rc
			global err_mssg = "error (as mkmat was applied)"
		}
		capture {
			local j 1
			while `j' <= _N {
				matname `matname' `rownm`j'', rows(`j') explicit
				local j = `j'+1
			}
			local cnam : colfullnames `matname'
			tokenize "`cnam'"
			local j 1
			while `j' <= colsof(`matname') {
				local `j'=subinword("``j''","__cons","_cons",1)
				local `j'=subinword("``j''","__b","_b",1)
				local `j'=subinword("``j''","__coef","_coef",1)
				matname `matname' ``j'' , columns(`j') explicit
				local j=`j'+1
			}
			drop _all
		}
	}
	if _rc~=0 & "${err_mssg}" == "" {
		local rc = _rc
		global err_mssg = "error (after mkmat was applied)"
	}
	if _rc==0 & `rc'==0 {
		disp in green "matrix " in yellow "`matname'" in green " loaded"
	}
	if `saved' {
		use `tmp', clear
		disp in green "data in memory restored"
	}
	if `rc'~=0 {
		disp as err "${err_mssg}"
		error `rc'
	}
	global err_mssg = ""
	exit `rc'
end
