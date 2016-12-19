mata:

//returns a matrix where base has the value of overlay where where_to_overlay==1
//where_to_overlay should contain either 1s or 0s
//doesn't handle .'s in base correctly (so use next function)
//TODO: This should be replaced with base[selectindex(where_to_overlay)]=overlay(where_to_overlay)
real matrix subset_assignment(base, where_to_overlay, overlay){
	return(base:*(1:-where_to_overlay)+where_to_overlay:*overlay)
}
//set's base missing values to be the corresponding ones from overlay
real matrix editmissing_vector(base, overlay){
	if(missing(base)==0)
		return(base)
	mis_indices = selectindex((base:==.))
	retmat = base
	retmat[mis_indices] = overlay[mis_indices]
	return(retmat)
}

//returns a matrix with each column multiplied by a scalar in cols_by
real matrix mult_each_col(real matrix base, rowvector cols_by){
	ret = J(rows(base),0,.)
	for(i=1; i<=length(cols_by);i++)
		ret = (ret, base[,i] :* cols_by[i])
	
	return(ret)
}

//draws random rows from a data vector
real matrix draw_random_rows(real matrix data, real scalar pr){
	return(select(data, rand_colvector(rows(data), pr)))
}
//This version will have exactly the right number of rows
real colvector draw_random_indexes(real scalar numrows, real scalar pr){
	return(jumble(1::numrows)[1::(pr*numrows),])
}
/*real colvector draw_random_indexes (real scalar numrows, real scalar pr){
	return(selectindex(rand_colvector(numrows, pr)))
}*/
real colvector rand_colvector(real scalar numrows, real scalar pr){
	return(floor(runiform(numrows,1):+pr))
}


real matrix remove_many_from_permutation(real vector perm, real vector nums){
	new_perm = perm
	new_nums = nums
	for(i=1; i<=cols(nums); i++){
		num = new_nums[i]
		new_perm = remove_from_permutation(new_perm, num)
		new_nums = subset_assignment(new_nums, (new_nums:>num), (new_nums:-1))
	}
	return(new_perm)
}
real vector remove_from_permutation(real vector perm, real scalar num){
	new_perm = select(perm, perm:!=num)
	return(subset_assignment(new_perm, (new_perm:>num), (new_perm:-1)))
}

real vector remove_many_ind_from_vector(real vector rowvec, real vector indexes){
	orig_len = cols(rowvec)
	indexes_len = cols(indexes)
	ret = J(1,(orig_len-indexes_len),0)
	new_i = 1
	for(orig_i=1; orig_i<= orig_len; orig_i++){
		found = 0
		for(k=1; k<=indexes_len; k++){
			if(orig_i==indexes[k]){
				found = 1
				break
			}
		}
		if(!found){
			ret[new_i] = rowvec[orig_i]
			new_i++
		}
	}
	return(ret)
}
real vector remove_ind_from_vector(real rowvector vect, real scalar index){
	len = length(vect)
	if(index == 1){
		if(len>1)
			return(vect[2..len])
		
		return(J(1,0,.))
	}

	if(index == len)
		return(vect[1..(len-1)])

	return(vect[(1..(index-1),(index+1)..len)])
}

