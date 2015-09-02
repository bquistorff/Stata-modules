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
{cmd:assign_treatment} Assign units randomly to treatments so that the treatments are as similar as possible in terms of the stratification variables. Cells identifying unique combinations of values of the stratification variables are identified and their units are assigned randomly to treatments. When the cell size is a multiple of num_treatments, then all the treatments receive the same number of units from a cell. Otherwise, some number (less than num_treatments) from a cell will be randomly picked as "misfits". The basic rules for a cell's misfits are that (a) there should be no overlap in assignment to treatment, and (b) the outcome is random. This ensures that cell-level differences in counts per-treatment will at most differ by 1. A secondary concern is maintaining overall balance at courser levels of stratification as cell-level differences of 1 can aggregate up to larger differences at intermediate levels and all the way up to totals.

{marker options}{...}
{title:Options}

{phang} {opt handle_misfit} determines how residual units ("misfits") in each cell are divided randomly among treatments. For example if a cell has 9 members and there are 6 treatments, then 3 units are picked as misfits. In all methods, the misfits are picked at random and randomly ordered. {p_end}
{phang2}{opt handle_misfit(obalance)}, the default, jointly assigns all misfits such that there is also overall balance (the number in each treatment differs by no more than 1). This ensures balance at the coursest level. It does this in a simply way by assigning misfits to a random "wrapping" interval of treatments (e.g. to (2,3,4) or (6,1,2)). The intervals from the misfits from all cells dove-tail together to ensure the overall balance. {p_end}
{phang2}{opt handle_misfit(reduction)} specifies that random intervals are chosen as in the default case, but a further attempt is made to allocate these intervals so that balance is maintained for important strata (intermediate levels of coarseness). It does this by progressively coarsening the stratification and re-ordering cells so that for important variables, units with the same value are more contiguous and therefore less likely to be mixed in a random way that ends up allocating them quite differently. The user lists the stratification variables in increasing order of importance. The more important stratification variables will be much better balanced. {p_end}
{phang2}{opt handle_misfit(full)} specifies that misfit units can be assigned to any of the full range of combinations (not just wrapped intevals, but, e.g. (1,3,4) or (2,4,5)). It does this by separately randomizing in each cell. This method may not yield optimal overall balance across treatments (totals may differ by more than 1). {p_end}
{phang2}{opt handle_misfit(full_obalance)} uses a slightly slower algorithm (simple recursive constraint satisfaction solver) that achieves overall balance as well as allowing misfits to be assigned to full (not just wrapped) combinations of treatments. It does so by assigning units one at a time to fill repeating slots of (1,...,T,1,...T,...,1..). At each stage it keeps track of possible units that could fill a spot (without causing two from the same cell to have the same treatment). It randomly picks one and then attempts to fill the next spot (while giving a slight weight to trying to fit first misfits from cells with many misfits). If filling a spot is impossible the algorithm backs up to the last point where there was a choice and tries a new option. There is a small chance that this option may take quite some time to find a solution. If this occurs you can restart with a new random seed. (For the technical, one can also play with the w variable in the mata code to strength or weaken the extra weight given to misfits that are numerous.) {p_end}
{phang2}{opt handle_misfit(missing)} does not assign the misfits to a treatment (leaves as missing).{p_end}
{pstd}
The algorithms have varying tradeoffs. Most people will likely find {opt handle_misfit(full_obalance)} appropriate unless there are intermediate levels of stratification for which optimal balance is required in which case use {opt handle_misfit(reduction)}. The others have the advantage of simplicity in terms of coding ({opt handle_misfit(obalance)} is essentially 5 lines of code) or conceptually {opt handle_misfit(full)}.

{marker examples}{...}
{title:Examples:}

{pstd}Basic usage{p_end}
{phang2}{cmd:. egen cell_id = group(strat_var1 strat_var2)}{p_end}
{phang2}{cmd:. assign_treatment strat_var1 strat_var2, generate(full_obalance) num_treatments(${ngroups})}{p_end}
{phang2}{cmd:. *Check balance. The numbers in each row should differ by at most 1.}{p_end}
{phang2}{cmd:. tab cell_id treatment_int}{p_end}
{phang2}{cmd:. *Check overall balance. The numbers should differ by at most 1.}{p_end}
{phang2}{cmd:. tab treatment_int}{p_end}

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
