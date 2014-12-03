*! version 1.0
*! For numerical replication need to list operating system, application version, and processor type
* Ref: http://www.stata.com/support/faqs/windows/results-in-different-versions/
* Note that log open/close timestamps don't happen for the batch-mode logs
*Make it look like -creturn list-. 
* To do: try to get the first part right-justified
program display_install_specs
	
	local c_opts_str os osdtl machine_type byteorder flavor hostname pwd
	foreach c_opt of local c_opts_str {
		di `" c(`c_opt') = "`c(`c_opt')'""'
	}
	
	local c_opts_num stata_version processors /*SE MP*/
	foreach c_opt of local c_opts_num {
		di  " c(`c_opt') = `c(`c_opt')'"
	}
end
