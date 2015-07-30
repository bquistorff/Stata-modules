*! v0.2 Brian Quistorff <bquistorff@gmail.com>
*! A replacement for -tempfile- that provides more options for non-local outputs
*! 1) Creates auto-named globally-scoped files in tmpdir (ie persistent files the user is in charge of deleting)
*! 2) Can assign the file names to global macros
* Main usage: a script that uses tempfile's has an error and it is hard to recover because the tempfile were removed on end.
* Solution:
* 1) replace -tempfile- with -interimfile- so that the file will stick around after end
* 2) You can recover the locals that pointed to the files with -interimefile, recover_locals- to investigate
* 3) Once done, do -interimfile, rm_instance_interims- to remove the files
* rm_all_tempfiles is helpful if Stata crashed and left files around (doesn't remove the mini-temp do files created).
* Assumes the c(tmpdir) doesn't change between assignments and rm_*_interims or recover_locals
* Wish this could also be a pass-through to -tempfile- but they'd be auto-deleted at the end of this program
* This should work on unix (though not tested thoroughly) but I'm not sure of the tempfile naming conventions on other platforms

program interimfile
	version 11.0 //just a guess here
	syntax [namelist] [, globals rm_instance_interims rm_all_interims rm_all_tempfiles recover_locals]
	
	local deleting "`rm_instance_interims'`rm_all_interims'`rm_all_tempfiles'"
	if "`namelist'"!="" & "`deleting'"!=""{
		di as error "Can't create files and delete existing ones at the same time"
		error 1
	}

	if "${INTERIMFILE_INST_ID}"=="" interimfile_INST_ID INTERIMFILE_INST_ID
	local win = ("`c(os)'"=="Windows")
	local i_pre "S"
	local tmproot ="`c(tmpdir)'"+cond(`win',"","/")
	
	if "`namelist'"!=""{
		local macro_assign = cond("`globals'"!="","global","c_local")
		if "${INTERIMFILE_FILE_NUM}"==""{
			interimfile_delete, win(`win') i_pre(`i_pre') tmproot(`tmproot') rm_instance_interims
			global INTERIMFILE_FILE_NUM = -1
		}
		local namelist_num : list sizeof namelist
		forval i=1/`namelist_num'{
			global INTERIMFILE_FILE_NUM = ${INTERIMFILE_FILE_NUM}+1
			local id_str = string(${INTERIMFILE_FILE_NUM},"%06.0f")
			local name : word `i' of `namelist'
			local fname ="`i_pre'"+cond(`win',"ST_${INTERIMFILE_INST_ID}`id_str'.tmp","St${INTERIMFILE_INST_ID}.`id_str'")
			
			`macro_assign' `name' "`tmproot'`fname'"
		}
		if "`globals'"=="" global INTERIMFILE_INST_locs "${INTERIMFILE_INST_locs} `namelist'"
	}
	
	if "`deleting'"!=""{
		interimfile_delete, win(`win') i_pre(`i_pre') tmproot(`tmproot') `rm_instance_interims' `rm_all_interims' `rm_all_tempfiles'
	}
	
	if "`recover_locals'"!=""{
		forval i=1/`:word count $INTERIMFILE_INST_locs'{
			local lname : word `i' of $INTERIMFILE_INST_locs
			local id_str = string(`=`i'-1',"%06.0f")
			local fname ="`tmproot'`i_pre'"+cond(`win',"ST_${INTERIMFILE_INST_ID}`id_str'.tmp","St${INTERIMFILE_INST_ID}.`id_str'")
			c_local `lname' `fname'
		}
	}

end

program interimfile_delete
	syntax, win(string) i_pre(string) tmproot(string) [rm_instance_interims rm_all_interims rm_all_tempfiles]
	
	local f_prefix  = cond(`win',"ST_","St")
	local any_inst  = cond(`win',"??","?????")
	local any_seqno = cond(`win',"??????.tmp",".??????")
	
	if "`rm_instance_interims'"!="" local pattern = "`i_pre'`f_prefix'${INTERIMFILE_INST_ID}`any_seqno'"
	if "`rm_all_interims'"     !="" local pattern = "`i_pre'`f_prefix'`any_inst'`any_seqno'"
	if "`rm_all_tempfiles'"    !="" local pattern =        "`f_prefix'`any_inst'`any_seqno'"
	
	local files_to_delete : dir "`tmproot'" files "`pattern'", respectcase
	foreach file_to_delete of local files_to_delete{
		rm "`tmproot'`file_to_delete'"
	}
	
	if "`rm_instance_interims'`rm_all_interims'"!=""{
		macro drop INTERIMFILE_INST_locs INTERIMFILE_FILE_NUM
	}
end

program interimfile_INST_ID
	args gname
	*Mostly from http://www.stata.com/statalist/archive/2007-08/msg01124.html
	tempfile tfullfile
	*I think it only goes 0-9a-w but just in case.
	local matc = regexm("`tfullfile'",cond("`c(os)'"=="Windows","ST_([a-z0-9][a-z0-9])([a-z0-9]+)\.tmp$","St([a-z0-9]+)\.([a-z0-9]+)$"))
	
	if `matc'!=1 error 1
	global `gname' `=regexs(1)'
end
