*! Outputs matrix (in dta and tex) of unit level matches
*! Requires globals: dir_base
program output_unit_matches
	syntax , numb(int) file_suff(string) weights_unr(string) weights(string) [match_file(string)]
	tempfile initdata
	qui save `initdata'
	
	qui drop _all
	qui svmat `weights_unr', names(W)
	rename (W*) (codigo weight)
	gsort -weight
	qui save12 "${dir_base}/data/estimates/weights/weights_`file_suff'.dta", replace
	
	qui drop _all
	qui svmat `weights', names(W)
	rename (W*) (codigo weight)
	gsort -weight
	qui keep in 1/`=min(`numb',_N)'
	qui keep if weight >= 0.01
	rename codigo set
	if "`match_file'"!=""{
		qui merge 1:1 set using "`match_file'", keep(match) nogenerate
	}
	gsort -weight
	
	di "Top matches (`file_suff') :"
	list
	
	drop set
	
	tempname top_matches
	qui ds *
	local allvars "`r(varlist)'"
	local notcolvar "Name"
	local colvars : list allvars - notcolvar
	if "`colvars'"=="`allvars'"{
		mkmat `colvars', mat(`top_matches')
	}
	else {
		mkmat `colvars', mat(`top_matches') rownames(Name)
	}
	qui frmttable using "${dir_base}/tab/tex/top_matches_`file_suff'_temp1.tex", replace ///
				statmat(`top_matches') tex fragment nodisplay coljust(lcr)
	
	qui filefilter "${dir_base}/tab/tex/top_matches_`file_suff'_temp1.tex" ///
		"${dir_base}/tab/tex/top_matches_`file_suff'_temp2.tex" , from(_) to(" ") replace
	qui filefilter "${dir_base}/tab/tex/top_matches_`file_suff'_temp2.tex" ///
		"${dir_base}/tab/tex/top_matches_`file_suff'.tex" , from(".00\BS\BS") to("\BS\BS") replace
		
	qui erase "${dir_base}/tab/tex/top_matches_`file_suff'_temp1.tex"
	qui erase "${dir_base}/tab/tex/top_matches_`file_suff'_temp2.tex"
	
	if "${track_files}"=="1" {
		writeout_tracked_file  "${dir_base}/tab/tex/top_matches_`file_suff'.tex"
	}
	
	use `initdata', clear
end
