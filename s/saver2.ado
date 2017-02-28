*! version 0.0.1 Brian Quistorff <bquistorff@gmail.com>
*! Some helper utilities when saving so that common saving tasks can be on one line
*! Also warns if saving tempvars. Be careful with these. If you open a dta file with
*! tempvars and Stata's internal temp counter is different (e.g. open in a fresh session) there may be problems.
*! Requires: -saver-

* For example:
*//Session1
* sysuse auto, clear
* tempvar t
* gen `t' = 1
* save temp.dta, replae
* //session2
* use temp.dta, clear
* recode foreign (1=0)

program saver2
	syntax anything(name=filename) [, noDATAsig noCOMPress *]
	local filename `filename' //remove quotes if any
	
	if "`compress'"!="nocompress" compress
  if "`datasig'"!="nodatasig" datasig set, reset
  
	cap unab temp: _*
	if `:list sizeof temp'>0 di "Warning: Saving with temporary (_*) vars"
	
	saver "`filename'", `options'
end