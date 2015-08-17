* Builds an mlib from mata files
* Call this with a single argument that is a list (wrap all in double quotes). 
* The first element is mlib the rest are the mata files.
* (Has to be one list otherwise when calling -$STATABATCH do cli_build_mlib.do l/lp.mlib a/a.mata-
* the logfile will be a.log rather than cli_build_mlib.log on Windows (because of the "/"))
local mlib : word 1 of `1'
local mata_files : list 1 - mlib

_getfilename `mlib'
local mlib_name `r(filename)'
local mlib_path = substr("`mlib'",1,length("`mlib'")-length("`mlib_name'"))
local mlib_base = subinstr("`mlib_name'", ".mlib","",.)
mata: mata clear
foreach mata_file in `mata_files'{
	do "`mata_file'"
}
mac dir
mata: mata mlib create `mlib_base', replace dir("`mlib_path'")
mata: mata mlib add `mlib_base' *()
