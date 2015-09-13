*! version 0.0.7  Jens Hainmueller 01/26/2014
*! version 0.0.7-bq Brian Quistorff 2014-02 
* 	-output the unrounded weights plus some other convenience vars. 
*   -Don't leave mats lying around
*   -make a bit faster by speeding up averaging, removing some checks, and not calling tsset redudantly
* To do: 
*  -fix so that the Ybal doesn't include pretreament (Zbal) when the not putting in resultsperiod and mspeperiod.
*  -If unitsnames included then it loops through all levels of pvar, make that faster.
*  -Fix up the V matrix when dropping vars?
*
program synth2 , eclass
	version 9.2
	preserve

	/* check if data is tsset with panel and time var */
	tsset, noquery
	local tvar `r(timevar)'
	local pvar "`r(panelvar)'"
	
	_assert "`tvar'"!="",  msg("panel unit variable missing please use -tsset panelvar timevar-") rc(198)
	_assert "`pvar'"!= "", msg("panel time variable missing please use -tsset panelvar timevar-") rc(198)

	/* obtain settings */
	syntax anything , ///
		TRUnit(numlist min=1 max=1 int sort) ///
		TRPeriod(numlist min=1 max=1 int sort) ///
		[ COUnit(numlist min=2 int sort)  ///
		counit_ind(varlist max=1 string) ///
		xperiod(numlist min=1 >=0 int sort) ///
		mspeperiod(numlist  min=1 >=0 int sort) ///
		resultsperiod(numlist min=1 >=0 int sort) ///
		unitnames(varlist max=1 string) ///
		FIGure ///
		Keep(string) ///
		REPlace ///
		customV(numlist) ///
		margin(real 0.005) ///
		maxiter(integer 1000) ///
		sigf(integer 12) ///
		bound(integer 10) ///
		nested ///
		allopt ///
		skipchecks ///
		* ///
		]


	/* Define Tempvars and speperate Dvar and Predcitors */
	tempvar Xco Xcotemp Xtr Xtrtemp Zco Ztr Yco Ytr subsample misscheck conlabel

	/* Check User Inputs  ************************* */

	qui levelsof `pvar',local(levp)
	
	loc checkinput: list trunit in levp
	_assert `checkinput' != 0, msg("treated unit not found in panelvar - check tr()") rc(198)


	/* if the panel vars has labels grab it */
	local clab: value label `pvar'
	/* if unitname specified, grab the label here */
	if "`unitnames'" != "" {
		capture confirm string var `unitnames'
		_assert !_rc, msg("`unitnames' does not exist as a (string) variable in dataset") rc(198)

		/* check if it has a value for all units */
		tempvar pcheck1 pcheck2
		qui egen `pcheck1' = max(`pvar') , by(`unitnames')
		qui egen `pcheck2' = min(`pvar') , by(`unitnames')
		qui count if `pcheck1'!=`pcheck2'
		_assert r(N)==0, msg("`unitnames' varies within units of `pvar' - revise unitnames variable ") rc(198)

		local clab "`pvar'"
		tempvar index
		gen `index' = _n
		/* now label the pvar accoringly */
		foreach i in `levp' {
			qui su `index' if `pvar' == `i', meanonly
			local label = `unitnames'[`r(max)']
			local value = `pvar'[`r(max)']
			qui label define `clab' `value' `"`label'"', modify
		}
		label value `pvar' `clab'
	}

	if "`clab'" != "" {
		local tlab: label `clab' `trunit' , strict
	}

	/* Produce initial output **************************** */
	di as txt "{hline}" _newline as res "Synthetic Control Method for Comparative Case Studies"
	di as txt "{hline}" _newline(2) as res "First Step: Data Setup" _newline as txt "{hline}"

	/* Build pre-treatment period */
	qui levelsof `tvar', local(levt)
	loc checkinput: list trperiod in levt
	_assert `checkinput'!=0, msg("period of treatment is not found in timevar - check trperiod()") rc(198)

	/* by default minmum of time var up to intervention (exclusive) is pre-treatment period */
	qui levelsof `tvar' if `tvar' < `trperiod' , local(preperiod)

	/* now if not supplied fill in xperiod (time period over which all predictors are averaged) */
	if "`xperiod'" == "" {
		numlist "`preperiod'" , min(1) integer sort
		local xperiod "`r(numlist)'"
	}
	else {
		loc checkinput: list xperiod in levt
		_assert `checkinput'!=0, msg("at least one time period specified in xperiod() not found in timevar") rc(198)
	}

	/* now if not supplied fill in mspeperiod (time period over which all loss is minimized are averaged) */
	if "`mspeperiod'" == "" {
		numlist "`preperiod'" , min(1) integer sort
		local mspeperiod "`r(numlist)'"
	}
	else {
		loc checkinput: list mspeperiod in levt
		_assert `checkinput'!=0, msg("at least one time period specified in mspeperiod() not found in timevar") rc(198)
	}

	if "`resultsperiod'" == "" {
		numlist "`levt'" , min(1) integer sort
		local resultsperiod "`r(numlist)'"
	}
	else {
		loc checkinput: list resultsperiod in levt
		_assert `checkinput'!=0, msg("at least one time period specified in resultsperiod() not found in timevar") rc(198)
	}

	/* get depvars */
	_assert "`anything'"!="", msg("not a single variable specified. please supply at least a response variable") rc(198)
	gettoken dvar anything: anything
	capture confirm numeric var `dvar'
	_assert !_rc, msg("`dvar' does not exist as a (numeric) variable in dataset") rc(198)

	/* Get treated dep matrices ************************************************* */
	agdvar `Ztr' , cvar(`dvar') timeno(`mspeperiod') unitno(`trunit') sub(`subsample') ///
		tlabel("pre-intervention MSPE period - check mspeperiod()") ///
		ulabel("treated unit") trorco("treated") pvar(`pvar') tvar(`tvar') `skipchecks'

	agdvar `Ytr' , cvar(`dvar') timeno(`resultsperiod') unitno(`trunit') sub(`subsample') ///
		tlabel("results period - check resultsperiod()") ///
		ulabel("treated unit") trorco("treated") pvar(`pvar') tvar(`tvar') `skipchecks'
		
		
	global bslack : tempvar
	mat $bslack = 1
	local displ_amount 2 //2=FLOOD, 1=STATUS, 0=QUIET
	local restart 0 //This produces almost the same result as stock synth
	
	*Get control unit markers
	_assert "`counit'"=="" | "`counit_ind'"=="", msg("Can't specify both counit_ind and counit") rc(198)
	if "`counit_ind'"==""{
		tempvar counit_ind counit_ind_orig
		if "`counit'"==""{
			local counit : subinstr local levp "`trunit'" " ", all word
			gen byte `counit_ind' = (`pvar'!=`trunit')
		}
		else{
			_assert `: list counit in levp'!=0, msg("at least one control unit not found in panelvar - check co()") rc(198)
			qui gen byte `counit_ind' =  0 
			foreach cux of numlist `counit' {
				qui replace `counit_ind'=1 if `pvar'==`cux'
			}
		}
		gen byte `counit_ind_orig' = `counit_ind'
	}
	else{
		local counit_ind_orig = `counit_ind'
		tempvar counit_ind
		gen byte `counit_ind' = `counit_ind_orig'
		qui levelsof `pvar' if `counit_ind',local(counit)
	}
	local counit_orig `counit'
	_assert `: list trunit in counit'!=1, msg("treated unit appears among control units  - check co() and tr()") rc(198)
	
	local predictors_orig `anything'
	local predictors `predictors_orig'
	
	tempname mat_0
	tempvar counitno wsolout wsolout_unr
	while(1){ //optimize passes
		* Construct info for control units and predictors and then optimize
		* If optimization needs to remove some, redo the pass

		if "`clab'" != "" {
			local colabels ""
			foreach i in `counit' {
				local label : label `clab' `i'
				local colabels `"`colabels', `label'"'
			}
			local colabels : list clean colabels
			local colabels : subinstr local colabels "," ""
			local colabels : list clean colabels
		}
		
		/* Create X matrices */
		local trno : list sizeof trunit
		local cono : list sizeof counit

		/* for now we assume that the user used blanks only to seperate variables */
		/* thus we have p predictors */

		/* *************************** */
		/* begin variable construction   */
		cap mat drop `Xtr' `Xco'
		local predictors_left `predictors'
		local predictors_used ""
		while "`predictors_left'" != "" {
			gettoken p predictors_left: predictors_left , bind

			/* check if there is a paranthesis in token */
			local whereq = strpos("`p'", "(")
			if `whereq' == 0 {
				/* if not, token is just a varname */
				capture confirm numeric var `p'
				_assert !_rc, msg("`p' does not exist as a (numeric) variable in dataset") rc(198)

				local var "`p'"
				local xtime_orig ""
				local xtime "`xperiod'"
				/* set empty label for regular time period */
				local xtimelab ""

			} /* if yes, token is varname plus time, so try to disentagngle the two */
			else {
				/* get var */
				local var = substr("`p'",1,`whereq'-1)
				qui capture confirm numeric var `var'
				_assert !_rc, msg("`var' does not exist as a (numeric) variable in dataset") rc(198)
				/* get time token  */
				local xtime = substr("`p'",`whereq'+1,.)
				local xtime_orig = "(`xtime'"

				/* save time token to use for label */
				local xtimelab `xtime'
				local xtimelab : subinstr local xtimelab " " "", all

				/* now check wheter this is a second paranthsis */
				local wherep = strpos("`xtime'", "(")
				/* if no, delete a potential & and done */
				if `wherep' == 0 {
					local xtime : subinstr local xtime "&" " ", all
					local xtime : subinstr local xtime ")" " ", all
				} /* if yes, this is a numlist so we remove both paranthesis, but put the first one back in */
				else {
					local xtime : subinstr local xtime ")" " ", all
					local xtime : subinstr local xtime " " ")"
				}
				numlist "`xtime'" , min(1) integer sort
				local xtime "`r(numlist)'"

				_assert (`: list xtime in levt'!=0), msg("for predictor `var' some specified periods are not found in panel timevar") rc(198)
			}

			/* now go an do averaging over xtime period for variable var   */
			local num_xtime : word count `xtime'

			/* Controls *************************** */
			if `num_xtime'==1 {
				*If no variation in donor then skip
				summ `var' if `counit_ind'     & `tvar'==`xtime', meanonly
				if r(min)==r(max){
					continue, break
				}
				
				mkmat `var' if `counit_ind'     & `tvar'==`xtime', matrix(`Xcotemp') rownames(`pvar')
				mkmat `var' if `pvar'==`trunit' & `tvar'==`xtime', matrix(`Xtrtemp') rownames(`pvar')
			}
			else {
				/* Define Subsample (just control units and periods from xtime() ) */
				qui reducesample , tno("`xtime'") genname(`subsample') tvar(`tvar') pvar(`pvar') u_ind(`counit_ind')
				if "`skipchecks'"==""{
					missingchecker , tno("`xtime'") cvar("`var'") sub("`subsample'") ///
						ulabel("control units") checkno(`cono') tilab("`xtimelab'") tvar(`tvar')
				}
				cap noisily agmat `Xcotemp' , cvar(`var') sub(`subsample') ulabel("control units") ///
					checkno(`cono') tilab("`xtimelab'") pvar(`pvar') stopifsame
				if _rc==2{
					qui drop `subsample'
					continue, break
				}
				qui drop `subsample'
				
				/* Now treated ***************************** */
				
				/* Define subsample just treated unit and xtime() periods */
				qui reducesample , tno("`xtime'") uno("`trunit'") genname(`subsample') tvar(`tvar') pvar(`pvar')
				if "`skipchecks'"==""{
					missingchecker , tno("`xtime'") cvar("`var'") sub("`subsample'") ///
						ulabel("treated unit") checkno(`trno') tilab("`xtimelab'") tvar(`tvar')
				}
				agmat `Xtrtemp' , cvar(`var') sub(`subsample') ulabel("treated unit") checkno(`trno') tilab("`xtimelab'") pvar(`pvar')
				qui drop `subsample'
			}
			local predictors_used "`predictors_used' `var'`xtime_orig'"

			/* finally name matrices and done  */
			if "`xtimelab'" == "" {
				mat coln `Xcotemp' = "`var'"
				mat coln `Xtrtemp' = "`var'"
			}
			else {
				mat coln `Xcotemp' = "`var'(`xtimelab'"
				mat coln `Xtrtemp' = "`var'(`xtimelab'"
			}

			mat `Xtr' = nullmat(`Xtr'),`Xtrtemp'
			mat `Xco' = nullmat(`Xco'),`Xcotemp'
		} /* close while loop through predictor string, varibale construction is done */
		local predictors_dropped : list predictors - predictors_used
		if "`predictors_dropped'"!="" di "Dropping predictors with no donor variation: `predictors_dropped'"
		local predictors `predictors_used' //for next time
	

		/* Get control dep matrix for controls ************************************************* */
		agdvar `Yco' , cvar(`dvar') timeno(`resultsperiod') unitno(`counit') sub(`subsample') ///
			tlabel("results period - check resultsperiod()") ///
			ulabel("control units") trorco("control") pvar(`pvar') tvar(`tvar') unit_ind(`counit_ind') `skipchecks'
			
		agdvar `Zco' , cvar(`dvar') timeno(`mspeperiod') unitno(`counit') sub(`subsample') ///
			tlabel("pre-intervention MSPE period - check mspeperiod()") ///
			ulabel("control units") trorco("control") pvar(`pvar') tvar(`tvar') unit_ind(`counit_ind') `skipchecks'

		/* rownames for final X matrixes  */
		mat rown `Xco' = `counit'
		mat rown `Xtr' = `trunit'

		/* transpose for optimization */
		mat `Xtr' = (`Xtr')'
		mat `Xco' = (`Xco')'


		di as txt "{hline}" _newline "Data Setup successful"  _newline "{hline}"
		if "`clab'" != "" {
			di "{txt}{p 16 28 0} Treated Unit: {res}`tlab' {p_end}"
			*di "{txt}{p 15 30 0} Control Units: {res}`colabels' {p_end}" //can be really long
		}
		else {
			di "{txt}{p 16 28 0} Treated Unit: {res}`trunit' {p_end}"
			*di "{txt}{p 15 30 0} Control Units: {res}`counit' {p_end}" //can be really long
		}
		di as txt "{hline}"
		di "{txt}{p 10 30 0} Dependent Variable: {res}`dvar' {p_end}"
		di "{txt}{p 2 30 0} MSPE minimized for periods: {res}`mspeperiod'{p_end}"
		di "{txt}{p 0 30 0} Results obtained for periods: {res}`resultsperiod'{p_end}"
		di as txt "{hline}"
		local prednames : rownames `Xco'
		di "{txt}{p 18 30 0} Predictors:{res} `prednames'{p_end}"
		di as txt "{hline}"
		di "{txt}{p 0 30 0} Unless period is specified {p_end}"
		di "{txt}{p 0 30 0} predictors are averaged over: {res}`xperiod'{p_end}"

		/* now go to optimization */
		/* ***************************************************************************** */
		di as txt "{hline}" _newline(2) as res "Second Step: Run Optimization"  _newline as txt "{hline}"

		/* Dataprep finished. Starting optimisation */
		tempname sval V

		/* save vars for output */
		mat `Xtrtemp' = `Xtr'
		mat `Xcotemp' = `Xco'

		/* normalize the vars */
		mata: normalize("`Xtr'","`Xco'")
		mat `Xtr' = xtrmat
		mat `Xco' = xcomat
		/* Set up V matrix */
		if "`customV'" == "" {
			/* If no custom V is provided go get Regression based V weights */
			mata: regsval("`Xtr'","`Xco'","`Ztr'","`Zco'")
			mat `V' = vmat

		}
		else {
			di as txt "Using user supplied custom V-weights" _newline "{hline}"

			local checkinput : list sizeof customV
			_assert `checkinput'==rowsof(`Xtr'), msg("wrong number of custom V weights; please specify one V-weight for each predictor") rc(198)

			mat input `sval' = (`customV')
			mata: normweights("`sval'")
			mat `V' = matout
		}


		/* now go into optimization */

		/* now if the user wantes the full nested method, go and get Vstar via nested method  */
		if "`nested'" == "nested" {

			di "{txt}{p 0 30 0} Nested optimization requested {p_end}"

			/* parse the ml optimization options */
			/* retrieve optimization options for ml */
			mlopts std , `options'
			/* if no technique is specified insert our default */
			if "`s(technique)'" == "" {
				local technique "tech(nr dfp bfgs)"
				local std : list std | technique
			}

			/*   /* if no iterations are specified insert our default */
			local std : subinstr local std "iterate" "iterate", count(local isinornot)
			if `isinornot' == 0 {
			local iterate " iterate(100)"
			local std : list std | iterate
			} */

			/* check wheter user has specified any of the nrtol options */
			/* 1. check if shownrtolernace is used */
			local std : subinstr local std "shownrtolerance" "shownrtolerance", count(local shownrtoluser)
			_assert `shownrtoluser'==0, msg("maximize option shownrtolerance cannot be used with synth") rc(198)

			/* 2. check if own ntolernace level is specified  */
			local std : subinstr local std "nrtolerance(" "nrtolerance(", count(local nrtoluser)

			/* 3. check if nontolernace level is specified  */
			local std : subinstr local std "nonrtolerance" "nonrtolerance", count(local nonrtoluser)

			/* delete difficult if specified*/
			local std : subinstr local std "difficult" " ", all

			/* refine input matrices for ml optimization as globals so that lossfunction can find them */
			/* maybe there is a better way to do this */
			global Xco : tempvar
			global Xtr : tempvar
			global Zco : tempvar
			global Ztr : tempvar
			mat $Xco = `Xco'
			mat $Xtr = `Xtr'
			mat $Zco = `Zco'
			mat $Ztr = `Ztr'

			/* set up the liklihood model for optimization */
			/* since we optimize on matrices, we need to trick */
			/* ml and first simulate a dataset with correct dimensions */
			qui drop _all
			qui matrix pred = matuniform(rowsof(`V'),rowsof(`V'))
			/*  now create k articifical vars names pred1, pred2,... */
			qui svmat  pred

			/* get regression based V or user defined V as initial values */
			tempname bini
			mat `bini' = vecdiag(`V')

			/* Run optimization */
			tempname lossreg svalreg
			di "{txt}{p 0 30 0} Starting nested optimization module {p_end}"
			qui wrapml , lstd(`std') lbini("`bini'") lpred("pred*") lnrtoluser(`nrtoluser') lnonrtoluser(`nonrtoluser') lsearch("off")
			di "{txt}{p 0 30 0} Optimization done {p_end}"
			scalar define `lossreg' = e(lossend)
			mat `sval' = e(sval)

			/* Now if allopt is specified then rerun optimization using ml search svals, and equal weights */
			if "`allopt'" == "allopt" {

				di "{txt}{p 0 30 0} Allopt requested. This may take a while{p_end}"

				/* **** */
				/* optimize with serach way of doing initial values  */
				tempname losssearch svalsearch
				di "{txt}{p 0 30 0} Restarting nested optimization module (search method) {p_end}"
				qui wrapml , lstd(`std') lbini("`bini'") lpred("pred*") lnrtoluser(`nrtoluser') lnonrtoluser(`nonrtoluser') lsearch("on")
				di "{txt}{p 0 30 0} done{p_end}"
				scalar define `losssearch' = e(lossend)
				mat `svalsearch' = e(sval)

				/* **** */
				/* optimize with equal weights way of doing initial values  */
				/* get equal weights */
				mat `bini' = vecdiag(I(rowsof(`V')))
				/* run opt */
				tempname lossequal svalequal
				di "{txt}{p 0 30 0} Restarting nested optimization module (equal method) {p_end}"
				qui wrapml , lstd(`std') lbini("`bini'") lpred("pred*") lnrtoluser(`nrtoluser') lnonrtoluser(`nonrtoluser') lsearch("off")
				di "done"
				scalar define `lossequal' = e(lossend)
				mat `svalequal' = e(sval)

				/* **** */
				/* Done with allopts optimization */

				/* now make a decision which loss is lowest. firt reg vs equal, then minimum vs search */
				if( `lossreg' < `lossequal' ) {
					mat `sval' = `svalequal'
					qui scalar define `lossreg' = `lossequal'
				}
				if( `lossreg' < `losssearch' ) {
					mat `sval' = `svalsearch'
				}

			}

			/* now get Vstar vector, normalize once again and create final diag Vstar */
			mata: getabs("`sval'")
			mat `sval' = matout
			mat `V' = diag(`sval')
		}

		/* now go get W, conditional on V (could be Vstar, regression V, or customV) */

		/* Set up quadratic programming */
		tempname H c A l u wsol wsol_unr
		mat `H' =  (`Xco')' * `V' * `Xco'
		mat `c' = (-1 * ((`Xtr')' * `V' * `Xco'))'
		assert `cono'==rowsof(`c')
		mat `A' = J(1,`cono',1)
		mat `l' = J(`cono',1,0)
		mat `u' = J(`cono',1,1)
		matrix `wsol' = J(`cono',1,.)

		/* do quadratic programming step  */
		cap plugin call synth2opt , `c' `H'  `A' $bslack `l' `u' `bound' `margin' `maxiter' `sigf' `wsol' `displ_amount' `restart' _ret_code
		if _rc>0 exit _rc

		/* round */
		mat `wsol_unr' = `wsol'
		mata: roundmat("`wsol'")
		mat `wsol' = matout

		/* organize W matrix for display */
		mat input `counitno' = (`counit')
		mat `counitno' = (`counitno')'
		mat `wsolout' =  `counitno' , `wsol'
		mat `wsolout_unr' =  `counitno' , `wsol_unr'
		
		if(`ret_code'!=20) continue, break
		
		di "Optimization dropped a variable. Restarting with donors with correct value. That var will get dropped."
		*save the unit #s of those that have 0 weight
		mata: wsolout = st_matrix("`wsolout'")
		mata: wsolout_0 = select(wsolout,wsolout[,2]:==0)
		mata: x = invtokens(strofreal(wsolout_0[,1]'))
		tempname w0
		mata: st_matrix("`w0'", wsolout_0)
		mata: st_local("co_to_remove", x)
		foreach cux of local co_to_remove{
			qui replace `counit_ind'=0 if `pvar'==`cux'
		}
		local counit : list counit - co_to_remove
		mat `mat_0' = nullmat(`mat_0') \ `w0'
	}
	
	tempname wsol_final
	mat `wsol_final' = `wsol'
	cap confirm matrix `mat_0'
	if !_rc{ //append the 0 matrix to the weights, and resort.
		mat `wsolout' = `wsolout' \ `mat_0'
		mat `wsolout_unr' = `wsolout_unr' \ `mat_0'
		mata: st_matrix("`wsolout'",sort(st_matrix("`wsolout'"),1))
		mata: st_matrix("`wsolout_unr'",sort(st_matrix("`wsolout_unr'"),1))
		mat `wsol' = `wsolout'[1...,2]
		mat `wsol_unr' = `wsolout_unr'[1...,2]
	}
	mat colname `wsolout' = "_Co_Number" "_W_Weight"
	mat colname `wsolout_unr' = "_Co_Number" "_W_Weight"
	
	qui svmat   `wsolout' , names(col)
	tempname Xbal Zbal Ybal loss Xsynth Ysynth Zsynth gap Xtr_norm Xco_norm

	/* play back original X */
	mat `Xtr_norm' = `Xtr'
	mat `Xco_norm' = `Xco'
	mat rowname `Xtr_norm' = `: rownames `Xtrtemp''
	mat colname `Xtr_norm' = `: colnames `Xtrtemp''
	mat rowname `Xco_norm' = `: rownames `Xcotemp''
	mat colname `Xco_norm' = `: colnames `Xcotemp''
	mat `Xtr' = `Xtrtemp'
	mat `Xco' = `Xcotemp'

	/* Compute loss and transform to RMSPE */
	mat `Zsynth' = `Zco' * `wsol_final'
	mat `Zbal' = `Ztr' ,  `Zsynth'
	mat colname `Zbal' = "Treated" "Synthetic"

	mat `loss' = (`Ztr' - `Zsynth')' * ( `Ztr' - `Zsynth' )
	mat `loss' = `loss' / rowsof(`Ztr')
	mata: roottaker("`loss'")
	mat rowname `loss' = "RMSPE"


	/* *************************************** */
	/* Organize output */
	di as txt "{hline}" _newline as res "Optimization done" _newline as txt "{hline}"
	di as res _newline "Third Step: Obtain Results" _newline as txt "{hline}"
	di as res "Loss: Root Mean Squared Prediction Error"
	matlist `loss' , tw(8) names(rows) underscore lines(rows) border(rows)
	di as txt "{hline}" _newline as res "Unit Weights:"

	/* Display either with or without colum names *********** */
	label var _Co_Number "Co_No"
	label values _Co_Number `clab'
	label var _W_Weight "Unit_Weight"
	tabdisp   _Co_Number if _Co_Number~=. ,c(_W_Weight)


	/* Display X Balance */
	mat `Xsynth' = `Xco' * `wsol_final'
	mat `Xbal' = `Xtr' ,  `Xsynth'
	mat colname `Xbal' = "Treated" "Synthetic"

	di as txt "{hline}" _newline as res "Predictor Balance:"
	matlist `Xbal' , tw(30) border(rows)
	di as txt "{hline}"

	/*compute outcome trajectory output */
	mat `Ysynth' = `Yco' * `wsol_final'
	mat `Ybal' = `Ytr' ,  `Ysynth'
	mat colname `Ybal' = "Treated" "Synthetic"

	mat `gap'    = `Ytr' - `Ysynth'

	/* if user wants plot or save */
	if "`keep'" != "" | "`figure'" != "" {

		/* create vars for plotting */
		qui svmat double `Ytr' , names(_Ytreated)
		qui svmat double `Ysynth' , names(_Ysynthetic)
		qui svmat double `gap' , names(_gap)
		/* time variable for plotting */
		tempvar timetemp
		mat input `timetemp' = (`resultsperiod')
		mat `timetemp' = (`timetemp')'
		qui svmat double `timetemp' , names(_time)
		/* rename cosmetics */
		qui rename _Ytreated1   _Y_treated
		qui rename _Ysynthetic1 _Y_synthetic
		qui rename _gap1   _gap
		qui rename _time1  _time
		if "`clab'" != "" {
			qui label var  _Y_treated "`tlab'"
			qui label var  _Y_synthetic  "synthetic `tlab'"
		}
		else {
			qui label var  _Y_treated "treated unit"
			qui label var  _Y_synthetic  "synthetic control unit"
			qui label var _gap "gap in outcomes: treated minus synthetic"
		}
	}

	/* Results Dataset */
	if "`keep'" != "" {
		qui keep _Co_Number _W_Weight _Y_treated _Y_synthetic _time
		qui drop if _Co_Number ==. & _Y_treated==.
		if "`replace'" != "" {
			qui save `keep' , `replace'
		}
		else {
			qui save `keep'
		}
	}

	/* Plot  */
	if "`figure'" == "figure" {
		twoway (line _Y_treated _time, lcolor(black)) (line _Y_synthetic _time, lpattern(dash) lcolor(black)), ytitle("`dvar'") xtitle("`tvar'") xline(`trperiod', lpattern(shortdash) lcolor(black))
	}

	/* Return results */
	qui ereturn clear
	ereturn mat Y_treated   `Ytr'
	ereturn mat Y_synthetic `Ysynth'
	if "`clab'" != "" {
		local colabels : subinstr local colabels " " "", all
		local colabels : subinstr local colabels "," " ", all
		local colabels : list clean colabels
		mat rowname `wsolout' = `colabels'
	}
	else {
		mat rowname `wsolout' = `counit'
	}
	ereturn mat W_weights  `wsolout'
	ereturn mat W_weights_unr `wsolout_unr'
	mat rowname `V' = `prednames'
	mat colname `V' = `prednames'
	ereturn mat V_matrix    `V'
	ereturn scalar RMSPE_scal = `loss'[1,1]
	ereturn mat RMSPE `loss'
	ereturn mat X_balance   `Xbal'
	ereturn mat Ybal `Ybal'
	ereturn mat Zbal `Zbal'

	/* drop global macros */
	macro drop Xtr Xco bslack

	mat drop xcomat xtrmat vmat fmat matout
	cap mat drop emat
	
	*ereturn mat X1    `Xtr'
	*ereturn mat X0    `Xco'
	ereturn mat X1_normalized    `Xtr_norm'
	ereturn mat X0_normalized    `Xco_norm'
	*ereturn mat Z1    `Ztr'
	*ereturn mat Z0    `Zco'

end


/* Subroutines */

/* subroutine reducesample: creates subsample marker for specified periods and units  */
* can specify u_ind variable instead of walking through uno
program reducesample , rclass
	version 9.2
	syntax , tno(numlist >=0 integer) genname(string) tvar(string) pvar(string) [uno(numlist integer) u_ind(string)]
	local tx: subinstr local tno " " ",", all
	/*local ux: subinstr local uno " " ",", all
	 qui gen `genname' = ( inlist(`tvar',`tx') & inlist(`pvar', `ux')) */
	if "`u_ind'"==""{
		qui gen `genname' =  0 
		foreach cux of numlist `uno' {
			qui replace `genname'=1 if inlist(`tvar',`tx') & `pvar'==`cux'
		}
	}
	else{
		qui gen `genname' = inlist(`tvar',`tx') & `u_ind'
	}
end

/* subroutine missingchecker: goes through matrix, checks missing obs and gives informative error */
program missingchecker , rclass
	version 9.2
	syntax , tno(numlist >=0 integer) cvar(string) sub(string) tvar(string) [checkno(string) ulabel(string) tilab(string) ]
	foreach tum of local tno {
		tempvar misscheck
		qui gen `misscheck' = missing(`cvar') if `tvar' == `tum' & `sub' == 1
		qui count if `misscheck' > 0 & `misscheck' !=.
		if `r(N)' > 0 {
			di as input "`cvar'(`ulabel'): for `r(N)' of out `checkno' units missing obs for predictor `cvar'(`tilab' in period `tum' -ignored for averaging"
		}
		qui drop `misscheck'
	}
end

/* subroutine gettabstatmat: heavily reduced version of SSC "tabstatmat" program by Nick Cox */
/*program gettabstatmat
        version 9.2
        syntax name(name=matout)
        local I = 1
        while "`r(name`I')'" != "" {
                local ++I
        }
        local --I
        tempname tempmat
        forval i = 1/`I' {
            matrix `tempmat' = nullmat(`tempmat') \ r(Stat`i')
            local names   `"`names' `"`r(name`i')'"'"'
        }
        matrix rownames `tempmat' = `names'
        matrix `matout' = `tempmat'
