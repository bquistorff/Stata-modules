** Downloaded from http://blogs.worldbank.org/impactevaluations/tools-of-the-trade-doing-stratified-randomization-with-uneven-numbers-in-some-strata
* Example code by Mirian Bruhm and David McKenzie


# delimit ;
*clear all; //EDIT: moved to calling routine
*cap log close;
*set mem 200m;
*use BlogStrataExample.dta, clear;

#delimit ;
* First Generate the Randomization Strata;
egen strata=group(variableA variableB variableC variableD);

* Count how many Strata there are and look at distribution per Strata;
distinct strata;
tab strata;


* ------------- *;
* Randomization *;
* ------------- *;

* First sort the data, assign the random number seed, generate a random number;
* for each unit, and then the rank of this number within each strata;
sort strata obsno;
by strata: gen obs=_N;
*set seed 467; //EDIT: moved to calling routine
gen random2=uniform();
by strata: egen rank2=rank(random2);


* Now start forming treatment groups - beginning with groups divisible by 6;
gen group="";

gen multiples=obs/6;
recast int multiples, force;
gen multiples2=multiples*6;

* since our biggest cellsize is 99 units, dividing this by 6 gives 16 as the; 
* most we can have all 6 treatment and control groups ever get within a strata;
forvalues x=1/16{;
local obs=6*`x';
local rank1=6*`x'-5;
local rank2=6*`x'-4;
local rank3=6*`x'-3;
local rank4=6*`x'-2;
local rank5=6*`x'-1;
local rank6=6*`x';
replace group="Treatment 1" if obs>=`obs' & rank2==`rank1' & rank2<=multiples2;
replace group="Treatment 2" if obs>=`obs' & rank2==`rank2' & rank2<=multiples2;
replace group="Treatment 3" if obs>=`obs' & rank2==`rank3' & rank2<=multiples2;
replace group="Treatment 4" if obs>=`obs' & rank2==`rank4' & rank2<=multiples2;
replace group="Treatment 5" if obs>=`obs' & rank2==`rank5' & rank2<=multiples2;
replace group="Control" if obs>=`obs' & rank2==`rank6' & rank2<=multiples2;
};



* Now allocate the remainders or misfits;
* First generate count of how many remainders there are, and randomly rank them;
#delimit ;
gen residual=obs-multiples2;
gen random4=uniform() if group=="";
by strata: egen rank4=rank(random4);
* here is the key step: generate a single random number per strata, to randomly;
* allocate which extra treatments or control conditions this strata gets;
#delimit ;
gen random5=uniform() if rank4==1;
by strata: egen mrandom5=max(random5);


* Now go through and allocate left over units;
#delimit ;
**Strata with 1 residual observation;

replace group="Treatment 1" if residual==1 & random4<.16666667 & random4~=.;
replace group="Treatment 2" if residual==1 & random4>=.16666667 & random4<.33333333;
replace group="Treatment 3" if residual==1 & random4>=.33333333 & random4<.5;
replace group="Treatment 4" if residual==1 & random4>=.5 & random4<.66666667;
replace group="Treatment 5" if residual==1 & random4>=.66666667 & random4<.83333333;
replace group="Control" if residual==1 & random4>.83333333 & random4~=.;

**Strata with 2 residual observations;

replace group="Treatment 1" if residual==2 & rank4==1 & mrandom5<.06666667 & mrandom5~=.;
replace group="Treatment 2" if residual==2 & rank4==2 & mrandom5<.06666667 & mrandom5~=.;

replace group="Treatment 1" if residual==2 & rank4==1 & mrandom5>=.06666667 & mrandom5<.13333333;
replace group="Treatment 3" if residual==2 & rank4==2 & mrandom5>=.06666667 & mrandom5<.13333333;

replace group="Treatment 1" if residual==2 & rank4==1 & mrandom5>=.13333333 & mrandom5<.2;
replace group="Treatment 4" if residual==2 & rank4==2 & mrandom5>=.13333333 & mrandom5<.2;

replace group="Treatment 1" if residual==2 & rank4==1 & mrandom5>=.2 & mrandom5<.26666667;
replace group="Treatment 5" if residual==2 & rank4==2 & mrandom5>=.2 & mrandom5<.26666667;

