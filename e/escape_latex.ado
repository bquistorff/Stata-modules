*! version 1.0
*! Escapes Latex meta-chatacters
*! Watch the backslashes as Stata is a bit uncommon in how it deals with them.
*! For the caret, it requires the textcomp package

* http://stackoverflow.com/questions/2627135/how-do-i-sanitize-latex-input
mata:
/*
 * Do simultaneous charachter replacement
 */
string scalar simultaneous_char_replace(string scalar input, string rowvector tomatch_chars, string rowvector toreplace_strs){
    string scalar output
    
    output = ""
    J = cols(tomatch_chars)
    for(i=1; i<=strlen(input); i++){
        letter = substr(input,i,1)
        
        for(j=1; j<=J; j++){
            if(letter == tomatch_chars[j]){
                output = output+toreplace_strs[j]
                break
            }
        }
        if(j==J+1){
            output = output+letter
        }
    }
    return(output)
}
end
program define escape_latex, sclass
	syntax anything(equalok everything name=input) [, disable_curly]
    
    * These replacements use each other's characters so have to do simultanous replacement (not sequential)
    mata: st_local("input", simultaneous_char_replace(`"`input'"', ("\","{","}"), ("\textbackslash{}","\{","\}")))
    
	local input = subinstr(`"`input'"',"$", "\$", .)
	local input = subinstr(`"`input'"',"&", "\&", .)
	local input = subinstr(`"`input'"',"#", "\#", .)
	local input = subinstr(`"`input'"',"^", "\textasciicircum{}", .)
	local input = subinstr(`"`input'"',"_", "\_", .)
	local input = subinstr(`"`input'"',"~", "\textasciitilde{}", .)
	local input = subinstr(`"`input'"',"%", "\%", .)
    
    *Some for OT1 encoding (but you're not using that, right!)
	local input = subinstr(`"`input'"',"<", "\textless{}", .)
	local input = subinstr(`"`input'"',">", "\textgreater{}", .)
	local input = subinstr(`"`input'"',"|", "\textbar{}", .)
    
    if "`disable_curly'"!=""{
        local input = subinstr(`"`input'"',`"""', "\textquotedbl{}", .)
        local input = subinstr(`"`input'"',"'", "\textquotesingle{}", .)
        local input = subinstr(`"`input'"',"|", "\textasciigrave{}", .)
    }
    
	sreturn local input `"`input'"'
end
