*! Version 1.2 Brian Quistorff <bquistorff@gmail.com>
*! Latex output of summary stats
**************************************
*Editted slightly by Brian Quistorff 11-09-2013
* -allows filenames with spaces
* -allows dropping the \begin{table} \end{table} lines (better for customization)
*This is sutex.ado beta version
*04 Sep 2001
*Questions, comments and bug reports : 
*terracol@univ-paris1.fr
*************************************
prog define sutex_env, byable(recall,noheader)
version 7.0
syntax [varlist] [if] [in] [aweight fweight],  [DIGits(integer 3)] [LABels] [PAR] [NOBS] [MINmax] [NA(string)] [TITle(string)] [KEY(string)] [PLacement(string)] [LONGtable] [NOCHECK] [NOTABLEENV] [FILE(string)] [APPEND] [REPLAce] 

********************
* Verifying syntax
********************
capture confirm variable `varlist'
if _rc==7 {
		di as error "no variables found" exit
		}
if "`file'"=="" & ("`append'"!="" | "`replace'"!="") {
									di as error "append and replace are only usable in conjonction with file, options ignored"
									}
if `digits'<0 | `digits' >20 {
					di as error "DIGits must be between 0 and 20"
					exit
					}

tempvar touse
mark `touse' `if' `in'
if _by() {
		qui replace `touse'=0 if `_byindex'!=_byindex()
		}

tempname fich
**********************
*setting file extension
**********************
if "`file'"!="" {
			tokenize "`file'", parse(.)
			if "`3'"=="" {
						local file="`1'.tex"
					}
			}

if _byindex()>1 {
			local replace=""
			local append="append"
			}
if "`file'"=="" {
			local type="di "
			}
if "`file'"!=""{
			local type="file write `fich'"
			local nline="_n"
			}
if "`file'"!="" {
			file open `fich' using "`file'" ,write `append' `replace'  text
			}


************************
*Table heads
************************
local nm_vr="Variable"
local nm_me="Mean"
local nm_sd="Std. Dev."
local nm_mn="Min."
local nm_mx="Max."
local headlong="... table \thetable{} continued"
local footlong="Continued on next page..."
*********************************

if "`placement'"=="" {
				local placement="htbp"
				}

if _by() {
		local by=_byindex()
		}

local z="`na'"
if "`na'"!="" {
			local na2="na(`z')"
			}
if "`varlist'"=="" {
				local varlist =unav _all
			}
if "`title'"=="" {
			local title="Summary statistics"
			}
if "`key'"=="" {
			local key="sumstat"
			}
local title="`title' `by'"
if _by()!=0 {
		local key="`key'`by'"
		}

*************************
*checking number of obs
************************
local v=2
tokenize "`varlist'"
qui su `1'
local q1=r(N)
mac shift
while "`1'" !="" {
			qui su `1'
			local q`v'=r(N)
			if `q`v''!=`q1' {local nobs="nobs"}
			local v=`v'+1
			mac shift
			}

			

***********************
* Number of digits
***********************

local nbdec="0."
local i=1
while `i'<=`digits'-1 {
				local nbdec="`nbdec'0"
				local i=`i'+1
				}
if `digits'==0 {
			local nbdec="1"
			}
if `digits'>0 {
			local nbdec="`nbdec'1"
			}

********************
* setting columns
********************

if "`minmax'"!="" {
			local a1=" c c"
			}
if "`minmax'"!="" {
			local a2=" & \textbf{`nm_mn'} &  \textbf{`nm_mx'}"
			}
local a3=2
if "`minmax'"!="" {
			local a3=`a3'+2
			}
if "`nobs'"!="" {
			local a3=`a3'+1
			}
local a6=`a3'+1
if "`nobs'"!="" {
			local a4=" c"
			}
if "`nobs'"!="" {
			local a5=" & \textbf{N}"
			}
if "`par'"!="" {
			local op="("
			}
if "`par'"!="" {
			local fp=")"
			}

if "`file'"=="" {
			`type' "%------- Begin LaTeX code -------%"_newline
			}
if "`file'"!="" {
			`type' ""_n
			}

******************
* "regular" table
******************
if "`longtable'"==""{
if "`notableenv'"=="" {
	`type' "\begin{table}[`placement']\centering \caption{`title'\label{`key'}}"`nline'
}
`type' "\begin{tabular}{l c c `a1' `a4'}\hline\hline"`nline'
`type' "\multicolumn{1}{c}{\textbf{`nm_vr'}} & \textbf{`nm_me'}" _newline " & \textbf{`op'`nm_sd'`fp'}`a2' `a5'\\\ \hline"`nline'
}

*******************
*longtable
******************

if "`longtable'"!="" {

`type'  `nline'"\begin{center}"_newline "\begin{longtable}{l c c `a1' `a4'}"`nline'
`type' "\caption{`title'\label{`key'}}\\\"_newline"\hline\hline\multicolumn{1}{c}{\textbf{`nm_vr'}}"_newline" &\textbf{`nm_me'}"_newline" & \textbf{`op'`nm_sd'`fp'}`a2' `a5' \\\ \hline"`nline'
`type' "\endfirsthead"`nline'
`type' "\multicolumn{`a6'}{l}{\emph{`headlong'}}"_newline"\\\ \hline\hline\multicolumn{1}{c}{\textbf{`nm_vr'}}"_newline" & \textbf{`nm_me'}"_newline" & \textbf{`op'`nm_sd'`fp'}`a2' `a5' \\\ \hline"`nline'
`type' "\endhead"`nline'
`type' "\hline"`nline'
`type' "\multicolumn{`a6'}{r}{\emph{`footlong'}}\\\"`nline'
`type' "\endfoot"`nline'
`type' "\endlastfoot"`nline'
}

