*! Version 1.0 Brian Quistorff <bquistorff@gmail.com>
*! Simplifies quick asserts
program assert_count
	version 11.0
	*Just a guess at the version
	syntax [if], rn(string) [message(string)]
	qui count `if'
	assert_msg `r(N)'`rn', message(`message')
end