replace group="Treatment 1" if residual==2 & rank4==1 & mrandom5>=.26666667 & mrandom5<.33333333;
replace group="Control" if residual==2 & rank4==2 & mrandom5>=.26666667 & mrandom5<.33333333;

replace group="Treatment 2" if residual==2 & rank4==1 & mrandom5>=.33333333 & mrandom5<.4;
replace group="Treatment 3" if residual==2 & rank4==2 & mrandom5>=.33333333 & mrandom5<.4;

replace group="Treatment 2" if residual==2 & rank4==1 & mrandom5>=.4 & mrandom5<.46666667;
replace group="Treatment 4" if residual==2 & rank4==2 & mrandom5>=.4 & mrandom5<.46666667;

replace group="Treatment 2" if residual==2 & rank4==1 & mrandom5>=.46666667 & mrandom5<.53333333;
replace group="Treatment 5" if residual==2 & rank4==2 & mrandom5>=.46666667 & mrandom5<.53333333;

replace group="Treatment 2" if residual==2 & rank4==1 & mrandom5>=.53333333 & mrandom5<.6;
replace group="Control" if residual==2 & rank4==2 & mrandom5>=.53333333 & mrandom5<.6;

replace group="Treatment 3" if residual==2 & rank4==1 & mrandom5>=.6 & mrandom5<.66666667;
replace group="Treatment 4" if residual==2 & rank4==2 & mrandom5>=.6 & mrandom5<.66666667;

replace group="Treatment 3" if residual==2 & rank4==1 & mrandom5>=.66666667 & mrandom5<.73333333;
replace group="Treatment 5" if residual==2 & rank4==2 & mrandom5>=.66666667 & mrandom5<.73333333;

replace group="Treatment 3" if residual==2 & rank4==1 & mrandom5>=.73333333 & mrandom5<.8;
replace group="Control" if residual==2 & rank4==2 & mrandom5>=.73333333 & mrandom5<.8;

replace group="Treatment 4" if residual==2 & rank4==1 & mrandom5>=.8 & mrandom5<.86666667;
replace group="Treatment 5" if residual==2 & rank4==2 & mrandom5>=.8 & mrandom5<.86666667;

replace group="Treatment 4" if residual==2 & rank4==1 & mrandom5>=.86666667 & mrandom5<.93333333;
replace group="Control" if residual==2 & rank4==2 & mrandom5>=.86666667 & mrandom5<.93333333;

replace group="Treatment 5" if residual==2 & rank4==1 & mrandom5>=.93333333 & mrandom5~=.;
replace group="Control" if residual==2 & rank4==2 & mrandom5>=.93333333 & mrandom5~=.;

**Strata with 3 residual observations;

replace group="Treatment 1" if residual==3 & rank4==1 & mrandom5<.05 & mrandom5~=.;
replace group="Treatment 2" if residual==3 & rank4==2 & mrandom5<.05 & mrandom5~=.;
replace group="Treatment 3" if residual==3 & rank4==3 & mrandom5<.5 & mrandom5~=.;

replace group="Treatment 1" if residual==3 & rank4==1 & mrandom5>=.05 & mrandom5<.1;
replace group="Treatment 2" if residual==3 & rank4==2 & mrandom5>=.05 & mrandom5<.1;
replace group="Treatment 4" if residual==3 & rank4==3 & mrandom5>=.05 & mrandom5<.1;

replace group="Treatment 1" if residual==3 & rank4==1 & mrandom5>=.1 & mrandom5<.15;
replace group="Treatment 2" if residual==3 & rank4==2 & mrandom5>=.1 & mrandom5<.15;
replace group="Treatment 5" if residual==3 & rank4==3 & mrandom5>=.1 & mrandom5<.15;

replace group="Treatment 1" if residual==3 & rank4==1 & mrandom5>=.15 & mrandom5<.2;
replace group="Treatment 2" if residual==3 & rank4==2 & mrandom5>=.15 & mrandom5<.2;
replace group="Control" if residual==3 & rank4==3 & mrandom5>=.15 & mrandom5<.2;

