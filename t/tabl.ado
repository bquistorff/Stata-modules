*! version 1.1.0  05oct1999  Jeroen Weesie/ICS  (STB-53: dm75) (modfied)
*http://www.stata.com/statalist/archive/2007-03/msg00584.html
program define tabl
	version 6.0

	syntax varlist [if ] [in] [, Width(int 40)]

	tokenize `varlist'
	while "`1'" != "" {
		Tabl `1' `if' `in', width(`width')
		mac shift
	}
end


/* Tabl varname [if] [in], width(#)
  displays a one-var tabulate with varlabel and value labels,
  wrapping if their length exceeds width
*/
program define Tabl
	syntax varname [if] [in], Width(int)

	marksample touse, novarlist

	local lab : value label `varlist'
	if "`lab'" == "" {
		* no value labels
		tab `varlist' if `touse', miss
		exit
	}

	tempname freq code

	qui tab `varlist' if `touse', matcell(`freq') matrow(`code')
	if r(N) == 0 {
		exit
	}
	local N = r(N)

	local vlab : var label `varlist'
	if `"`vlab'"' == "" {
		local vlab `varlist'
	}
	else local vlab `varlist' (`vlab')

	* determine max length of varlabel and value labels
	local len = length(`"`vlab'"')
	local i 1
	while `i' <= rowsof(`freq') {
		local ci = `code'[`i',1]
		local li : label (`varlist') `ci'
		local len = max(`len', length(`"`li'"'))
		local i = `i'+1
	}
	if `len' > `width' {
		local len = `width'
	}
	local col1 = `len' + 3

	di
	local vlab1 : piece 1 `len' of `"`vlab'"'
	local vlab2 : piece 2 `len' of `"`vlab'"'
	local i 2
	while `"`vlab2'"' ~= "" {
		di in gr `"`vlab1'"'
		local vlab1 `vlab2'
		local i = `i'+1
		local vlab2 : piece `i' `len' of `"`vlab'"'
	}

	di in gr "`vlab1'" _col(`col1') "   code  |   freq "
	di in gr _dup(`col1') "-"        "--------+--------"

	local i 1
	while `i' <= rowsof(`freq') {
		local ci = `code'[`i',1]
		local li : label (`varlist') `ci'
		local pli : piece 1 `len' of `"`li'"'

		di in gr %`len's `"`pli'"' _col(`col1') %6.0f `ci' /*
			*/ "   |" in ye %7.0f `freq'[`i',1]

		* display the rest of the value label
		local j 2
		local pli : piece `j' `len' of `"`li'"'
		while `"`pli'"' != "" {
			di in gr %`len's `"  `pli'"' _col(`col1') "         |"
			local j = `j'+1
			local pli : piece `j' `len' of `"`li'"'
		}

		local i = `i'+1
	}

	qui count if (`varlist'==.) & (`touse'==1)
	if r(N) > 0 {
		di in gr _dup(`col1') "-" "--------+--------"
		di in gr %`len's "<missing value>" _col(`col1') "     .   |"  /*
			*/ in ye %7.0f r(N)
	}

	di in gr _dup(`col1') "-" "--------+--------"
	di in gr _col(`col1') " Total   |" in ye %7.0f = `N'+r(N)
end
