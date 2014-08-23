*! Version 1.0
*! Prints a simple progress bar and time estimates
program print_dots
	args curr end
	local timernum 13
	
	if `curr'==1 {
		timer off `timernum'
		timer clear `timernum'
		timer on `timernum'
		exit 0
	}
	if `curr'<5 {
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
	if `curr'==5 {
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
		di "....." _continue
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
