*! Version 1.0 Brian Quistorff <bquistorff@gmail.com>
*! An assert with a message when false
*! Similar to -_assert- except have a pause
program assert_msg
	version 11.0
	*Just a guess at the version
	
	syntax anything [, message(string)]
	
	cap assert `anything', fast
	if _rc==1 { //Break key
		error 1
	}
	if _rc!=0 {
		di "(`message') [`anything']!=0."
		pause
		error _rc
	}
end
