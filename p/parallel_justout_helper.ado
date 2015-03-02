*! Does: parses up uneven tasks, takes care of the seed, appends datasets, cleans up temps
*! Assumed globals:  numclusters, dir_base
*! If doesn't work do:
*! parallel clean, all force
*! Right now if something goes wrong, tempfiles are left around in temp folder (slightly bad).
program parallel_justout_helper
	*set trace on
	syntax , donor_mat(string) cmd_base(string) cmd_options(string) outfile(string) [permweightsfile(string)]
	
	tempfile initdatafile
	qui save "`initdatafile'", replace
	*-parallel cmd- changes the seed
	local rng_state_init = "`c(seed)'"
	
	tempname donor_mat_left
	mat `donor_mat_left' = `donor_mat'
	
	local reps_left = rowsof(`donor_mat')
	
	*Rounds of parallel computation
	while `reps_left'>0 {
		*Determine reps for this round
		local reps = `reps_left'
		if "${max_rep_per_cl}"!=""{
			local max_reps_per_round = ${max_rep_per_cl}*${numclusters}
			if `reps_left'>`max_reps_per_round' {
				local reps = `max_reps_per_round'
			}
		}
		
		*Setup the matrices
		if `reps'<${numclusters} {
			forval i=1/`reps'{
				mata: donor_mat`i' = st_matrix("`donor_mat_left'")[`i',1]
			}
		}
		else {
			local normal_reps = floor(`reps'/${numclusters})
			forval i=1/${numclusters}{
				local start_ind = (`i'-1)*`normal_reps'+1
				local end_ind = `i'*`normal_reps'
				if `i'== ${numclusters} {
					local end_ind = `reps'
				}
				mata: donor_mat`i' = st_matrix("`donor_mat_left'")[`start_ind'..`end_ind',1]
			}
		}
		if `reps'<`reps_left' {
			mat `donor_mat_left' = `donor_mat_left'[`=`reps'+1'...,1]
		}
		local reps_left = `reps_left'-`reps'


		*Setup for the main run
		if `reps'<${numclusters} {
			local oldnumcl = ${numclusters}
			parallel_clean_setclusters `reps', noclean
		}
		forval i=1/${numclusters}{
			*cap erase "`outfile'`i'" //post replaces
			cap erase "`permweightsfile'`i'"
		}
		parallel, mata nodata keep: `cmd_base' , `cmd_options' donor_mat(donor_mat) ///
			outfile("`outfile'") permweightsfile("`permweightsfile'") ///
			logfile("${dir_base}/log/`cmd_base'_run${extra_f_suff}")
		assert_msg r(pll_errs)==0
		global pid `r(pll_id)'

		*Aggregate the estimates
		qui drop _all
		forval i = 1/${numclusters} {
			append using "`outfile'`i'"
		}
		*assert_msg _N>0
		cap append using "`outfile'"
		qui save "`outfile'", replace
		
		if "`permweightsfile'"!= ""{
			qui drop _all
			forval i = 1/${numclusters} {
				append using "`permweightsfile'`i'"
			}
			cap append using "`permweightsfile'"
			qui save "`permweightsfile'", replace
		}

		*Erase temp files after the data appending so that if one process fails, can debug
		forval i = 1/${numclusters} {
			erase "`outfile'`i'"
			erase "${dir_base}/log/`cmd_base'_run${extra_f_suff}`i'.log"
			cap erase "`permweightsfile'`i'"
		}
		
		*Now restore the normal numclusters
		if "`oldnumcl'"!="" {
			parallel_clean_setclusters `oldnumcl', noclean
		}

		*With repeated calls was getting an error (select needs a vector in parallel_clean)
		*Unless I take care of the temp files using -parallel clean-.
		cap parallel clean, event(${pid}) force
		* Got an "unlink():  3621  attempt to write read-only file \n parallel_clean():     -  function returned error
		* So trying this
		if _rc!=0{
			closeallmatafiles
			di as error "-parallel clean- gave an error, waiting and trying again"
			sleep 1000
			cap parallel clean, event(${pid}) force
		}
	}
	set seed `rng_state_init'

	qui use "`initdatafile'", clear
	*di "Done with parallel_justout_helper"
end
