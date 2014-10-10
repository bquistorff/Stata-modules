{smcl}
{* *! version 0.1  09oct2014}{...}
{title:Title}

{p2colset 5 25 27 2}{...}
{p2col :{cmd:assign_treatment} {hline 2}}Assign Treatment{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:assign_treatment {varlist}, generate({newvar}) num_treatments(int) [handle_misfit(string)]}

{marker description}{...}
{title:Description}

{pstd}
{cmd:assign_treatment} Assign units randomly to treatments so that the treatments are as similar as possible in terms of the stratification variables. Cells identifying unique combinations of values of the stratification variables are identified and assigned randomly to treatments. When the cell size is a multiple of num_treatments, then all the treatments receive the same number of units from a cell. Otherwise the amounts may differ by 1.

{marker options}{...}
{title:Options}
{phang} {opt handle_misfit} determines how residual units ("misfits") in each cell are divided randomly among treatments. For example if a cell has 9 members and there are 6 treatments, then 3 units are picked at random to be the misfits and randomly ordered. {p_end}
{phang2}If no option is specified, the default behavior is to assign the misfits to a random (wrapping) interval of treatments. For example, they could assigned to treatments (2,3,4) or (6,1,2).{p_end}
{phang2}If "full" is specified then the units are assigned to a random combination of treatments. For example (1,3,4) or 2,4,5).{p_end}
{phang2}If "reduction" is specified then random intervals are chosen as in the default case, but an attempt is made to allocate these intervals so that balance is maintains for important strata. The issue is that while the above methods ensure minimal cell-level differences across treatments, when looking at a courser level of stratification (e.g. looking at the balance across only one stratification variable when cells are defined by two stratification variables) then these small differences can aggregate up to bigger differences. The reduction method takes the misfits from the original invocation, makes the cells more course by removing the least important stratification variable, and tries to allocate the units again. With several initial stratification variables this procedure continues (recurses) until there are no stratification variables left. The user lists the stratification variables in increasing order of importance. The more important stratification variables will be much better balanced. {p_end}

{marker examples}{...}
{title:Examples:}

{pstd}Basic usage{p_end}
{phang2}{cmd:. egen cell_id = group(strat_var1 strat_var2)}{p_end}
{phang2}{cmd:. assign_treatment strat_var1 strat_var2, generate(treatment_int) num_treatments(${ngroups})}{p_end}
{phang2}{cmd:. *Check balance. The numbers in each row should differ by at most 1.}{p_end}
{phang2}{cmd:. tab cell_id treatment_int}{p_end}

{pstd}Stratification reduction{p_end}
{phang2}{cmd:. assign_treatment strat_var1 strat_var2, generate(treatment_redux) num_treatments(${ngroups}) handle_misfit(reduction)}{p_end}
{phang2}{cmd:. tab cell_id treatment_redux}{p_end}
{phang2}{cmd:. *Now the strata we care about has smallest differences possible given cell-level balance.}{p_end}
{phang2}{cmd:. tab strat_var2 treatment_redux}{p_end}

{marker references}{...}
{title:References}

{marker WIKI}{...}
{phang}
{browse "http://blogs.worldbank.org/impactevaluations/tools-of-the-trade-doing-stratified-randomization-with-uneven-numbers-in-some-strata":{it:Tools of the trade: Doing Stratified Randomization with Uneven Numbers in some Strata}.}
{p_end}