real vector get_other_indices(real vector elim_ind, real scalar len){
	plain_ind = 1..len
	plain_ind[elim_ind] = J(1,cols(elim_ind),0)
	return(order(plain_ind',1)'[(cols(elim_ind)+1)..len])
}


//creates a column vector of the row-products
real matrix row_product(X){
	num_cols = cols(X)
	ret = J(rows(X),1,1)
	for(i=1; i<= num_cols; i++){
		ret = ret :* X[,i]
	}
	return(ret)
}

real scalar my_exp(real scalar x) return(exp(x))
real scalar my_ln(real scalar x) return(ln(x))
real scalar function identity_fn(x) return(x)
real scalar my_sq(real scalar x) return(x^2)
real scalar my_sqrt(real scalar x) return(sqrt(x))

//safe logistic function (never returns .). Useful.
real scalar function logistic_s(x){
	val = invlogit(x)
	min = 0.0000001
	max =  .9999999
	if(val != . & val<max & val>min) 
		return(val)
	if(x<0) return(min) //not sure about this line later
	return(max)
}

real matrix function apply_fns_to_vec(real matrix vect, fns){
	len = cols(vect)
	result = J(1,len,.)
	for(i=1; i<=len; i++){
		result[i] = (*(fns[i]))(vect[i])
	}
	return(result)
}


//Generates intermediate points between two vectors.
real matrix gen_lin_comb_params(p_start, p_end, num_total_inc){
	retm = p_start
	diff = (p_end :- p_start)/(num_total_inc-1)
	for(i = 1; i <= (num_total_inc-2); i++){
		retm = retm \ (p_start + (diff:*i))
	}
	retm = retm \ p_end
	return(retm)
}

//Mapping from multi-dimentions index to single-dimentions index
//if oneindex is 1, then vals and output are 1-indexed
// otherwise 0. oneindex should be 1,0,missing, or not included
//maxes are the total number possible in each dimension
real scalar function gen_index(real matrix vals, real matrix bases, | real scalar oneindex){
	oneindex = (!missing(oneindex) & oneindex==1)
	index = 0
	block_size = 1
	for(i=length(vals); i>=1; i--){
		index = index+block_size*(vals[i]-oneindex)
		block_size = block_size*bases[i]
	}
	return(index+oneindex)
}
real matrix function comp_from_index(real scalar index, real matrix bases, | real scalar oneindex){
	oneindex = (!missing(oneindex) & oneindex==1)
	ind = index-oneindex
	vals = J(1,length(bases),0)
	for(i=length(vals); i>=1; i--){
		vals[i] = mod(ind, bases[i])
		ind = trunc(ind/bases[i])
	}
	return(vals:+oneindex)
}
//when all the maxes are the same
real scalar function gen_index_cbase(real matrix vals, real scalar base, | real scalar oneindex){
	bases_length = length(vals)
	return(gen_index(vals,  J(1,bases_length,base), oneindex))
}
real matrix function comp_from_index_cbase(real scalar index, real scalar base, | real scalar oneindex){
	bases_length = round(log_b(base,index))+1
	return(comp_from_index(index, J(1,bases_length,base), oneindex))
}
//more generic log with respect to an arbitrary base
real scalar log_b(real scalar base, real scalar x){
	return(log(x) / log(base))
}
//only works with each element <10
real scalar show_in_base10(real matrix digits){
	ret = 0
	num_digits = cols(digits)
	for(i = cols(digits); i >=1; i--){
		ret = ret+digits[i]*(10^(num_digits-i))
	}
	return(ret)
}

void overwrite_st_store(real matrix mat, |string vector vnames){
	if(args()==1) vnames = J(1,cols(mat),"v") + strofreal(1..cols(mat))

	st_dropvar(.)
	temp = st_addvar("float", vnames)
	
	st_addobs(rows(mat))
            
	st_store(.,.,mat)
}

void st_append(real matrix obs){
	N0 = st_nobs() 
	N_del = rows(obs)
	st_addobs(N_del)
	new_rows = (N0+1)::(N0+N_del)
	st_store(new_rows,.,obs)
}

void print_vector(real vector row_vec, | real scalar nonewline){
	errprintf("(")
	errprintf("%f", row_vec[1])
	for(i=2; i<=cols(row_vec); i++){
		if(row_vec[i]==NULL)
			errprintf(", <<NULL>>")
		else
			errprintf(", %f", row_vec[i])
	}
	errprintf(")")
	if(nonewline == J(1,1,.) | nonewline==0)
		errprintf("\n")
}

//send in a 
matrix stack_matrices(rowvector mat_ptrs){
	len = length(mat_ptrs)
	if(len==0)
		return(J(0,0,.))
	ret = *(mat_ptrs[1])
	if(len>1)
		for(i=2; i<=len; i++){
			ret = ret, *(mat_ptrs[i])
		}
		
	return(ret)
}
	
//AIC. Want minimum
real scalar get_aic(real scalar lnL, real scalar k)
	return(2*(k-lnL))
	
//small-sample correction
real scalar get_aic_c(real scalar lnL, real scalar k, real scalar n)
	return(get_aic(lnL,k) + 2*k*(k+1)/(n-k-1))


void print_label_vector(real vector vect, string vector vect_label, | real scalar nonewline){
	errprintf("(")
	errprintf("%s=%f", vect_label[1], vect[1])
	for(i=2; i<=cols(vect); i++){
		errprintf(", %s=%f", vect_label[i], vect[i])
	}
	errprintf(")")
	if(nonewline == J(1,1,.) | nonewline==0)
		errprintf("\n")
}

//http://www.stata.com/statalist/archive/2006-07/msg00750.html
void plot(real colvector y, real colvector x, | string scalar opts)
{
	real scalar n, N, Y, X

	n = rows(y)
	if (rows(x)!=n) _error(3200)
	N = st_nobs()
	if (N<n) st_addobs(n-N)
	st_store((1,n), Y=st_addvar("double", st_tempname()), y)
	st_store((1,n), X=st_addvar("double", st_tempname()), x)
	stata("twoway scatter " + st_varname(Y) + " " +
	 st_varname(X) + ", " + opts)
	if (N<n) st_dropobsin((N+1,n))
	st_dropvar((Y,X))
}


//void setDvzero(struct deriv__struct scalar D){
//	D.verbose = 0
//}
//The optimizer doesn't pass it's verbosity setting to
// the Deriv structure.
//Might be particular to Stata13
void setSDverbosity(struct opt__struct scalar S, real scalar verbose){
	deriv__verbose_num(S.D, verbose)
}
transmorphic get_quiet_optimizer(){
	S = optimize_init()
	optimize_init_tracelevel(S, "none")
	optimize_init_verbose(S, 0)
	optimize_init_conv_warning(S, "off")
	setSDverbosity(S, 0)
	return(S)
}

//list externals and their sizes
void listexternal(){
	l = direxternal("*")
	for(i=1; i<=rows(l); i++){
		p = findexternal(l[i])
		printf(l[i] + ": rows=" + strofreal(rows(*p)) +", cols=" + strofreal(cols(*p)) + "\n")
	}
}

//ending mata
end
