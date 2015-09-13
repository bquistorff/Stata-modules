*! v0.3 Brian Quistorff <bquistorff@gmail.com>
*! Clears more than -clear all-.
*! It can't clear the locals from the calling context, so still might want to -mac drop _all-
*! (but unnecessary if used at top of do file that is only run (no -include-d) as it will have its own local context anyways)
program clear_all
	version 12 // is a guess
	syntax [, reset_ADO closeallmatafiles closealllogs]
	
	clear all //also clears graphs and sersets
	cap restore, not
	profiler off
	if "`closealllogs'"!="" log close _all
	
	*These are independent commands also. Embed for portability
	if "`reset_ADO'"!="" global S_ADO `"BASE;SITE;.;PERSONAL;PLUS;OLDPLACE"'
	
	*Normal open files closed by clear all
	if "`close_mata_files'"!=""{
		*From http://www.stata.com/statalist/archive/2006-10/msg00794.html
		forvalues i=0(1)50 {
			capture mata: fclose(`i')
		}
	}
	mac drop _all //has to be after use the options. effectively just clears globals
end
