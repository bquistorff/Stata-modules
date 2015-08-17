mata: 
/**
 * @brief The quadratic mean
 * @param a matrix where each row will be transformed into the RMSPE
 *
 * @returns the RMS of each row
 */
real colvector calc_RMS(real matrix data){
	N = rows(data)
	L = cols(data)
	RMSPEs = J(N,1,.)
	for(i=1; i<=N; i++){
		RMSPEs[i,1] = sqrt(data[i,]*data[i,]'/L)
	}
	return(RMSPEs)
}

/**
 * @brief Calculates p-values of stat against placebos
 * @detailed For plain p-values, usually include the main estimations so 
 * if do N perm reps and b are better or equal then p=(b+1)/(N+1).
 * For weighted p-values there is no natural way to weight real vs permuation so p=b_w/N
 *
 * @param t_effect Treatment effect
 * @param c_effects Placebo/control "effects"
 * @param sided 1- or 2-sided test?
 * @param incl_real_in_null Think of treatment as part of null distribution?
 * @param c_weights weighted p-value's?
 *
 * @returns p-val
 */
real scalar calc_pval(real rowvector t_effect, real matrix c_effects, real scalar sided, 
						| real scalar incl_real_in_null, real colvector c_weights,
						real scalar assume_mean0){
	assert_msg(sided==1 | sided==2, "Error: sided must be 1 or 2")
	if(incl_real_in_null==.) incl_real_in_null= (c_weights!=J(1,1,.))
	K=cols(t_effect)
	if(assume_mean0==.) assume_mean0=1
	if(K>1){
		assume_mean0=0
		sided=1
	}
	
	tocompare = t_effect
	if(incl_real_in_null) compare_set = c_effects \ t_effect
	else compare_set = c_effects
	
	N=rows(compare_set)
	
	
	if(K>1){
		mvar = meanvariance(compare_set)
		m   = mvar[1,]
		var = mvar[|2,1 \ .,.|]
		vc_inv=invsym(var)
		compare_set=per_row_weighted_cross(compare_set - J(N,1,1)*m, vc_inv)
		tocompare = per_row_weighted_cross(tocompare   - m         , vc_inv)
	}
	else{
		if(!assume_mean0){
			m = mean(compare_set)
			compare_set = compare_set - m*J(1,N,1)
			tocompare = tocompare - m
		}
	}
	
	if(sided==2){
		select_bigger = (abs(compare_set):>= abs(tocompare))
	}
	else{
		if(tocompare>0)
			select_bigger = (compare_set:>= tocompare)
		else
			select_bigger = (compare_set:<= tocompare)
	}
	
	if(c_weights!=J(1,1,.)){
		c_weights_norm = c_weights :* (N/sum(c_weights))
		amount_as_big_treat = sum(select_bigger :* c_weights_norm)
	}
	else
		amount_as_big_treat = sum(select_bigger)
		
	return (amount_as_big_treat/N)
}

/**
 * @brief Calculates the 2-sided (I'm using RMSPE) p-values of stat against placebos
 *
 * @param y_diff_main_str Name of Stata matrix (Tx1) with main stat
 * @param y_diff_reps_str Name of Stata matrix (TxN) with placebo stats
 * @param pre_len Number of pre-treatment observations
 * @param justall Just include p-values for joint test of all post-treatment years? (Default=0)
 * @param post_tvar_labels String of tokens to label the t-periods by
 * @param perm_weights Name of Nx1 Weighted p-value. (Default=no weights)
 * @param yearsacross Should years be the columns (alternative is by rows)? (Default=1)
 *
 * @returns r(p_vals) matrix; r(howgood_match) scalar; 
 */
void eval_placebo(string scalar y_diff_main_str, string scalar y_diff_reps_str, 
	real scalar pre_len, | real scalar justall, string scalar post_tvar_labels,
	string scalar perm_weights_str, real scalar yearsacross) {
	
	//defaults
	if(justall == J(1,1,.)) justall = 0
	if(yearsacross == J(1,1,.)) yearsacross = 1
	if(perm_weights_str!="") perm_weights = st_matrix(perm_weights_str)
	else perm_weights = J(1,1,.)
	weighted= (perm_weights_str!="")
	incl_real_in_null = !weighted
	
	y_diff_main = (st_matrix(y_diff_main_str))'
	y_diff_reps = (st_matrix(y_diff_reps_str))'
	
	N = rows(y_diff_reps)
	
	
	assert_msg(cols(y_diff_main)>pre_len, "Error: cols(y_diff_main)<=pre_len")
	pre_PE = y_diff_main[1,1..pre_len]
	post_PE = y_diff_main[1,(pre_len+1)..length(y_diff_main)]
	assert_msg(cols(y_diff_main)==cols(y_diff_reps), "Error: rows(y_diff_main)!=rows(y_diff_reps)")
	pre_PEs = y_diff_reps[,1..pre_len]
	post_PEs = y_diff_reps[,(pre_len+1)..length(y_diff_main)]
	
	pre_RMSPE  = calc_RMS(pre_PE)
	pre_RMSPEs = calc_RMS(pre_PEs)
	post_RMSPE = calc_RMS(post_PE)
	post_RMSPEs= calc_RMS(post_PEs)
		
	limits = (1, 5)
	
	post_len = length(y_diff_main)-pre_len
	if(justall){
		post_len = 0
	}
	else{
		post_years = tokens(post_tvar_labels)
		if(length(post_years)!=post_len)
			post_years = strofreal(((pre_len+1)..length(y_diff_main)))
	}
	
	p_vals = J(post_len+1,length(limits)+2,.)
	howgood_match = J(1,length(limits)+1,.)
	
	
	post_time_strs = J(post_len+1,2,"")
	perm_w_to_use = J(1,1,.)
	for(post_time = 1; post_time<=(post_len+1); post_time++){
		if(post_time==(post_len+1)){
			post_tr = post_RMSPE
			post_ct = post_RMSPEs
			
			post_time_strs[post_time,] = ("", "all years joint")
		}
		else{
			post_tr = post_PE[1,post_time]
			post_ct = post_PEs[,post_time]
			post_time_strs[post_time,] = ("", post_years[1,post_time])
		}
		
		for(limit=1; limit<=(length(limits)+1); limit++){
			if(limit==(length(limits)+1)){
				selectvar = J(N,1,1)
			}
			else{
				selectvar = pre_RMSPEs:<(limits[limit]*pre_RMSPE)
			}
			if(weighted) perm_w_to_use = select(perm_weights, selectvar)
				
			p_vals[post_time,limit] = calc_pval(post_tr, select(post_ct, selectvar), 2, ., perm_w_to_use )
			ncases_to_use = sum(selectvar)
			amount_as_small_pre = sum(select(pre_RMSPEs, selectvar) :<= pre_RMSPE)
			howgood_match[1,limit] = (amount_as_small_pre + incl_real_in_null)/(ncases_to_use + incl_real_in_null)
		}
		
		p_vals[post_time,length(limits)+2] = calc_pval(post_tr/pre_RMSPE, post_ct:/pre_RMSPEs, 2, ., perm_weights)	
	}
	
	
	limit_strs  = J(length(limits),2,"")
	for(limit_i=1; limit_i<=length(limits); limit_i++){
		limit = limits[limit_i]
		if(limit==1){
			limit_strs[limit_i,] = ("", "$\{\hat\alpha_p|s_p\leq s_1\}$")
		}
		else{
			limit_strs[limit_i,] = ("", "$\{\hat\alpha_p|s_p\leq" + strofreal(limit) + " s_1\}$")
		}
	}
	limit_strs = limit_strs \ ("" , "$\{\hat\alpha_p\}$")
	limit_strs = limit_strs \ ("" , "$\{\tau_p=\hat\alpha_p /s_p\}$")
	
	st_rclear()
	if(yearsacross){
		st_matrix("r(p_vals)", p_vals')
		st_matrixcolstripe("r(p_vals)", post_time_strs)
		st_matrixrowstripe("r(p_vals)", limit_strs)	
	}
	else{
		st_matrix("r(p_vals)", p_vals)
		st_matrixcolstripe("r(p_vals)", limit_strs)
		st_matrixrowstripe("r(p_vals)", post_time_strs)
	}
		
	st_numscalar("r(howgood_match)", howgood_match[1,length(limits)+1])
}

//see conf_set for the more general approach
real rowvector calc_ci(real rowvector bhat, real colvector c_effects, real scalar alpha_ret, 
						real scalar incl_real_in_null, | real rowvector diffs_ret){
	N_ctrl = rows(c_effects)
	pmin = 2 * 1/(incl_real_in_null+N_ctrl)
	alpha_ind = max((1,round(alpha_ret/pmin)))
	alpha_ret = alpha_ind * pmin
	
	sorted = sort(c_effects,1)
	low_diff = sorted[alpha_ind]
	high_diff = sorted[(N_ctrl+1)-alpha_ind]
	if(diffs_ret!=J(1,1,.)) diffs_ret = (low_diff, high_diff)
	//note that the indices are swapped on the right
	effect_CIs = (bhat - high_diff, bhat - low_diff)
	return(effect_CIs)
}

real matrix conf_set(real rowvector t_effect, real matrix c_effects, real scalar alpha_ret){
	incl_real_in_null = 1
	N_ctrl = rows(c_effects)
	pmin = 2 * 1/(incl_real_in_null+N_ctrl)
	alpha_ind = max((1,round(alpha_ret/pmin)))
	alpha_ret = alpha_ind * pmin
	
	std_devs = std_deviation(c_effects)
	std_devs_sorted = sort(std_devs,1)
	c_effects_fit = fit_null_to_treatment(t_effect, c_effects)
	in_set = std_devs :>= std_devs_sorted[alpha_ind] :& std_devs :<= std_devs_sorted[(N_ctrl+1)-alpha_ind]
	cs = select(c_effects_fit, in_set)
	return(cs)
}

real matrix fit_null_to_treatment(real rowvector t_effect, real matrix c_effects){
	N_ctrl = rows(c_effects)
	return(J(N_ctrl,1,1)*t_effect - c_effects)
}

real colvector std_deviation(real matrix c_effects){
	N = rows(c_effects)
	mvar = meanvariance(c_effects)
	m   = mvar[1,]
	var = mvar[|2,1 \ .,.|]
	std_devs = per_row_weighted_cross(c_effects - J(N,1,1)*m, invsym(var))
	return(std_devs)
}

/**
 * @ brief Does a two-sided confidence interval.
 * Testing non-null hypotheses of b_0=b1: 
 * 		Apply null hypothesis (get "unexpected deviation) then permuate.
 * 		In this case, compare (bhat-b1) to {{b_perm}+(bhat-b1)}
 * To make the math a bit nicer, I will reject a hypothesis if pval<=alpha
 * CI: Find all b_c that aren't rejected
 *		pval(b_0=b_c)>alpha	(1)
 * The lowest possible pval is pmin=2/(N+1)
 * for alpha<pmin, the whole line is shared.
 * The next biggest chunk is CI(pmin<=alpha<2*pmin). Since we
 * will disply the "biggest confidence interval" we will set alpha=pmin.
 * The confidence includes (bhat-high_diff) and (bhat-low_diff)
 * Note that if the low and high points picked don't contain 0
 * then the Confidence Interval won't contain the estimated beta.
 * This is likely with only a few permutation tests.
 *
 * Assumes that pre_RMSPEs, post_PEs (from above function) exist
 * @param pre_len Number of pre-treatment observations.
 * @param y_diff_main_str Name of Stata matrix (Tx1) of the difference between Treatment and Control (T-C)
 * @param y_diff_reps_str Name of Stata matrix (TxN) with placebo stats
 * @param tc_outcome_str Name of Stata matrix (Tx2) with treatment (1) and control (2) outcomes
 * @param alpha Significance level (Default=0.05)
 * @param pre_cap_mult Limit the null-dist to those permutations by their pre-treatment RMSPE (Default=.)
 * @returns r(CI_pval) scalar; r(CIs) matrix.
 */
void makeCIs(real scalar pre_len, string scalar y_diff_main_str, string scalar y_diff_reps_str, 
	| string scalar tc_outcome_str, real scalar alpha, real scalar pre_cap_mult, 
	real scalar graphAroundControl, real scalar incl_real_in_null){
	
	y_diff_main = (st_matrix(y_diff_main_str))'
	y_diff_reps = (st_matrix(y_diff_reps_str))'
	assert_msg(cols(y_diff_main)>pre_len, "Error: cols(y_diff_main)<=pre_len")
	
	pre_PE = y_diff_main[1,1..pre_len]
	pre_PEs = y_diff_reps[,1..pre_len]
	
	post_PE = y_diff_main[1,(pre_len+1)..length(y_diff_main)]
	post_PEs = y_diff_reps[,(pre_len+1)..length(y_diff_main)]
	N = rows(post_PEs)
	
	pre_RMSPE = calc_RMS(pre_PE)
	pre_RMSPEs = calc_RMS(pre_PEs)
	
	post_RMSPE = calc_RMS(post_PE)
	
	if(alpha==.) alpha=0.05
	alpha_act = alpha
	if(incl_real_in_null==.) incl_real_in_null=1
	post_len = cols(post_PEs)
	
	if(pre_cap_mult>=.)
		post_PE_using = post_PEs
	else
		post_PE_using = select(post_PEs, pre_RMSPEs:<pre_RMSPE*pre_cap_mult)
	
	diff_ranges = J(post_len,2,.)
	effect_CIs = J(post_len,2,.)
	for(post_time = 1; post_time<=post_len; post_time++){
		diffs = J(1,2,.)
		effect_CIs[post_time,] = calc_ci(post_PE[1,post_time], post_PE_using[,post_time], alpha_act, incl_real_in_null, diffs)
		diff_ranges[post_time,] = diffs
	}
	
	if(sum(effect_CIs[,1] :> post_PE') + sum(effect_CIs[,2] :< post_PE'))
		printf("The used null distribution doesn't contain 0 (CI doesn't contain effect)\n")
	
	if(tc_outcome_str!=""){
		tc_outcome = st_matrix(tc_outcome_str)
		post_synth = tc_outcome[(pre_len+1)::rows(tc_outcome),2]
		if(graphAroundControl!=0){
			post_CIs = (diff_ranges[,1]+post_synth, diff_ranges[,2]+post_synth)
		}
		else
			post_CIs = (effect_CIs[,1]+post_synth, effect_CIs[,2]+post_synth)
		}
	else{
		post_CIs = effect_CIs
	}
	
	CIs = J(pre_len, 2,.) \ post_CIs
	
	st_rclear()
	st_numscalar("r(CI_pval)", alpha_act)
	st_matrix("r(CIs)", CIs)
}

void mean_post_RMSPEs(string scalar y_diff_reps_str, real scalar pre_len){
	y_diff_reps = (st_matrix(y_diff_reps_str))'
	post_PEs = y_diff_reps[,(pre_len+1)..cols(y_diff_reps)]

	N = rows(y_diff_reps)
	
	mean_post_RMSPEs = 0
	for(i=1; i<=N; i++){
		mean_post_RMSPEs = mean_post_RMSPEs+calc_RMS(post_PEs[i,])
	}
	mean_post_RMSPEs = mean_post_RMSPEs/N
	
	st_rclear()
	st_numscalar("r(mean_post_RMSPEs)", mean_post_RMSPEs)
}
end
