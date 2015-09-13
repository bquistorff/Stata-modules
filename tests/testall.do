set PLUS "`c(pwd)'/../"
set PERSONAL "`c(pwd)'/../"
log using testall.log, name(testall) replace

local dirs :dir . dir *
foreach dir in `dirs'{
	cd `dir'
	do `test.do
	cd ..
}

do net_tests.do

log close testall