tokenize "`varlist'"
local l=0
while "`1'" !="" {
			local l=`l'+1
			mac shift
			}

local i=1
while `i'<=`l' {
			if "`par'"!="" {
						local op="("
						}
			if "`par'"!="" {
						local fp=")"
						}
			tokenize "`varlist'"
			local nom="``i''"
			qui su `nom' if `touse'  [`weight' `exp']
			if "`labels'"!="" {
						local lab : variable label ``i''
						if "`lab'"!="" {
								    local nom="\`lab'"
									}
						}
		
			***************************
			*LaTeX special characters
			**************************
			if "`nocheck'"=="" {
							latres ,name(`nom')
							local nom="$nom"
							}
			****************************

			local mean=round(r(mean), `nbdec')
			local sd=round(sqrt(r(Var)), `nbdec')
			if substr("`mean'",1,1)=="." {
								local mean="0`mean'"
								}
			if substr("`mean'",1,2)=="-." {
								local pb=substr("`mean'",3,.)
								local mean="-0.`pb'"
								}
			if substr("`sd'",1,1)=="." {
								local sd="0`sd'"
								}
			parse "`mean'", parse(.)
			local mean="$_1"+"$_2"+substr("$_3",1,`digits')
			parse "`sd'", parse(.)
			local sd="$_1"+"$_2"+substr("$_3",1,`digits')
			local N`i'=r(N)
			if `N`i''==0  {
					   local mean="`na'"
					   local sd="`na'"
					   local op=""
					   local fp=""
					  }
			if `N`i''==1  {
						local sd="`na'"
						local op=""
						local fp=""
						}
			local min=round( r(min), `nbdec')
			if substr("`min'",1,1)=="." {
								local min="0`min'"
								}
			if substr("`min'",1,2)=="-." {
								local pb=substr("`min'",3,.)
								local min="-0.`pb'"
								}
			parse "`min'", parse(.)
			local min="$_1"+"$_2"+substr("$_3",1,`digits')
			local max=round( r(max), `nbdec')
			if substr("`max'",1,1)=="." {
								local max="0`max'"
								}
			if substr("`max'",1,2)=="-." {
								local pb=substr("`max'",3,.)
								local max="-0.`pb'"
								}
			parse "`max'", parse(.)
			local max="$_1"+"$_2"+substr("$_3",1,`digits')
			if `N`i''==0  {
					   local min="`na'"
					   local max="`na'"
						}
			if "`minmax'"!="" {
						local extr="& `min' & `max'"
						}
			if "`nobs'"!="" {
						local taille=" & `N`i''"
						}
			local ligne="\`nom' & `mean' & `op'`sd'`fp' `extr' `taille'"
			**************************
			* Displaying table lines
			**************************
			`type' "`ligne'\\\"`nline'
			local i=`i'+1
		}



if "`nobs'"!="" {
			`type' "\hline"
			}


local N=r(N)
if "`nobs'"=="" {
			`type' "\multicolumn{1}{c}{N} & \multicolumn{`a3'}{c}{`N'}\""\\"  " \hline"
			}

if "`longtable'"==""{
				`type' "\end{tabular}"
if "`notableenv'"==""{
`type' _newline "\end{table}"
}
}

if "`longtable'"!=""{
				`type' "\end{longtable}"_newline "\end{center}"			}






if "`file'"!="" {
			`type' ""_n
			}
if "`file'"=="" {
			`type'  "%------- End LaTeX code -------%"`nline'
			}
if "`file'"!="" {
			file close `fich'
			}

macro drop ligne*
macro drop nom 
if "`file'"!="" {
			di `"file {view "`file'"} saved"'
			}

end




***************************************************
*LaTeX special characters search and replace routine
***************************************************

cap prog drop latres
program define latres
version 7.0
syntax ,name(string) [sortie(string) nom]
if "`sortie'"=="" {
			local sortie="nom"
			}

local cr1="_" 
local crc1="\_"
local cr2="\"
local crc2="$\backslash$ "
local cr3="$"
local crc3="\symbol{36}"
local cr4="{"
local crc4="\{"
local cr5="}"
local crc5="\}"
local cr6="%"
local crc6="\%"
local cr7="#"
local crc7="\#"
local cr8="&"
local crc8="\&"
local cr9="~"
local crc9="\~{}"
local cr10="^"
local crc10="\^{}"
local cr11="<"
local crc11="$<$ "
local cr12=">"
local crc12="$>$ "

local nom="`name'"

			local t=length("`nom'")
			local rg=1
			local mot2=""
			while `rg'<=`t' {
						local let`rg'=substr("`nom'",`rg',1)
						local num=1
						while `num'<=12 {
									if "`let`rg''"=="`cr`num''" {
														local let`rg'="`crc`num''"
														}
									local num=`num'+1
									}
						if "`let`rg''"=="" {
										local mot2="`mot2'"+" " 
										}
						else if "`let`rg''"!="" {
											local mot2="`mot2'"+"`let`rg''"
										}		
						local rg=`rg'+1
						}
						
			global `sortie'="`mot2'"
end