replace group="Treatment 1" if residual==3 & rank4==1 & mrandom5>=.2 & mrandom5<.25;
replace group="Treatment 3" if residual==3 & rank4==2 & mrandom5>=.2 & mrandom5<.25;
replace group="Treatment 4" if residual==3 & rank4==3 & mrandom5>=.2 & mrandom5<.25;

replace group="Treatment 1" if residual==3 & rank4==1 & mrandom5>=.25 & mrandom5<.3;
replace group="Treatment 3" if residual==3 & rank4==2 & mrandom5>=.25 & mrandom5<.3;
replace group="Treatment 5" if residual==3 & rank4==3 & mrandom5>=.25 & mrandom5<.3;

replace group="Treatment 1" if residual==3 & rank4==1 & mrandom5>=.3 & mrandom5<.35;
replace group="Treatment 3" if residual==3 & rank4==2 & mrandom5>=.3 & mrandom5<.35;
replace group="Control" if residual==3 & rank4==3 & mrandom5>=.3 & mrandom5<.35;

replace group="Treatment 1" if residual==3 & rank4==1 & mrandom5>=.35 & mrandom5<.4;
replace group="Treatment 4" if residual==3 & rank4==2 & mrandom5>=.35 & mrandom5<.4;
replace group="Treatment 5" if residual==3 & rank4==3 & mrandom5>=.35 & mrandom5<.4;

replace group="Treatment 1" if residual==3 & rank4==1 & mrandom5>=.4 & mrandom5<.45;
replace group="Treatment 4" if residual==3 & rank4==2 & mrandom5>=.4 & mrandom5<.45;
replace group="Control" if residual==3 & rank4==3 & mrandom5>=.4 & mrandom5<.45;

replace group="Treatment 2" if residual==3 & rank4==1 & mrandom5>=.45 & mrandom5<.5;
replace group="Treatment 3" if residual==3 & rank4==2 & mrandom5>=.45 & mrandom5<.5;
replace group="Treatment 4" if residual==3 & rank4==3 & mrandom5>=.45 & mrandom5<.5;

replace group="Treatment 2" if residual==3 & rank4==1 & mrandom5>=.5 & mrandom5<.55;
replace group="Treatment 3" if residual==3 & rank4==2 & mrandom5>=.5 & mrandom5<.55;
replace group="Treatment 5" if residual==3 & rank4==3 & mrandom5>=.5 & mrandom5<.55;

replace group="Treatment 2" if residual==3 & rank4==1 & mrandom5>=.55 & mrandom5<.6;
replace group="Treatment 3" if residual==3 & rank4==2 & mrandom5>=.55 & mrandom5<.6;
replace group="Control" if residual==3 & rank4==3 & mrandom5>=.55 & mrandom5<.6;

replace group="Treatment 2" if residual==3 & rank4==1 & mrandom5>=.6 & mrandom5<.65;
replace group="Treatment 4" if residual==3 & rank4==2 & mrandom5>=.6 & mrandom5<.65;
replace group="Treatment 5" if residual==3 & rank4==3 & mrandom5>=.6 & mrandom5<.65;

replace group="Treatment 2" if residual==3 & rank4==1 & mrandom5>=.65 & mrandom5<.7;
replace group="Treatment 4" if residual==3 & rank4==2 & mrandom5>=.65 & mrandom5<.7;
replace group="Control" if residual==3 & rank4==3 & mrandom5>=.65 & mrandom5<.7;

replace group="Treatment 3" if residual==3 & rank4==1 & mrandom5>=.7 & mrandom5<.75;
replace group="Treatment 4" if residual==3 & rank4==2 & mrandom5>=.7 & mrandom5<.75;
replace group="Treatment 5" if residual==3 & rank4==3 & mrandom5>=.7 & mrandom5<.75;

replace group="Treatment 3" if residual==3 & rank4==1 & mrandom5>=.75 & mrandom5<.8;
replace group="Treatment 4" if residual==3 & rank4==2 & mrandom5>=.75 & mrandom5<.8;
replace group="Control" if residual==3 & rank4==3 & mrandom5>=.75 & mrandom5<.8;

