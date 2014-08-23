{smcl}
{* *! version 0.1  28jun2013}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{cmd:iso8601_strs} {hline 2}}ISO 8601 date/times{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:iso8601_strs}

{marker description}{...}
{title:Description}

{pstd}
{cmd:iso8601_strs} generates strings related to ISO 8601 date/times.

{marker examples}{...}
{title:Examples:  Log-files}

{pstd}Log-file usage{p_end}
{phang2}{cmd:. iso8601_strs}{p_end}
{phang2}{cmd:. log using "output_`s(iso8601_dt_file)'.log"}{p_end}


{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:iso8601_strs} saves the following in {cmd:s()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:s(iso8601_d)}}ISO 8601 date (e.g. "2000-12-25"){p_end}
{synopt:{cmd:s(iso8601_dt)}}ISO 8601 date-time (e.g. "2000-12-25T13:01:01"){p_end}
{synopt:{cmd:s(iso8601_dt_file)}}ISO 8601 date-time for filenames (e.g. "2000-12-25T13-01-01"){p_end}
{synopt:{cmd:s(unix_ts)}}Unix timestamp, second since 1970 epoch (e.g. "977749261"){p_end}


{marker references}{...}
{title:References}

{marker WIKI}{...}
{phang}
{browse "http://en.wikipedia.org/wiki/ISO_8601":{it:Wikipedia - ISO 8601}.}
{p_end}
