*Version 0.1 Brian Quistorff <bquistorff@gmail.com>
* Description: Similar to sample but for data in file (so big datasets). 
program define fsample
	version 11.0 //Just a guess at the version
	
	args f gsize ssize
	qui describe using "`f'", short
	local fsize r(N)
	local ncompletegroups `=floor(`fsize'/`gsize')'
	tempfile acc_sample
	clear
	save `acc_sample', emptyok
	forvalues groupnum = 1/`ncompletegroups' {
		local startobs `=(`groupnum'-1)*`gsize'+1'
		local endobs `=`startobs'+`gsize'-1'
		use in `startobs'/`endobs' using "`f'", clear
		qui sample `ssize', count
		append using `acc_sample', nolabel
		qui save `acc_sample', replace
	}
	local final_ssize `=round(`ssize'/`gsize'*mod(`fsize',`gsize'))'
	if `final_ssize'>0 {
		local startobs `=`ncompletegroups'*`gsize'+1'
		local endobs `fsize'
		use in `startobs'/`endobs' using "`f'", clear
		qui sample `final_ssize', count
		append using `acc_sample', nolabel
		*save `acc_sample', replace
	}
end
