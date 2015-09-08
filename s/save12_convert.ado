*! version 0.1 Brian Quistorff <bquistorff@gmail.com>
*! converts a file using save12. Can prefix a command (that produces it).
program save12_convert
	if regexm(`"`0'"',":") {
		gettoken 0 colon_command : 0, parse(":")
		gettoken colon command : colon_command, parse(":")
		`command'
	}
	syntax anything [, replace *]
	
	
	preserve
	use `anything', clear
	save12 `anything', replace `options'
	restore
end
