*Notes:
* If you want the trace log from the optimizer from synth run it in batch mode and on Windwos it
*  creates a 'temp' file.
*Todo:
*On linux, -synth, nested- it eats up all the memory. This didn't seem to be reported by -memory-.

cap log close _all
log using "test.internal.log", replace name(test)

clear all
sysdir set PERSONAL "`c(pwd)'/ado"
sysdir set PLUS "`c(pwd)'/ado"
global S_ADO "PERSONAL;BASE"
set more off

cap confirm file ado/s/synth.ado
if _rc!=0{
	mkdir ado
	
	net set ado PLUS
	net set other PLUS
	local lcl_repo "`c(pwd)'/../.."
	ssc install synth, all
	net install synth2, from(`lcl_repo'/s) all
	
	net install b_file_ops, from(`lcl_repo'/b) all
	find_in_file using ado/s/synth.ado , regexp("qui plugin call synthopt") local(pluginline)
	change_line  using ado/s/synth.ado , ln(`pluginline')      insert(" timer on  1")
	change_line  using ado/s/synth.ado , ln(`=`pluginline'+2') insert(" timer off 1")
	find_in_file using ado/s/synth2.ado, regexp("cap plugin call synth2opt") local(pluginline)
	change_line  using ado/s/synth2.ado, ln(`pluginline')      insert(" timer on  1")
	change_line  using ado/s/synth2.ado, ln(`=`pluginline'+2') insert(" timer off 1")
		
	
	
}
else{
	*adoupdate synth synth2, update //TODO: re-enable when done with testing
}
mata: mata mlib index

version 13
local init_seed 1234567890
set seed `init_seed' //though I don't think I'm randomizing

* Test basic plugin behavior. Remember H has to be symmetric
if 0{
scalar n = 3
scalar m = 2
mat c = (1 \ 0 \ 0)
mat H = (0,0,0 \ 0,1,1 \ 0,1,1)
mat A = (1,0,1 \ 0,1,1) //m.n
mat b = (1.5  \ 1)
mat l = J(n,1,-2)
mat u = J(n,1,3)
mat wsol = J(n,1,.)
cap program synth2opt, plugin
plugin call synth2opt , c H A b l u 10 0.005 20 12 wsol
assert wsol[1,1]+1.5<0.001 & wsol[2,1]+2<0.001 & wsol[3,1]-3<0.001
}

*Test basic equality between synth and synth2
if 0{
sysuse smoking, clear
drop if lnincome==.
tsset state year

synth cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988 1980 1975), trunit(3) trperiod(1989)
mat w = e(W_weights)

synth2 cigsale beer(1984(1)1988) lnincome retprice age15to24 cigsale(1988 1980 1975), trunit(3) trperiod(1989)
mat w2 = e(W_weights)

mat diff = w-w2
mata: assert(colsum(st_matrix("diff"))[1,2]<0.01)
}


*Test correction of error that synth can give
if 0{
*The below command with -synth- on Windows gives all . for weights.
* The optimizer matches on football airport and then dies

use syntherror12.dta, clear

local curr_eval 152
*original error report command
local predictors "dmlnpoptot(1) dmlnpoptot(3) dmlnpoptot(5) dmlnpoptot(7) football airport"
local mspeperiod "1(1)7"
*more minimal command that still errors
local predictors "dmlnpoptot(1) football airport"
local mspeperiod "4 7"


synth2 dmlnpoptot `predictors', trunit(`curr_eval') mspeperiod(`mspeperiod') resultsperiod(8(1)15)  trperiod(8) skipchecks
mat x =  e(W_weights_unr)
assert x[1,2]!=.
}

*Speed test synth vs synth2
if 1{
sysuse smoking, clear
drop if lnincome==.
label values state
tsset state year
set matsize 9000

tempfile smoke
save `smoke'
gen int wave=1
local N_waves=20
forval i=2/`N_waves'{
	qui append using `smoke'
	qui recode wave (.=`i')
	*make them not colinear
	qui replace cigsale=cigsale*1.01*`i' if wave==`i'
	qui replace beer=beer*1.02*`i' if wave==`i'
	qui replace lnincome=lnincome*1.03*`i' if wave==`i'
	qui replace retprice=retprice*1.04*`i' if wave==`i'
	qui replace age15to24=age15to24*1.05*`i' if wave==`i'
}
egen long new_id = group(state wave)
tsset new_id year

local N=1
*even took out some averaging becausing synth is probably slower at that.
local synth_command "cigsale beer(1988) lnincome(1984) retprice(1984) age15to24(1984) cigsale(1984) cigsale(1985) cigsale(1986) cigsale(1987) cigsale(1988), trunit(3) trperiod(1989)"
timer on 2
forval i=1/`N'{
	qui synth2 `synth_command'
}
timer off 2
di "timer1 is plugin, timer2 is total"
timer list
timer clear
timer on 2
forval i=1/`N'{
	qui synth `synth_command'
}
timer off 2
timer list
timer clear
}

clear all //needed to copy over the plugin file (release the file lock)
log close test
