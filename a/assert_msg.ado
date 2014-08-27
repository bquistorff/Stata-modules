*! Version 1.0
*! An assert with a message when false
program assert_msg
    version 12
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
