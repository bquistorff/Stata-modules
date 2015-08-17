* v 1.0 2015-04-15
* Author: Brian Quistorff
*
* Usage:
* The code is currently setup for cases where there are T units
* and each receives a different treatment schedule. A permutation reassigns
* the schedules to different units. There are T! total permutation.
* It is assumed that the data is -sort unit period- and strongly balanced.
* For a different treatment-data structure one should be able to just
* modify setup_permutation_maker() and set_permutation()
*
* Example code:
* mata: setup_permutation_maker(`num_treatments', "treat_schedule_var")
* forval perm_num=`init_perm_num'/`end_perm_num'{
*		mata: set_permutation(`perm_num', `num_treatments', "new_treat_schedule_var")
* 	reg depvar new_treat_schedule_var
* }
*
* Notes: 
* 	If you want to enumerate all permutations serially then look at
* Heap's Algorithm or Steinhaus-Johnson-Trotter algorithm. But I'm not sure how
* to break up into subsets to parallelize (probably can find ways to break
* it up at certain points in the process, but haven't investigated this).
*	If you want to easily go from permutation number to permutation (so
* that you can break the problem up easily for parallelizing) then convert
* to factorial number system. Watch out for over-running the limits of numbers
* 	If you don't want to exhaustively enumerate permutations then you sample
* the distribution with the Fisher-Yates shuffle.
*
* To generalize to other types of RI think of having N treatments each of size 1.
* Then we do the permutation of assigning them to N units. #=N!
* In an RCT we have T treatments of size n_t and assign them to N=(sum_t n_t) units. 
* This is called distinguishable permutations and #=N!/(prod_t n_t!) if you think of 
* the different ways of permuting the treatment.
* Equivalently, this is a multinomial coefficent where we think of assigning N units
* to sized bins (treatments).
* In a simple RCT with 2 equal sized arms then #=N!/( (N/2)! * (N/2)!)
* This is equivalent to think about doing (T-1) assignments from the pool of obs
* to treatments (the last one just assigns everyone left to the last treatment).
* So you do C_{n_1}^N then you do C_{n_2}^{N-n_1} ... which is T-1 combinations.
* So this t index a particular complete assignment then you just need to index each
* combination. You can use the https://en.wikipedia.org/wiki/Combinatorial_number_system
* See this article for how I implemented the conversions below.
*
* All reals in Mata are of type double (8 byte) with 16 digits of precision this should be as accurate numerically
* as working with 4-byte longs.

mata:
void setup_permutation_maker(real scalar num_T, string scalar existing_data_str){
	external schedules
	sch_data =  st_data(., existing_data_str)
	N = length(sch_data)
	sch_len = N/num_T
	schedules = J(sch_len, num_T,.)
	for(i = 1; i<= num_T; i++){
		start_i = (i-1)*sch_len+1
		end_i = start_i+sch_len-1
		schedules[.,i] = sch_data[(start_i::end_i),1]
	}
}

//Assumes new_var_str exists.
void set_permutation(real scalar perm_num, real scalar num_treatments, string scalar new_var_str){
	external schedules
	permutation = permutation_from_perm_num(num_treatments, perm_num)
	new_var = J(0,1,.)
	for(i=1; i<=num_treatments; i++){
		new_var = new_var \ schedules[,permutation[i]]
	}
	st_store(., new_var_str,new_var)
}

//Usage:
// num_items: number of items you are permuting
// permutation_num: range=[1,num!]. The specific permutation number.
// Output: a num_items length vector where each element is in [1,num_items] and each number
//         is unique in the vector. 
real rowvector permutation_from_perm_num(real scalar num_items, real scalar permutation_num){
	//First decompose the perm number into the index "choices"
	choices = convert_to_fact_base(num_items, permutation_num-1):+1
	
	//Build orig_list list
	orig_order = J(1,num_items,1)
	for(index=2; index<=num_items; index++){
		orig_order[index] = index
	}
	
	perm = J(1,num_items,.)
	for(index=1; index<=num_items; index++){
		choice = choices[index]
		perm[index] = orig_order[choice]
		orig_order = remove_ind_from_vector(orig_order, choice)
	}
	
	return(perm)
}

real scalar perm_num_from_permutation(real rowvector perm){
	//Convert final items to choices
	num_items = length(perm)
	
	//Build orig_list list
	orig_order = J(1,num_items,1)
	for(index=2; index<=num_items; index++){
		orig_order[index] = index
	}
	
	choices = J(1,num_items,.)
	//For first one, index of perm[1] in orig_order is perm[1]
	choices[1] = perm[1]
	orig_order = remove_ind_from_vector(orig_order, perm[1])
		//Find index of perm[i] in orig_order
	for(i=2; i<=num_items-1; i++){
		for(j=1; j<=length(orig_order) ; j++){
			if(orig_order[j]==perm[i]){
				choices[i] = j
				orig_order = remove_ind_from_vector(orig_order, j)
				break
			}
		}
	}
	choices[num_items] = 1
	
	return(convert_from_fact_base(choices:-1)+1)
}

real rowvector convert_to_fact_base(real scalar fb_length, real scalar num_10){
	num_fb = J(1,fb_length,0)
	for(index=2; index<= fb_length; index++){
		digit_fb = mod(num_10, index)
		num_fb[fb_length+1-index] = digit_fb
		num_10 = (num_10-digit_fb)/index
	}
	return(num_fb)
}

// Ideally would warn if it is going to be outside the range 
real scalar convert_from_fact_base(real rowvector num_fb){
	fb_length = length(num_fb)
	num_10 = 0
	for(i=1; i<=fb_length-1; i++){
		num_10 = num_10+num_fb[i]
		num_10 = num_10*(fb_length-i)
	}
	
	return(num_10)
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

void test(){
	num_fb = (1,1,0)
	assert(num_fb == convert_to_fact_base(length(num_fb),convert_from_fact_base(num_fb)))
	perm = (3,1,2)
	assert(perm == permutation_from_perm_num(length(perm), perm_num_from_permutation(perm)))
}

end
