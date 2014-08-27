*! Version 1.0
*! Replaces -profiler report- and create a dta as output (rather than a text file)
*! Requires: save_cmd_output.ado
program nice_profile_report
    version 12
	syntax , outfile(string)
	tempfile textoutput
	save_cmd_output, outfile("`textoutput'") command(profiler report)
	tempfile initdata
	qui save `initdata'
	qui {
	import delimited "`textoutput'", clear
	destring count, replace
	gen frac_time = time/time[_N]
	save12 "`outfile'", replace
	}
    use `initdata', clear
end
