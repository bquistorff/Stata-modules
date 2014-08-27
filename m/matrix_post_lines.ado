*! Version 1.0
*! Creates the post init and post string lines that will come from a matrix
program matrix_post_lines, sclass
    version 12
	syntax , matrix(string) varstub(string) varnumend(int) [varnumstart(int 1)]
	
	*Create the post strings (faster in mata and nicer in traced-log)
	local num_per =`varnumend'-`varnumstart'+1
	mata: line_init = invtokens(J(1,`num_per', " float `varstub'") + strofreal(`varnumstart'..`varnumend'))
	mata: line_post = invtokens(J(1,`num_per', " (`matrix'[") + strofreal(1..`num_per') + J(1,`num_per',",1])"))
	*^^^ Does the same as the below.
	/*forval i = `varnumstart'/`varnumend' {	
		local ps_init "`ps_init' float PE`i'"
		local ps_posting "`ps_posting' (`matrix'[`=`i'-`varnumstart'+1',1])"
	}*/
	mata: st_local("ps_init", line_init)
	mata: st_local("ps_posting", line_post)
	
	sreturn local ps_init = "`ps_init'"
	sreturn local ps_posting = "`ps_posting'"
	
end
