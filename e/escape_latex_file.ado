program escape_latex_file
	syntax, txt_infile(string) tex_outfile(string)
	
	tempname out_handle in_handle
	file open `out_handle' using "`tex_outfile'", write text replace
	file open  `in_handle' using "`txt_infile'" , read text
	file read `in_handle' line
	while r(eof)==0 {
		escape_latex "`line'", local(line_out)
		if "`notfirst'"=="1" file write `out_handle' _n(2)
		file write `out_handle' "`line_out'"
		
		local notfirst = "1"
		file read `in_handle' line
	}

	
	file close `out_handle'
	file close `in_handle'
end
