*! version 1.0
*! Creates axis ticks (major & minor) for log scales
*! (Stata's auto ticks are bad)
program log_axis_ticks, sclass
	version 11.0
	*Just a guess at the version
	
	syntax , [range(numlist) vars(varlist numeric) label_scale(string)]
	
	* Get the range
	if "`range'"!=""{
		local min : word 1 of `range'
		local max : word 2 of `range'
	}
	else {
		local min = .
		local max = .
		foreach v in `vars'{
			summ `v', meanonly
			if `min'==. | `r(min)'<`min'{
				local min = `r(min)'
			}
			if `max'==. | `r(max)'>`max'{
				local max = `r(max)'
			}
		}
	}

	local logdiff = log10(`max'/`min')
	
	if `logdiff'<1{
		* If small just put down 4 markers at equal proportions. 
		* Not sure what to do better here but probably something
		local maj_factor = (`max'/`min')^(1/3)
		local major_lst "`min' `=`min'*`maj_factor'' `=`min'*`maj_factor'^2' `max'"
		
		local num_min_small 12
		local min_factor = (`max'/`min')^(1/`num_min_small')
		
		local min_next = `min'
		forval i=1/`num_min_small'{
			local minor_lst "`minor_lst' `min_next'"
			local min_next = `min_next'*`min_factor'
		}
	}
	else {
		local min_mag_not_bigger = 10^floor(log10(`min'))
		local min_mag_not_smaller = 10^ceil(log10(`min'))
		local fdigit = substr("`min'",1,1)
		
		* If intermediate do the 2,5,10 scale
		if `logdiff'<2 {
			local multi_lst = "2 2.5 2"
			if (`fdigit'==5 & `min'>5*`min_mag_not_bigger') | `fdigit'>5 | `min'==`min_mag_not_smaller' {
				local major_lst = `min_mag_not_smaller'
				local multi_ind = 1
			}
			else {
				if (`fdigit'==2 & `min'>2*`min_mag_not_bigger') | `fdigit'>2 {
					local major_lst = 5* `min_mag_not_bigger'
					local multi_ind = 3
				}
				else {
					local major_lst = 2*`min_mag_not_bigger'
					local multi_ind = 2
				}
			}
			local last = `major_lst'
			while 1{
				local next = `last'*`: word `multi_ind' of `multi_lst''
				if `next'>`max'{
					continue, break
				}
				local major_lst "`major_lst' `next'"
				local last = `next'
				local multi_ind = mod(`multi_ind',3)+1
			}
			
			
		}
		*If really big just go up by equal orders of magnitude
		else {
			if `logdiff'<5 {
				local step = 1
			}
			else {
				local step = floor(`logdiff'/3)
			}
			local major_lst = `min_mag_not_smaller'
			local last = `major_lst'
			while 1{
				local next = `last'*(10^`step')
				if `next'>`max'{
					continue, break
				}
				local major_lst "`major_lst' `next'"
				local last = `next'
			}
			
			if `step'>1{
                local min_next = `min_mag_not_bigger'
                while 1{
                    local minor_lst "`minor_lst' `min_next'"
                    local min_next = 10*`min_next'
                    if `min_next'>= `max'{
                        continue, break
                    }
                }
			}
		}
		
		if "`minor_lst'"==""{
			local minor_lst = `fdigit'*`min_mag_not_bigger'
			local increment = `min_mag_not_bigger'
			local mlast = `minor_lst' 
			while 1{
				local mnext = `mlast' + `increment'
				local minor_lst "`minor_lst' `mnext'"
				if `mnext'>=`max'{
					continue, break
				}
				local mlast = `mnext'
				
				if `mlast' == 10^ceil(log10(`mlast')){
					local increment = 10*`increment'
				}
			}
		}
	}
	
	if "`label_scale'"!="" {
		local major_lst_orig `"`major_lst'"'
		local major_lst ""
		foreach mtick in `major_lst_orig'{
			local major_lst `"`major_lst' `mtick' "`=`mtick'/`label_scale''""'
		}
		sreturn local major_lst_orig = "`major_lst_orig'"
	}
	
	sreturn local major_ticks = `"`major_lst'"'
	sreturn local minor_ticks = "`minor_lst'"
end
