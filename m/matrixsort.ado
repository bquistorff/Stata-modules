*! version 1.0 Brian Quistorff <bquistorff@gmail.com>
*! Sorts a Stata matrix by a column. Fixes problem in -matsort- where row labels with spaces are mangled
*! make sortcol negative if you want descending order
program matrixsort
	version 11.0
	*Just a guess at the version
	
	args matname sortcol
	
	mata: sort_st_matrix("`matname'", `sortcol')
end

mata:
void sort_st_matrix(string scalar matname, real scalar sortcol){
	orig_mat = st_matrix(matname)
	perm = order(orig_mat, sortcol)
	sort_mat = orig_mat[perm,]
	row_l = st_matrixrowstripe(matname)
	sort_row_l = row_l[perm,]
	
	st_replacematrix(matname, sort_mat)
	st_matrixrowstripe(matname, sort_row_l)

}
end