end*/

/* subroutine agmat: aggregate x-values over time, checks missing, and returns predictor matrix */
program agmat
	version 9.2
	syntax name(name=finalmat) , cvar(string) sub(string) ulabel(string) checkno(string) pvar(string) ///
	[ tilab(string) stopifsame]

	/*OLD way
	qui tabstat `cvar' if `sub' == 1 , by(`pvar') s("mean") nototal save
	qui gettabstatmat `finalmat'*/
	preserve
	collapse (mean) `cvar' if `sub' == 1, by(`pvar') fast
	*XXX do I care about losing the labels?
	summ `cvar', meanonly
	if ("`stopifsame'"!="") & (r(min)==r(max)){
		exit 2
	}
	mkmat `cvar', matrix(`finalmat')
	if matmissing(`finalmat') {
		qui local checkdimis : display `checkdimis'
		di as err "`ulabel': for at least one unit predictor `cvar'(`tilab' is missing for ALL periods specified"
		exit 198
	}
end

/* subroutine agdvar: aggregates values of outcome varibale over time and returns in transposed form  */
/* has a trorco flag for treated or controls, since different aggregation is used */
program agdvar
	version 9.2
	syntax name(name=outmat) , cvar(string) timeno(numlist >=0 integer) ///
				  unitno(numlist integer) sub(string) tlabel(string) ///
				  ulabel(string) trorco(string) pvar(string) tvar(string) [unit_ind(string) skipchecks]

	/* reduce sample */
	qui reducesample , tno("`timeno'") uno("`unitno'") genname(`sub') tvar(`tvar') pvar(`pvar') u_ind(`unit_ind')
	local tino : list sizeof timeno
	local cono : list sizeof unitno
	if "`skipchecks'"=="" {
		foreach tum of local timeno {
			qui sum `cvar' if `tvar' == `tum' & `sub' == 1 , meanonly
			tempname checkdimis checkdimshould
			qui scalar define `checkdimis' = `r(N)'
			qui scalar define `checkdimshould' = `cono'
			qui scalar define `checkdimis' = `checkdimshould' - `checkdimis'
			if `checkdimis' != 0 {
				qui local checkdimis : display `checkdimis'
				di as err "`ulabel': for `checkdimis' of out `cono' units outcome variable `cvar' is missing in `tum' `tlabel'"
				error 198
			}
		}
	}

	/* aggregate for controls */
	if "`trorco'" == "control" {
		qui mata: switchmat("`pvar'","`cvar'", "`sub'")
		mat `outmat' = fmat
	}
	else {
		/* and for treated */
		qui mkmat `cvar' if `sub' == 1 , matrix(`outmat')
	}
	_assert !matmissing("`outmat'"), msg("`ulabel': outcome variable missing for `tlabel'") rc(198)
	
	mat coln `outmat' = `unitno'
	mat rown `outmat' = `timeno'
	qui drop `sub'
end

/* subroutine to run ml in robust way using difficult and without, plus with or without nrtol */
program wrapml , eclass
	version 9.2
	syntax , lstd(string) lbini(string) lpred(string) lnrtoluser(numlist) lnonrtoluser(numlist) lsearch(string)

	/* add search if specified */
	if "`lsearch'" == "on" {
		local lsearch "search(quietly)"
		local lstd : list lstd | lsearch
	}

	di "started wrapml"
	di "Std is: `lstd'"

	/* in any case we run twice once with and once without difficult specified */
	/* if user specifed any of the nrtol or nortol settings, give him exactly what he wants */
	tempname loss1 sval1 loss2 sval2
	if `lnrtoluser' > 0 | `lnonrtoluser' > 0 {
		di "user did specify nrtol setting"
		di "starting 1. attempt without difficult"
		qui ml model d0 synth2_ll (xb: =  `lpred', noconstant), ///
			crittype(double) `lstd' maximize init(`lbini', copy) nowarning
		mat `sval1' = e(b)
		qui scalar define `loss1' = e(ll)
		di "done, loss is:"
		display `loss1'
		di "starting 2. attempt with difficult"

		/* now rerun with difficult */
		qui ml model d0 synth2_ll (xb: =  `lpred', noconstant), ///
			crittype(double) `lstd' maximize init(`lbini', copy) nowarning difficult
		mat `sval2' = e(b)
		qui scalar define `loss2' = e(ll)
		di "done, loss is:"
		display `loss2'

	}
	else {
		/* if he did not, try first with nrtol then without */
		di "user did not specify nrtol settings"
		di "starting 1. attempt with nrtol and without difficult"
		qui capture ml model d0 synth2_ll (xb: =  `lpred', noconstant), ///
			crittype(double) `lstd' maximize init(`lbini', copy) nowarning
		di "done"
		if _rc { /* if it breaks down we go with */
			di "optimization crashed. trying again with nonrtol and without difficult"
			qui ml model d0 synth2_ll (xb: =  `lpred', noconstant), ///
				crittype(double) `lstd' maximize init(`lbini', copy) nowarning nonrtolerance
			mat `sval1' = e(b)
			qui scalar define `loss1' = e(ll)
			di "done, loss is:"
			display `loss1'
		}
		else { /* if it does not break down, store and go on */
			mat `sval1' = e(b)
			qui scalar define `loss1' = e(ll)
			di "optimization successful. loss is:"
			display `loss1'
		}

		/* now rerun with difficult */
		di "starting 2. attempt with nrtol and with difficult"
		qui capture ml model d0 synth2_ll (xb: =  `lpred', noconstant), ///
			crittype(double) `lstd' maximize init(`lbini', copy) nowarning difficult
		if _rc { /* if it breaks down we go with */
			di "optimization crashed. trying again with nonrtol and with difficult"
			qui ml model d0 synth2_ll (xb: =  `lpred', noconstant), ///
				crittype(double) `lstd' maximize init(`lbini', copy) nowarning nonrtolerance difficult
			mat `sval2' = e(b)
			qui scalar define `loss2' = e(ll)
		}
		else {
			mat `sval2' = e(b)
			qui scalar define `loss2' = e(ll)
			di "done, loss is:"
			display `loss2'
		}
	}

	di "end wrapml: results obtained"
	di "loss1:"
	display `loss1'
	di "loss2:"
	display `loss2'
	di "and svals1 and 2"

	/* now make a decision which reg based loss is lowest */
	tempname sval lossend
	if `loss1' < `loss2' {
		mat `sval' = `sval2'
		qui scalar define `lossend' = `loss2'
	}
	else {
		mat `sval' = `sval1'
		qui scalar define `lossend' = `loss1'
	}

	/* return loss and svals */
	ereturn scalar lossend = `lossend'
	ereturn matrix sval = `sval'

end


/* subroutine quadratic programming (C++ plugin) */
program synth2opt, plugin
