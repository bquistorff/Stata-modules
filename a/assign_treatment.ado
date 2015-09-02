*! version 1.2 Brian Quistorff <bquistorff@gmail.com>
program assign_treatment
	version 11.0 //Just a guess
	
	syntax varlist, generate(namelist max=1) num_treatments(int) [handle_misfit(string)]
	if "`handle_misfit'"=="" local handle_misfit = "obalance"

	* Error checking
	_assert inlist("`handle_misfit'","obalance","full", "full_obalance", "reduction", "missing"), rc(197) ///
		msg("Error: handle_misfit() option must be one of: full, reduction, missing, full_obalance, obalance (or empty).")
	_assert `num_treatments'> 0 & `num_treatments'<=`=_N', rc(197) ///
		msg("Error: num_treatments must be greater than 0 and not greater than _N.")
	
	if "`handle_misfit'"=="reduction" & `: word count `varlist''<2 local handle_misfit = "obalance"
	
	* First-pass randomization. Implicitly does "obalance" and determines misfits.
	tempvar cell_id cell_position rand misfit
	gen `rand' = runiform()
	egen `cell_id'    = group(`varlist')
	sort `cell_id', stable
	by `cell_id' : gen `cell_position' = `rand'[1]
	sort `cell_position' `rand'
	by `cell_position': gen `misfit' = (_n > floor(_N/`num_treatments')*`num_treatments')
	gen int `generate' = mod(_n-1, `num_treatments')+1 
	
	if inlist("`handle_misfit'","full","full_obalance","reduction"){
		*separate out the misfits
		tempfile nonmisfits
		preserve
		qui drop if `misfit'
		qui save `nonmisfits'
		restore
		qui keep if `misfit'
	
		if "`handle_misfit'"=="reduction"{
			tempvar prev_cell_internal_rank prev_cell_id bigger_cell_id prev_cell_rand
			by `cell_position': gen int `prev_cell_internal_rank' = _n
			local varsleft = "`varlist'"
			gen int `prev_cell_id' = `cell_id'
			sort `prev_cell_id' `prev_cell_internal_rank' //no change, just update varname in sortorder
			while `:word count `varsleft''>1{
				gettoken var varsleft : varsleft
				cap drop `bigger_cell_id' `prev_cell_rand'
				egen int `bigger_cell_id' = group(`varsleft')
				
				by `prev_cell_id' : gen `prev_cell_rand' = `rand'[1]
				sort `bigger_cell_id' `prev_cell_rand'  `prev_cell_internal_rank'
				qui by `bigger_cell_id': replace  `prev_cell_internal_rank' = _n
				qui replace `prev_cell_id' = `bigger_cell_id'
				sort `prev_cell_id' `prev_cell_internal_rank' //no change, just update varname in sortorder
			}
			qui replace `generate' = mod(_n-1, `num_treatments')+1
		}
		if "`handle_misfit'"=="full"{
			*Assign again but with fake observations to "complete" the misfit groups.
			qui set obs `=_N+`num_treatments''
			tempvar rank
			qui by `cell_position': gen `rank' = _n
			fillin `cell_id' `rank'
			qui replace `rand' = runiform() //re-fill
			sort `cell_id' `rand'
			qui replace `generate' = mod(_n-1, `num_treatments')+1
			qui drop if _fillin | `cell_id'==.
			drop _fillin
		}
		if "`handle_misfit'"=="full_obalance"{
			mata: set_full_obalance(`num_treatments', "`cell_id'", "`generate'")
		}
		
		append using `nonmisfits', nolabel nonotes
	}
	
	if "`handle_misfit'"=="missing"{
		qui replace `generate'=. if `misfit'
	}
	
	qui compress `generate'
end

mata:

void set_full_obalance(real scalar T, string scalar cell_id_var, string scalar output_var){
	cell_ids = st_data(.,cell_id_var)
	N = rows(cell_ids)
	ids = 1::N
	obs = (ids,cell_ids)

	ret = full_obalance(T, obs)
	if(missing(ret)) _error(197, "Error: Something went wrong. Not possible to assign misfits to treatments without overlap.")
	
	ts = mod(ids :-1, T) :+ 1
	data =  sort((obs, ts), 1)
	st_store(.,output_var, data[,3])
}

//This functions uses the order to implicitly record the treatment
//obs = (id, cell_id)
//This is a simple constraint-satisfaction solver
real matrix full_obalance(real scalar T, real matrix obs_left, | real matrix obs_fixed, real matrix cell_id_freq){
	if(rows(obs_left)==0) return(J(0,2,.))
	if(obs_fixed==J(0, 0, .)) obs_fixed = J(0,2,.)
	if(cell_id_freq==J(0,0,.)){
		cids = obs_fixed[,2] \ obs_left[,2]
		cid_max = max(cids)
		cell_id_freq = J(cid_max,1,0)
		for(i=1; i<=rows(cids); i++){
			cell_id_freq[cids[i]] = cell_id_freq[cids[i]]+1
		}
	}
	
	new_rank = rows(obs_fixed)+1
	new_t = mod(new_rank-1,T)+1
	
	obs_available = obs_left
	for(i=new_t; i<new_rank; i=i+T){
		obs_available = select(obs_available,obs_available[,2]:!=obs_fixed[i,2])
	}
	n_avail = rows(obs_available)
	
	//pick order to try for next ones
	//obs_to_try = jumble(obs_available) //simple/naive method
	//the above method will sometimes take quite a while to find a solution
	// so instead try to fit first the cell_ids that are hard to do so (ones with most misfits)
	//can tune this using the w parameter (w=0 is no weighting)
	rand = runiform(n_avail,1)
	w=1
	for(i=1; i<=n_avail; i++){
		rand[i,1] = rand[i,1]*(1+w*cell_id_freq[obs_available[i,2]])
	}
	perm = order(rand,-1)
	obs_to_try = obs_available[perm,]
	
	for(i=1; i<=n_avail; i++){
		ob_to_try = obs_to_try[i,]
		ret = full_obalance(T, select(obs_left,obs_left[,1]:!=ob_to_try[1,1]), obs_fixed \ ob_to_try, cell_id_freq)
		if(!missing(ret)) return(ob_to_try \ ret)
	}
	return(.)
}

end
