l/lperm_inference.mlib : p/perm_inference.mata
	$$STATABATCH do cli_build_mlib.do "$@ $^"; tail cli_build_mlib.log; rm cli_build_mlib.log
