{smcl}
{* *! version 0.1 30aug2021}{...}
{cmd:help ranger}
{hline}

{title:Title}

{phang}
{bf:ranger} {hline 2} Stata-bindings for R's ranger package, which implements Random Forests.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ranger}
	{it:varlist(fv)} [{cmd:if}] [{cmd:pw}] [{cmd:,} {opt predict(newvarname)} {opt predict_oob(newvarname)} num_trees(int 500)] 

{synoptset 23 tabbed}{...}
{marker options_table}{...}
{synopthdr}
{synoptline}
{syntab :Main}
{synopt :{opt varlist}}Standard estimation specification. Allows factor variables.{p_end}

{syntab :Options}
{synopt :{opt predict(newvarname)}}Name of variable to store the predictions.{p_end}
{synopt :{opt predict_oob(newvarname)}}Name of variable to store the out-of-bag (a form of out-of-sample) predictions.{p_end}
{synopt :{opt num_trees(#)}}Number of trees in the forest to run. This increases the run-time.{p_end}

{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
Pre-requisites: One needs to install {browse "https://www.r-project.org/":R} and {cmd:ranger} R package (available in their default/CRAN repository). One also needs to install the Stata module
{browse "https://github.com/haghish/rcall":Rcall}. 

{pstd}
{cmd:ranger} provides Stata-bindings to R's {cmd:ranger} package which is a fast implementation of Random Forests.
As the R session is only open during the call, we combine both estimationg and prediction in a single step.


{marker examples}{...}
{title:Examples}

{pstd}
Example:

	{cmd:sysuse auto}
	{cmd:ranger price mpg, predict(price_hat)}


