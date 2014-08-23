*! Version 1.0
*! This will collapse the dataset and preserve the variable and value labels. 
*! The syntax for using this is just like with the collapse command.
*! There is one additional optional option: show stat. If you add this option to the command (collapseandperserve ... ,by(...) omitstatfromvarlabel
*!     then it will not show the statistic (i.e. (fist), (mean), (last), etc.) in the variable label

* From: http://shafiquejamal.blogspot.com/2012/11/stata-tip-collapse-dataset-while.html
* Written by Shafique Jamal (shafique.jamal@gmail.com).

program define collapseandpreserve

    syntax anything(id="variable and values" name=arguments equalok) [fweight  aweight  pweight  iweight], by(string asis) [cw fast Omitstatfromvarlabel]
    version 9.1
    
    // save all the value labels
    tempfile tf
    qui label save using `"`tf'"', replace
    
    // get the list of variables to be collapse, and keep track of the value label - variable correspondence 
    tempname precollapse_listofvars postcollapse_listofvars listofvaluelabels valuelabelname stat oldvarname newvarname
    local `stat' "(mean)"
    foreach a of local arguments {
        *di `"word: `a'"'
        if (regexm(`"`a'"',"^\(.*\)$")) { // if there is something like (first), (mean), etc.
            local `stat' = `"`a'"'    
        } 
        else { // This is a variable. Store the associated variable label and value label name
            
            // What if there is an = in the term? then need two list of variables: a precollapse list and a postcollapse list
            if (regexm(`"`a'"',"^(.*)=(.*)$")) {
                local `oldvarname' = regexs(2)
                local `newvarname' = regexs(1)
                // di "Regex match! oldvarname: ``oldvarname''. newvarname: ``newvarname''"
            }
            else {
                local `oldvarname' `"`a'"'
                local `newvarname' `"`a'"'
                // di "NO regex match! oldvarname: ``oldvarname''. newvarname: ``newvarname''"
            }
            
            local `precollapse_listofvars'   `"``precollapse_listofvars'' ``oldvarname''"'
            local `postcollapse_listofvars'   `"``postcollapse_listofvars'' ``newvarname''"'
            local `valuelabelname' : value label ``oldvarname''
            tempname vl_``newvarname''
            local `vl_``newvarname''' : variable label ``oldvarname''
            if (`"``vl_``newvarname''''"' == `""') {
                local `vl_``newvarname''' `"``newvarname''"'
            }
            *di `"omitstatfromvarlabel = `omitstatfromvarlabel'"'
            if (`"`omitstatfromvarlabel'"'==`""') {
                local `vl_``newvarname''' `"``stat'' ``vl_``newvarname''''"'
                *di "not omitting"
            }
            else {
                local `vl_``newvarname''' `"``vl_``newvarname''''"'
                *di "omitting"
            }
            
            if (`"``valuelabelname''"' == `""') { // variable has no value label
                local `listofvaluelabels' `"``listofvaluelabels'' ."'
            }
            else {
                local `listofvaluelabels' `"``listofvaluelabels'' ``valuelabelname''"'
            }
        }
    }
    *di "`weight'`exp'"
    collapse `arguments' [`weight'`exp'], by(`by') `cw' `fast'
    // macro list
    
    // retrieve the valuelabels
    qui do `"`tf'"'
    
    // reapply the variable labels and the value labels
    tempname count
    local `count' = 0
    *di "------------------------------------------------"
    foreach var of local `postcollapse_listofvars' {
        *di `"var: `var'"'
        *di `"its variable label: ``vl_`var'''"'
        // reapply the variable labels
        local `count' = ``count'' + 1
        label var `var' `"``vl_`var'''"'
        
        // reapply the value labels
        local `valuelabelname' : word ``count'' of ``listofvaluelabels''
        if (`"``valuelabelname''"' != `"."') {
            label values `var' ``valuelabelname''
        }
    }
end program
