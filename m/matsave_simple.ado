*! Originally from: version 1.1.7  24oct2004  by Marc-Andreas Muendler: muendler@ucsd.edu
*! BQ: Make saving automatic (no dropall), remove manual -more-s,
*!   put the full filename in path (not just dir) so can save to a name that is not the matrix name
*! Requires save12
program define matsave_simple
	version 7
	args matname
	syntax newvarname [, REPLACE Path(string) Type(string)]
	
	local matname= subinstr("`matname'",",","",1)
	if lower("`type'")~="" & lower("`type'")~="byte" & lower("`type'")~="int" & lower("`type'")~="long" & lower("`type'")~="float" & lower("`type'")~="double" {
		local type = "float"
	}
	tempname tst
	local tst = colsof(`matname')
	local currN = _N
	
	local file = "`path'"
	local saved 0
	if `currN'>0 {
		local dropall = ""
		tempfile tmp
		quietly save `tmp'
		local saved 1
		drop _all
	}
	
	local chgflg =0
	local cnam : colfullnames `matname'
	tokenize "`cnam'"
	local i 1
	while `i' <= colsof(`matname') {
		local `i' = subinstr("``i''",":","_",.)
		if "``i''" == "_cons" | "``i''" == "_b" | "``i''" == "_coef" {
			local chgflg 1
			local `i' = "_" + "``i''"
		}
		matname `matname' :``i'', columns(`i') explicit
		local i = `i' + 1   
	}  
	local dosv=1
	
	qui svmat `type' `matname', names(col)
	
	local i 1
	if `chgflg' {
		while `i' <= colsof(`matname') {
			matname `matname' ``i'', columns(`i') explicit
			local i = `i' +1   
		}  
	}  
	local rnam : rowfullnames `matname'
	tokenize "`rnam'"
	local maxlen= 0
	local j 1
	while `j' <= rowsof(`matname') {
		if length("``j''") > `maxlen' {local maxlen = length("``j''")}
		local j=`j'+1
	}
	if `maxlen' >80 {local maxlen = 80}
	quietly gen str`maxlen' _rowname=""
	local j 1
	while `j' <= rowsof(`matname') {
		quietly replace _rowname = "``j''" in `j'
		local j=`j'+1
	}
	order _rowname

	qui save12 "`file'", `replace'
	
	if `saved' {
		use `tmp', clear
	}
end
