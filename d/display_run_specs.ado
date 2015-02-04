*! version 1.0
*! For numerical replication need to list operating system, application version, and processor type
* Ref: http://www.stata.com/support/faqs/windows/results-in-different-versions/
* Note that log open/close timestamps don't happen for the batch-mode logs
* Environment variables should be noted as well. 
*  Some are consequential so list them in $envvars_show and the others in $envvars_hide
program display_run_specs
	version 11.0
	*Just a guess at the version
	
	
	local c_opts_str os osdtl machine_type byteorder flavor hostname pwd
	foreach c_opt of local c_opts_str {
		local skip = 23 - (length("`c_opt'")+3)
		di _skip(`skip') as text "c(`c_opt') = " as result `""`c(`c_opt')'""'
	}
	
	local c_opts_num stata_version processors /*SE MP*/
	foreach c_opt of local c_opts_num {
		local skip = 23 - (length("`c_opt'")+3)
		di  _skip(`skip') as text "c(`c_opt') = " as result "`c(`c_opt')'"
	}
	
	foreach vname in $envvars_show {
		di `"env `vname': `: environment `vname''"'
	}
	foreach vname in $envvars_hide {
		di `"LOGREMOVE env `vname': `: environment `vname''"'
	}
end
