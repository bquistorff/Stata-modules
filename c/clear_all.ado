*! v0.2 Brian Quistorff <bquistorff@gmail.com>
*! Really resets everything (-clear all- doesn't clear all)
program clear_all
	version 12
	*version is a guess
	syntax [, reset_ADO closeallmatafiles closealllogs]
	clear all
	mac drop _all
	cap restore, not
	profiler off
	if "`closealllogs'"!="" log close _all
	
	*These are independent commands also. Embed for portability
	if "`reset_ADO'"!="" global S_ADO `"BASE;SITE;.;PERSONAL;PLUS;OLDPLACE"'
	if "`close_mata_files'"!=""{
		*From http://www.stata.com/statalist/archive/2006-10/msg00794.html
		forvalues i=0(1)50 {
			capture mata: fclose(`i')
		}
	}
end