replace group="Treatment 3" if residual==3 & rank4==1 & mrandom5>=.8 & mrandom5<.85;
replace group="Treatment 5" if residual==3 & rank4==2 & mrandom5>=.8 & mrandom5<.85;
replace group="Control" if residual==3 & rank4==3 & mrandom5>=.8 & mrandom5<.85;

replace group="Treatment 4" if residual==3 & rank4==1 & mrandom5>=.85 & mrandom5<.9;
replace group="Treatment 5" if residual==3 & rank4==2 & mrandom5>=.85 & mrandom5<.9;
replace group="Control" if residual==3 & rank4==3 & mrandom5>=.85 & mrandom5<.9;

replace group="Treatment 1" if residual==3 & rank4==1 & mrandom5>=.9 & mrandom5<.95;
replace group="Treatment 5" if residual==3 & rank4==2 & mrandom5>=.9 & mrandom5<.95;
replace group="Control" if residual==3 & rank4==3 & mrandom5>=.9 & mrandom5<.95;

replace group="Treatment 2" if residual==3 & rank4==1 & mrandom5>=.95 & mrandom5~=.;
replace group="Treatment 5" if residual==3 & rank4==2 & mrandom5>=.95 & mrandom5~=.;
replace group="Control" if residual==3 & rank4==3 & mrandom5>=.95 & mrandom5~=.;

**Strata with 4 residual observations;

replace group="Treatment 1" if residual==4 & rank4==1 & mrandom5<.06666667 & mrandom5~=.;
replace group="Treatment 2" if residual==4 & rank4==2 & mrandom5<.06666667 & mrandom5~=.;
replace group="Treatment 3" if residual==4 & rank4==3 & mrandom5<.06666667 & mrandom5~=.;
replace group="Treatment 4" if residual==4 & rank4==4 & mrandom5<.06666667 & mrandom5~=.;

replace group="Treatment 1" if residual==4 & rank4==1 & mrandom5>=.06666667 & mrandom5<.13333333;
replace group="Treatment 2" if residual==4 & rank4==2 & mrandom5>=.06666667 & mrandom5<.13333333;
replace group="Treatment 3" if residual==4 & rank4==3 & mrandom5>=.06666667 & mrandom5<.13333333;
replace group="Treatment 5" if residual==4 & rank4==4 & mrandom5>=.06666667 & mrandom5<.13333333;

replace group="Treatment 1" if residual==4 & rank4==1 & mrandom5>=.13333333 & mrandom5<.2;
replace group="Treatment 2" if residual==4 & rank4==2 & mrandom5>=.13333333 & mrandom5<.2;
replace group="Treatment 3" if residual==4 & rank4==3 & mrandom5>=.13333333 & mrandom5<.2;
replace group="Control" if residual==4 & rank4==4 & mrandom5>=.13333333 & mrandom5<.2;

replace group="Treatment 1" if residual==4 & rank4==1 & mrandom5>=.2 & mrandom5<.26666667;
replace group="Treatment 2" if residual==4 & rank4==2 & mrandom5>=.2 & mrandom5<.26666667;
replace group="Treatment 3" if residual==4 & rank4==3 & mrandom5>=.2 & mrandom5<.26666667;
replace group="Treatment 5" if residual==4 & rank4==4 & mrandom5>=.2 & mrandom5<.26666667;

replace group="Treatment 1" if residual==4 & rank4==1 & mrandom5>=.26666667 & mrandom5<.33333333;
replace group="Treatment 2" if residual==4 & rank4==2 & mrandom5>=.26666667 & mrandom5<.33333333;
replace group="Treatment 4" if residual==4 & rank4==3 & mrandom5>=.26666667 & mrandom5<.33333333;
replace group="Treatment 5" if residual==4 & rank4==4 & mrandom5>=.26666667 & mrandom5<.33333333;

replace group="Treatment 1" if residual==4 & rank4==1 & mrandom5>=.33333333 & mrandom5<.4;
replace group="Treatment 2" if residual==4 & rank4==2 & mrandom5>=.33333333 & mrandom5<.4;
replace group="Treatment 4" if residual==4 & rank4==3 & mrandom5>=.33333333 & mrandom5<.4;
replace group="Control" if residual==4 & rank4==4 & mrandom5>=.33333333 & mrandom5<.4;

