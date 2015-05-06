*! version 1.2 Brian Quistorff <bquistorff@gmail.com>
*! Passthrough command allowing one to use the -ereturn- cmds easily.
* Usage: ereturn_do local l1 yes
* Usage: ereturn_do matrix y = y, copy
/* Notes for "post": 1) you need colnames(V)=rownames(V)=colnames(b)
					2) the supplied matrices are moved, not copied
	*Example:
	. mat b = (1,2)
	. mat V = (1, 0 \ 0, 1)
	. mat rownames V = `: colnames V'
	. ereturn_do post b V
*/
* For -eststo- need to specify b
* For -est store- need: b and the macro 'cmd'
program ereturn_do, eclass
	version 11.0
	* Version requirement is conservative.
	syntax anything(equalok everything) [, *]
	if "`options'"!="" loc options `", `options'"'
	ereturn `anything' `options'
end
