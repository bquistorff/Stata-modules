*! version 0.1  28jun2013
* Description: Generates strings corresponding to 
*   ISO 8601 data and date-time formats. These may
*   be useful for generating log-file filenames.
* Returns:
*   s(iso8601_d)      : 2000-12-25
*   s(iso8601_dt)     : 2000-12-25T13:01:01
*   s(iso8601_dt_file): 2000-12-25T13-01-01
*   s(unix_ts)        : 977749261 (second since 1970 epoch)
*
* Author: Brian Quistorff (bquistorff@gmail.com)

program define iso8601_strs, sclass
    version 12

	local curr_date = "`c(current_date)'"
	local curr_time = "`c(current_time)'"
	
	local unix_ts : display %12.0g clock("`curr_date' `curr_time'", "DMY hms" )/1000 - clock("1 Jan 1970", "DMY" )/1000
	local date : display %tdCCYY-NN-DD date("`curr_date'", "DMY" )
	local curr_t_str = subinstr("`curr_time'",":","-",.)
	
	sreturn local iso8601_d "`date'"
	sreturn local iso8601_dt = "`date'T`curr_time'"
	sreturn local iso8601_dt_file = "`date'T`curr_t_str'"
	sreturn local unix_ts = trim("`unix_ts'")
end