replace group="Treatment 1" if residual==4 & rank4==1 & mrandom5>=.4 & mrandom5<.46666667;
replace group="Treatment 3" if residual==4 & rank4==2 & mrandom5>=.4 & mrandom5<.46666667;
replace group="Treatment 4" if residual==4 & rank4==3 & mrandom5>=.4 & mrandom5<.46666667;
replace group="Treatment 5" if residual==4 & rank4==4 & mrandom5>=.4 & mrandom5<.46666667;

replace group="Treatment 1" if residual==4 & rank4==1 & mrandom5>=.46666667 & mrandom5<.53333333;
replace group="Treatment 3" if residual==4 & rank4==2 & mrandom5>=.46666667 & mrandom5<.53333333;
replace group="Treatment 4" if residual==4 & rank4==3 & mrandom5>=.46666667 & mrandom5<.53333333;
replace group="Control" if residual==4 & rank4==4 & mrandom5>=.46666667 & mrandom5<.53333333;

replace group="Treatment 1" if residual==4 & rank4==1 & mrandom5>=.53333333 & mrandom5<.6;
replace group="Treatment 4" if residual==4 & rank4==2 & mrandom5>=.53333333 & mrandom5<.6;
replace group="Treatment 5" if residual==4 & rank4==3 & mrandom5>=.53333333 & mrandom5<.6;
replace group="Control" if residual==4 & rank4==4 & mrandom5>=.53333333 & mrandom5<.6;

replace group="Treatment 1" if residual==4 & rank4==1 & mrandom5>=.6 & mrandom5<.66666667;
replace group="Treatment 2" if residual==4 & rank4==2 & mrandom5>=.6 & mrandom5<.66666667;
replace group="Treatment 5" if residual==4 & rank4==3 & mrandom5>=.6 & mrandom5<.66666667;
replace group="Control" if residual==4 & rank4==4 & mrandom5>=.6 & mrandom5<.66666667;

replace group="Treatment 2" if residual==4 & rank4==1 & mrandom5>=.66666667 & mrandom5<.73333333;
replace group="Treatment 3" if residual==4 & rank4==2 & mrandom5>=.66666667 & mrandom5<.73333333;
replace group="Treatment 4" if residual==4 & rank4==3 & mrandom5>=.66666667 & mrandom5<.73333333;
replace group="Treatment 5" if residual==4 & rank4==4 & mrandom5>=.66666667 & mrandom5<.73333333;

replace group="Treatment 2" if residual==4 & rank4==1 & mrandom5>=.73333333 & mrandom5<.8;
replace group="Treatment 3" if residual==4 & rank4==2 & mrandom5>=.73333333 & mrandom5<.8;
replace group="Treatment 4" if residual==4 & rank4==3 & mrandom5>=.73333333 & mrandom5<.8;
replace group="Control" if residual==4 & rank4==4 & mrandom5>=.73333333 & mrandom5<.8;

replace group="Treatment 2" if residual==4 & rank4==1 & mrandom5>=.8 & mrandom5<.86666667;
replace group="Treatment 3" if residual==4 & rank4==2 & mrandom5>=.8 & mrandom5<.86666667;
replace group="Treatment 5" if residual==4 & rank4==3 & mrandom5>=.8 & mrandom5<.86666667;
replace group="Control" if residual==4 & rank4==4 & mrandom5>=.8 & mrandom5<.86666667;

replace group="Treatment 3" if residual==4 & rank4==1 & mrandom5>=.86666667 & mrandom5<.93333333;
replace group="Treatment 4" if residual==4 & rank4==2 & mrandom5>=.86666667 & mrandom5<.93333333;
replace group="Treatment 5" if residual==4 & rank4==3 & mrandom5>=.86666667 & mrandom5<.93333333;
replace group="Control" if residual==4 & rank4==4 & mrandom5>=.86666667 & mrandom5<.93333333;

replace group="Treatment 2" if residual==4 & rank4==1 & mrandom5>=.93333333 & mrandom5~=.;
replace group="Treatment 4" if residual==4 & rank4==2 & mrandom5>=.93333333 & mrandom5~=.;
replace group="Treatment 5" if residual==4 & rank4==3 & mrandom5>=.93333333 & mrandom5~=.;
replace group="Control" if residual==4 & rank4==4 & mrandom5>=.93333333 & mrandom5~=.;


