/* subroutine lossfunction: loss function for nested optimization */
program synth_ll
	version 9.2
	args todo b lnf
	tempname loss bb VV H c A l u wsol
	tempvar loss_var loss_final
	*matrix list `b'

	/* get abs constrained weights and create V */
	mata: getabs("`b'")
	mat `bb' = matout
	mat `VV' = diag(`bb')

	/* Set up quadratic programming */
	mat `H' =  ($Xco)' * `VV' * $Xco
	mat `c' = (-1 * (($Xtr)' * `VV' * $Xco))'
	mat `A' = J(1,rowsof(`c'),1)
	mat `l' = J(rowsof(`c'),1,0)
	mat `u' = J(rowsof(`c'),1,1)

	/* Initialize read out matrix  */
	matrix `wsol' = `l'

	/* do quadratic programming step  */
	plugin call synthopt , `c' `H'  `A' $bslack `l' `u' $bd $marg $maxit $sig `wsol'

	/* Compute loss */
	mat `loss' = ($Ztr - $Zco * `wsol')' * ( $Ztr - $Zco * `wsol')
	mat colnames `loss' = `loss_var'
	qui svmat  double `loss' ,names(col)
	qui gen    double `loss_final' = -1 * `loss_var'
	qui mlsum  `lnf'  = `loss_final' if `loss_var' ~=.
	*      sum    `loss_final'
	qui drop   `loss_final' `loss_var'
end

/* subroutine quadratic programming (C++ plugin) */
program synthopt, plugin
