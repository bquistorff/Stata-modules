
*GE_mode
global GE_mode_nothing 0
global GE_mode_custom_cmd 1
global GE_mode_trim_early_placebo 2

*Drop reason
global Synth_PE_high 2
global Synth_PE_low 3
global Synth_opt_error 4

*Unit types
global Unit_type_treated 1
global Unit_type_donor 2
label define unit_type ${Unit_type_treated} "Treated" ${Unit_type_donor} "Donor", replace
