*! drops all but the specified macros
*! parallel of -macro drop-
*! This has to be a mata function because otherwise can't access locals!

mata:
/*
 * pattern_list if space delimited. use "_" before locals
 */
void macro_keep(string scalar pattern_list){
	patterns = tokens(pattern_list)
	
	if(cols(patterns)==0) return
	
	//get the lists of all macros
	locals_todrop = st_dir("local", "macro", "*")
	globals_todrop = st_dir("global", "macro", "*")
	if(rows(globals_todrop)>0){
		sys_glob_pat = "^(S\_|!)"
		globals_todrop = select(globals_todrop, !regexm(globals_todrop, sys_glob_pat))
	}
	
	//remove from the lists the ones to keep
	for(i=1; i<=cols(patterns); i++){
		pattern = patterns[i]

		if (substr(pattern,1,1)=="_"){
			pat_len = strlen(pattern)
			if (pat_len>1){
				pattern = substr(pattern,2,pat_len-1)
				pattern
				locals_tokeep = st_dir("local", "macro", pattern)
				for(j=1; j<=rows(locals_tokeep); j++){
					locals_todrop = select(locals_todrop, locals_todrop :!= locals_tokeep[j])
				}
			}
		}
		else{
			globals_tokeep = st_dir("global", "macro", pattern)
			for(j=1; j<=rows(globals_tokeep); j++){
				globals_todrop = select(globals_todrop, globals_todrop :!= globals_tokeep[j])
			}
		}
	}
	
	//Now delete the ones left
	for(i=1; i<=rows(globals_todrop); i++){
		st_global(globals_todrop[i], "")
	}
	for(i=1; i<=rows(locals_todrop); i++){
		st_local(locals_todrop[i], "")
	}
}
end