**Strata with 5 residual observations;

replace group="Treatment 1" if residual==5 & rank4==1 & mrandom5<.16666667 & mrandom5~=.;
replace group="Treatment 2" if residual==5 & rank4==2 & mrandom5<.16666667 & mrandom5~=.;
replace group="Treatment 3" if residual==5 & rank4==3 & mrandom5<.16666667 & mrandom5~=.;
replace group="Treatment 4" if residual==5 & rank4==4 & mrandom5<.16666667 & mrandom5~=.;
replace group="Treatment 5" if residual==5 & rank4==5 & mrandom5<.16666667 & mrandom5~=.;

replace group="Treatment 1" if residual==5 & rank4==1 & mrandom5>=.16666667 & mrandom5<.33333333;
replace group="Treatment 2" if residual==5 & rank4==2 & mrandom5>=.16666667 & mrandom5<.33333333;
replace group="Treatment 3" if residual==5 & rank4==3 & mrandom5>=.16666667 & mrandom5<.33333333;
replace group="Treatment 4" if residual==5 & rank4==4 & mrandom5>=.16666667 & mrandom5<.33333333;
replace group="Control" if residual==5 & rank4==5 & mrandom5>=.16666667 & mrandom5<.33333333;

replace group="Treatment 1" if residual==5 & rank4==1 & mrandom5>=.33333333 & mrandom5<.5;
replace group="Treatment 2" if residual==5 & rank4==2 & mrandom5>=.33333333 & mrandom5<.5;
replace group="Treatment 3" if residual==5 & rank4==3 & mrandom5>=.33333333 & mrandom5<.5;
replace group="Treatment 5" if residual==5 & rank4==4 & mrandom5>=.33333333 & mrandom5<.5;
replace group="Control" if residual==5 & rank4==5 & mrandom5>=.33333333 & mrandom5<.5;

replace group="Treatment 1" if residual==5 & rank4==1 & mrandom5>=.5 & mrandom5<.66666667;
replace group="Treatment 2" if residual==5 & rank4==2 & mrandom5>=.5 & mrandom5<.66666667;
replace group="Treatment 4" if residual==5 & rank4==3 & mrandom5>=.5 & mrandom5<.66666667;
replace group="Treatment 5" if residual==5 & rank4==4 & mrandom5>=.5 & mrandom5<.66666667;
replace group="Control" if residual==5 & rank4==5 & mrandom5>=.5 & mrandom5<.6666666;

replace group="Treatment 1" if residual==5 & rank4==1 & mrandom5>=.66666667 & mrandom5<.83333333;
replace group="Treatment 3" if residual==5 & rank4==2 & mrandom5>=.66666667 & mrandom5<.83333333;
replace group="Treatment 4" if residual==5 & rank4==3 & mrandom5>=.66666667 & mrandom5<.83333333;
replace group="Treatment 5" if residual==5 & rank4==4 & mrandom5>=.66666667 & mrandom5<.83333333;
replace group="Control" if residual==5 & rank4==5 & mrandom5>=.66666667 & mrandom5<.83333333;

replace group="Treatment 2" if residual==5 & rank4==1 & mrandom5>.83333333 & mrandom5~=.;
replace group="Treatment 3" if residual==5 & rank4==2 & mrandom5>.83333333 & mrandom5~=.;
replace group="Treatment 4" if residual==5 & rank4==3 & mrandom5>.83333333 & mrandom5~=.;
replace group="Treatment 5" if residual==5 & rank4==4 & mrandom5>.83333333 & mrandom5~=.;
replace group="Control" if residual==5 & rank4==5 & mrandom5>.83333333 & mrandom5~=.;

*** Let's look, did it give us good balance?;
* Overall numbers allocated to each group;
tab group;
* Number in each strata allocated to each group;
tab strata group;

//EDIT: cleanup;
egen int treatment_mb = group(group);
drop obs random2 rank2 group multiples multiples2 residual random4 rank4 random5 mrandom5;
qui compress;
