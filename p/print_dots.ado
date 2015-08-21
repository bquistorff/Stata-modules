*! Version 1.1
*! Prints a simple progress bar and time estimates
*! If you don't want to keep track of curr (e.g. in a foreach loop)
*! Then just pass in one parameter being the end.
program print_dots
    version 12
	args curr end
	local timernum 13
	
	*See if passed in both
	if "`end'"==""{
		local end `curr'
		if "$PRINTDOTS_CURR"=="" global PRINTDOTS_CURR 0
		global PRINTDOTS_CURR = $PRINTDOTS_CURR+1
		local curr $PRINTDOTS_CURR
	}
	
	if `curr'==1 {
		timer off `timernum'
		timer clear `timernum'
		timer on `timernum'
		exit 0
	}
	local start_point = min(5, `end')
	if `curr'<`start_point' {
		timer off `timernum'
		qui timer list  `timernum'
		local used `r(t`timernum')'
		timer on `timernum'
		if `used'>60 {
			local remaining = `used'*(`end'/`curr'-1)
			local remaining_toprint = round(`remaining')
			local used_toprint = round(`used')
			display "After `=`curr'-1': " `used_toprint' "s elapsed, " `remaining_toprint' "s est. remaining"
		}
		exit 0
	}
	if `curr'==`start_point' {
		timer off `timernum'
		qui timer list  `timernum'
		local used `r(t`timernum')'
		timer on `timernum'
		local remaining = `used'*(`end'/`curr'-1)
		local remaining_toprint = round(`remaining')
		local used_toprint = round(`used')
		display "After `=`curr'-1': " `used_toprint' "s elapsed, " `remaining_toprint' "s est. remaining"
		
		if `end'<50{
			di "|" _column(`end') "|" _continue
		}
		else{
			di "----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5" _continue
		}
		di " Total: `end'"
		forval i=1/`start_point'{
			di "." _continue
		}
		exit 0
	}
	
	if (mod(`curr', 50)==0 | `curr'==`end'){
		timer off `timernum'
		qui timer list  `timernum'
		local used `r(t`timernum')'
		local used_toprint = round(`used')
		if `end'>`curr'{
			timer on `timernum'
			local remaining = `used'*(`end'/`curr'-1)
			local remaining_toprint = round(`remaining')
			display ". " `used_toprint' "s elapsed. " `remaining_toprint' "s remaining"
		}
		else{
			di "| " `used_toprint' "s elapsed. "
		}
	}
	else{
		di "." _continue
	}
end
