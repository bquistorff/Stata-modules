log using "net_test.log", replace

local dirs :dir .. dirs ?
foreach dir in `dirs'{
	local pkgs : dir "../`dir'/" files "*.pkg"
	foreach pkg in `pkgs'{
		local pkg_name = substr("`pkg'",1, length("`pkg'")-4)
		net describe `pkg_name', from (https://raw.github.com/bquistorff/Stata-modules/master/`dir'/)
	}
}

log close
