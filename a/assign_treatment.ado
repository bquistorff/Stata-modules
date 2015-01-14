*! version 1.1 Brian Quistorff
*! Trying to do "reduction" with "full" looks like a much harder problem (and not much benefit).
program assign_treatment
	syntax varlist, generate(string) num_treatments(int) [handle_misfit(string) subcell_order_vars(string)]
	
	* First-pass randomization. Implicitly does "interval" for handle_misfit.
	tempvar cell_id cell_position subcell_id subcell_position rand misfit
	gen `rand' = runiform()
	egen `cell_id'    = group(`varlist')
	egen `subcell_id' = group(`subcell_order_vars')
	sort `cell_id', stable
	by `cell_id'             : gen `cell_position'    = `rand'[1]
	sort `cell_id' `subcell_id', stable
	by `cell_id' `subcell_id': gen `subcell_position' = `rand'[1]
	sort `cell_position' `subcell_position' `rand'
	by `cell_position': gen `misfit' = (_n > floor(_N/`num_treatments')*`num_treatments')
	gen `generate' = mod(_n-1, `num_treatments')+1 
	
	if "`handle_misfit'"=="full" | "`handle_misfit'"=="reduction"{
		tempfile nonmisfits
		preserve
		qui drop if `misfit'
		qui save `nonmisfits'
		restore
	}
	
	if "`handle_misfit'"=="reduction" & `: word count `varlist''>1{
		qui keep if `misfit'
		drop `generate'
		gettoken varlist_first varlist_rest : varlist
        *The subcell is essential!
		assign_treatment `varlist_rest', generate(`generate') num_treatments(`num_treatments') ///
			handle_misfit(`handle_misfit') subcell_order_vars(`subcell_order_vars' `varlist_first')
		append using `nonmisfits', nolabel nonotes
	}
	
	if "`handle_misfit'"=="missing"{
		qui replace `generate'=. if `misfit'
	}

	if "`handle_misfit'"=="full"{
		qui keep if `misfit'
		*Assign again but with fake observations to "complete" the misfit groups.
		qui set obs `=_N+`num_treatments''
		qui by `cell_position': replace `rand' = _n //reusing rand for 2-lines
		fillin `cell_id' `rand'
		qui replace `rand' = runiform()
		sort `cell_id' `rand'
		qui replace `generate' = mod(_n-1, `num_treatments')+1
		qui drop if _fillin | `cell_id'==.
		drop _fillin
		append using `nonmisfits', nolabel nonotes
	}
end
