*! version 1.1 Brian Quistorff April 2015
*! version 1.0.11 (chardel) by NJC 1.0.1 1 April 2000 
*! Blanks out all chars for everything in the namelist passed in.
*! Along with reshape, destring also sometimes adds a var[destring] char
program def bchardel 
	version 10.0 
	syntax namelist 

	foreach name in `namelist'{
		local chnames : char `name'[] 
		foreach chname in `chnames'{
			char `name'[`chname']         /* blank it out */ 
		} 	
	}
end 		
	
