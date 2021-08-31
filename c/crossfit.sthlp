{smcl}
{* *! version 0.1 30aug2021}{...}
{cmd:help crossfit}
{hline}

{title:Title}

{phang}
{bf:crossfit} {hline 2} Generate out-of-sample predictions/residuals using cross-fitting.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:crossfit}
	{it:newvar}
	[{cmd:,} {opt k(#)} {opt by(varname)} {opt residuals} {opt outcome(varname)} {opt nodots}]
	{cmd::} {it:est_command}

{synoptset 23 tabbed}{...}
{marker options_table}{...}
{synopthdr}
{synoptline}
{syntab :Main}
{synopt :{opt newvar}}Name of the variable to create{p_end}

{syntab :Options}
{synopt :{opt k(#)}}Number of folds to create.{p_end}
{synopt :{opt by(varname)}}Pre-existing fold identifier variable to use.{p_end}
{synopt :{opt residuals}}Create newvar with residuals rather than predictions.{p_end}
{synopt :{opt outcome(varname)}}Name of outcome variable. Required with {it:residuals}.{p_end}
{synopt :{opt nodots}}Whether to silence the progress bar.{p_end}

{syntab :Command}
{synopt :{opt est_command}}An estimation command that supports {cmd:predict}. 
The command must also be parse-able by the generic {cmd:syntax} and support {it:if} (we splice in an extra {it:if} clause).{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:crossfit} creates out-of-sample/honest predictions (or residuals) for an estimation command. 
It does this by separating the data into K folds and generating the prediction for the kth fold
using a model trained on all but the kth fold of data. Either {it:k} or {it:by(varname)} must be specified.
{it:by(varname)} is useful if you want to pre-generate folds that are the same across several crossfitting tasks.
If {opt outcome(varname)} is specified, then the following are generated: {cmd:e(mse)} (mean-squared error), 
{cmd:e(mae)} (mean absolute error), and {cmd:e(r2)} (R2).

{marker examples}{...}
{title:Examples}

{pstd}
Example:

	{cmd:sysuse auto}
	{cmd:crossfit price_hat_oos, k(5) outcome(price): reg price mpg}


