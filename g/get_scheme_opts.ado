*! returns the available scheme options
program get_scheme_opts, sclass
	args num
	
	*Add more. (get from ado/base/s/scheme-*)
	local s2color_lcolor "navy maroon forest_green dkorange teal cranberry lavender khaki sienna emidblue emerald brown erose gold bluishgray"
	local s2color_mcolor "`s2color_lcolor'"
	local s2mono_msymbol "circle diamond square triangle x plus circle_hollow diamond_hollow square_hollow triangle_hollow smcircle smdiamond smsquare smtriangle smx"
	local s2mono_mcolor "gs6 gs10 gs8 gs4 black gs12 gs2 gs7 gs9 gs11 gs13 gs5 gs3 gs12 gs5"
	local s1mono_lpattern "solid dash vshortdash longdash_dot longdash dash_dot dot shortdash_dot tight_dot dash_dot_dot longdash_shortdash dash_3dot longdash_dot_dot shortdash_dot_dot longdash_3dot"
	local s1mono_msymbol "`s2mono_msymbol'"
	local s1mono_mcolor "`s2mono_mcolor'"
	
	foreach opt_type in lcolor lpattern msymbol mcolor{
		local sch_opt : word `num' of ``c(scheme)'_`opt_type''
		if "`sch_opt'" != ""{
			local opts = "`opts' `opt_type'(`sch_opt')"
		}
	}
	sreturn local opts "`opts'"
end
