*! v1.0 bquistorff@gmail.com
*! converts a *.gph file to three possible derivate files
program gph2fmt
	version 12.0 //just a guess
	syntax anything(everything name=gph_file), [plain_file(string) titleless_file(string) bare_file(string)]
	
	tempname toexport
	graph use "`gph_file'", name(`toexport')
	
	if "`plain_file'"!="" graph export "`plain_file'", replace
	gr_edit .title.draw_view.setstyle, style(no)
	if "`titleless_file'"!="" graph export "`titleless_file'", replace
	gr_edit .note.draw_view.setstyle, style(no)
	if "`bare_file'"!="" graph export "`bare_file'", replace
	
	graph drop `toexport'
end
