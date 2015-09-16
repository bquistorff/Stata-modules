*Version 0.1 Brian Quistorff <bquistorff@gmail.com>
* Description: Returns the first line that matches the regular expression (or 0)
program find_in_file
	version 12 //guess
	syntax using/, regexp(string) local(string) [start_at_ln(int 0)]
	
	tempname fh
	local linenum = 0
	local line_on = 0
	file open `fh' using `"`using'"', read
	file read `fh' line
	while r(eof)==0 {
			local linenum = `linenum' + 1
			if `linenum'>=`start_at_ln'{
				if regexm(`"`macval(line)'"',`"`regexp'"'){
					local line_on = `linenum'
					continue, break
				}
			}
			file read `fh' line
	}
	file close `fh'
	
	c_local `local' `line_on'
end
