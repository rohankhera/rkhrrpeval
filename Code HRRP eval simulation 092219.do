/***********************************************
THE FOLLOWING CODE CREATES A SIMULATED DATA SET 
AND REPLICATES THE ANALYTIC APPROACH FOR 
BOTH ANALYTIC STRATEGIES
***********************************************/

/****** VERSION DATE September 22, 2019 ********/

set obs 123
gen DYM = _n
drop if DYM <4

gen month_number = _n

*creating month year variables

gen Day = 1
gen Year = floor(2005 + ((DYM-1)/12))
gen Month = DYM - 12*(Year-2005)
gen date = mdy(Month, Day, Year)
gen moyear = ym(Year, Month)
label variable moyear "Month"
format %tmMon_CCYY moyear
format %td date

gen month_analysis = moyear

*3 ITS with four 30 month periods

mkspline T4Period 4 = moyear,  displayknots
mkspline T4Change 4 = moyear,  displayknots marginal

gen The4periods = 1 if moyear <572.75
replace The4periods = 2 if moyear >572.75 & moyear <602.5
replace The4periods = 3 if moyear >602.5 & moyear <632.25
replace The4periods = 4 if moyear >632.25

sort The4periods DYM



*Rising slope
gen linear = 0.008*month_number+7
plot linear month_number
twoway scatter linear month_number

*Positive control

gen month_post_HRRP = month_number - 60 if month_number > 60
replace month_post_HRRP = 0 if month_number <= 60


gen linear_pos = linear + (0.004*month_post_HRRP)
plot linear_pos month_number
twoway scatter linear_pos month_number

set seed 20
gen varlinear = rnormal(0,0.05)
plot varlinear month_number


gen linear_pos_comp = linear_pos + varlinear
plot linear_pos_comp month_number
twoway scatter linear_pos_comp month_number


*doing contrasts across periods
regress linear_pos_comp i.The4periods
contrast ar.The4periods, effects

*testing using ITS

regress linear_pos_comp T4Period* 
regress linear_pos_comp T4Change* 

*creating an inflection that occurred before HRRP
*At month 48 - 1 year before HRRP

gen month_start48 = month_number - 48 if month_number > 48
replace month_start48 = 0 if month_number <= 48

gen linear_pos_48 = linear + (0.004*month_start48)
replace  linear_pos_48 = linear if month_number <= 48
plot  linear_pos_48 month_number
twoway scatter  linear_pos_48 month_number

*Positive control

gen linear_pos_48_comp =  linear_pos_48 + varlinear
plot linear_pos_48_comp month_number
twoway scatter linear_pos_48_comp month_number

*doing contrasts across periods
regress linear_pos_48_comp i.The4periods
contrast ar.The4periods, effects

*testing using ITS

regress linear_pos_48_comp T4Period* 
regress linear_pos_48_comp T4Change* 


*creating an inflection at month 36 - 2 years before HRRP
gen month_start36 = month_number - 36 if month_number > 36
replace month_start36 = 0 if month_number <= 36

*Positive control
gen linear_pos_36 = linear + (0.004*month_start36)
plot  linear_pos_36 month_number
twoway scatter  linear_pos_36 month_number


gen linear_pos_36_comp =  linear_pos_36 + varlinear
plot linear_pos_36_comp month_number
twoway scatter linear_pos_36_comp month_number

*doing contrasts across periods
regress linear_pos_36_comp i.The4periods
contrast ar.The4periods, effects

*testing using ITS

regress linear_pos_36_comp T4Period* 
regress linear_pos_36_comp T4Change* 


save simulation071519_yearly, replace

use simulation071519_yearly, clear


********Creating concatenated files for period wise assessments

*sim 12
use simulation071519_yearly
save sim_12_partial, replace
drop if inlist(The4periods,3,4)
keep linear_pos_comp linear_pos_48_comp linear_pos_36_comp The4periods T4Period1-T4Period4 moyear
gen time_period = 0 if The4periods == 1
replace time_period = 1 if The4periods == 2
gen comparison = 1
save sim_12_partial, replace

*sim 23
use simulation071519_yearly
save sim_23_partial, replace
drop if inlist(The4periods,1,4)
keep linear_pos_comp linear_pos_48_comp linear_pos_36_comp The4periods T4Period1-T4Period4 moyear
gen time_period = 0 if The4periods == 2
replace time_period = 1 if The4periods == 3
gen comparison = 2
save sim_23_partial, replace

*sim 34
use simulation071519_yearly
save sim_34_partial, replace
drop if inlist(The4periods,1,2)
keep linear_pos_comp linear_pos_48_comp linear_pos_36_comp The4periods T4Period1-T4Period4 moyear
gen time_period = 0 if The4periods == 3
replace time_period = 1 if The4periods == 4
gen comparison = 3
save sim_34_partial, replace

append using sim_23_partial
append using sim_12_partial

save sim_1to4_appended, replace

****CREATING RESULT FILE
putdocx clear
putdocx begin


*doing contrasts across periods
putdocx paragraph
putdocx text ("Positive control with change at HRRP announcement")
putdocx paragraph
putdocx text ("Using period-wise assessments")
regress linear_pos_comp i.The4periods
putdocx table mytable = etable

contrast ar.The4periods, effects
putdocx table mytable = etable

use sim_1to4_appended, clear
regress linear_pos_comp time_period##comparison if comparison ~= 3
putdocx table mytable = etable
margins r.time_period, over(r.comparison)
putdocx table mytable = etable


use simulation071519_yearly, clear
*testing using ITS
putdocx paragraph
putdocx text ("Using ITS models")

regress linear_pos_comp T4Period* 
putdocx table mytable = etable

regress linear_pos_comp T4Change* 
putdocx table mytable = etable

putdocx pagebreak


*doing contrasts across periods
putdocx paragraph
putdocx text ("Control with change at Month 48")
putdocx paragraph
putdocx text ("Using period-wise assessments")
regress linear_pos_48_comp i.The4periods
putdocx table mytable = etable

contrast ar.The4periods, effects
putdocx table mytable = etable

use sim_1to4_appended, clear
regress linear_pos_48_comp time_period##comparison if comparison ~= 3
putdocx table mytable = etable
margins r.time_period, over(r.comparison)
putdocx table mytable = etable

use simulation071519_yearly, clear
*testing using ITS
putdocx paragraph
putdocx text ("Using ITS models")

regress linear_pos_48_comp T4Period* 
putdocx table mytable = etable

regress linear_pos_48_comp T4Change* 
putdocx table mytable = etable

putdocx pagebreak

*doing contrasts across periods
putdocx paragraph
putdocx text ("Control with change at Month 36")
putdocx paragraph
putdocx text ("Using period-wise assessments")
regress linear_pos_36_comp i.The4periods
putdocx table mytable = etable

contrast ar.The4periods, effects
putdocx table mytable = etable

use sim_1to4_appended, clear
regress linear_pos_36_comp time_period##comparison if comparison ~= 3
putdocx table mytable = etable
margins r.time_period, over(r.comparison)
putdocx table mytable = etable

use simulation071519_yearly, clear
*testing using ITS
putdocx paragraph
putdocx text ("Using ITS models")

regress linear_pos_36_comp T4Period* 
putdocx table mytable = etable

regress linear_pos_36_comp T4Change* 
putdocx table mytable = etable

putdocx save Simulation_analysis_report_071519.docx, replace


*********************************************************
********* CREATING FIGURES FOR SIMULATION ***************
*********************************************************

twoway (scatter linear_pos_comp moyear ,msymbol(O) msize(tiny) xlabel(#40, labsize(vsmall) angle(45)) xtitle("Months") ylabel(,labsize(small) nogrid) mcolor(maroon) ytitle("Mortality rate, %")), graphregion(color(white)) bgcolor(white) xline(602.5, lcolor(black) lpattern(dash))  xline(602.5, lcolor(red) lpattern(dot))

 graph save "simulation source HRRP 60 mortality.gph", replace
graph export "simulation source  HRRP 60 mortality.pdf", as(pdf) replace
graph export "simulation source  HRRP 60 mortality.svg", as(svg) replace
graph export "simulation source HRRP 60 mortality.tif", as(tif) replace


twoway (scatter linear_pos_48_comp moyear ,msymbol(O) msize(tiny) xlabel(#40, labsize(vsmall) angle(45)) xtitle("Months") ylabel(,labsize(small) nogrid) mcolor(maroon) ytitle("Mortality rate, %")), graphregion(color(white)) bgcolor(white) xline(590.5, lcolor(black) lpattern(dash)) xline(602.5, lcolor(red) lpattern(dot))

 graph save "simulation source HRRP 48 mortality.gph", replace
graph export "simulation source  HRRP 48 mortality.pdf", as(pdf) replace
graph export "simulation source  HRRP 48 mortality.svg", as(svg) replace
graph export "simulation source HRRP 48 mortality.tif", as(tif) replace


twoway (scatter linear_pos_36_comp moyear ,msymbol(O) msize(tiny) xlabel(#40, labsize(vsmall) angle(45)) xtitle("Months") ylabel(,labsize(small) nogrid) mcolor(maroon) ytitle("Mortality rate, %")), graphregion(color(white)) bgcolor(white) xline(578.5, lcolor(black) lpattern(dash)) xline(602.5, lcolor(red) lpattern(dot))

 graph save "simulation source HRRP 36 mortality.gph", replace
graph export "simulation source  HRRP 36 mortality.pdf", as(pdf) replace
graph export "simulation source  HRRP 36 mortality.svg", as(svg) replace
graph export "simulation source HRRP 36 mortality.tif", as(tif) replace



*testing using ITS

regress linear_pos_comp T4Period* 
predict linear_pos_comp_spline

regress linear_pos_comp T4Change* 
label variable linear_pos_comp "Simulated inflection at HRRP announcement"
label variable linear_pos_comp_spline "Simulated inflection at HRRP announcement"

 twoway  (scatter linear_pos_comp moyear ,msymbol(O) msize(tiny) xlabel(#40, labsize(vsmall) angle(45)) xtitle("Months") ylabel(,labsize(small) nogrid) mcolor(maroon) ytitle("Mortality rate, %")) (line linear_pos_comp_spline moyear ,lcolor(maroon) legend(off) sort) , xline(572.75 602.5 632.25, lcolor(black)) graphregion(color(white)) bgcolor(white)
 
 graph save "simulation HRRP 60 mortality.gph", replace
graph export "simulation HRRP 60 mortality.pdf", as(pdf) replace
graph export "simulation HRRP 60 mortality.svg", as(svg) replace
graph export "simulation HRRP 60 mortality.tif", as(tif) replace


*Month 48

regress linear_pos_48_comp T4Period* 
predict linear_pos_48_comp_spline

regress linear_pos_48_comp T4Change* 
label variable linear_pos_48_comp "Simulated inflection at Month 48"
label variable linear_pos_48_comp_spline "Simulated inflection at Month 48"

 twoway  (scatter linear_pos_48_comp moyear ,msymbol(O) msize(tiny) xlabel(#40, labsize(vsmall) angle(45)) xtitle("Months") ylabel(,labsize(small) nogrid) mcolor(maroon) ytitle("Mortality rate, %")) (line linear_pos_48_comp_spline moyear ,lcolor(maroon) legend(off) sort) , xline(572.75 602.5 632.25, lcolor(black)) graphregion(color(white)) bgcolor(white)
 
 graph save "simulation HRRP 48 mortality.gph", replace
graph export "simulation HRRP 48 mortality.pdf", as(pdf) replace
graph export "simulation HRRP 48 mortality.svg", as(svg) replace
graph export "simulation HRRP 48 mortality.tif", as(tif) replace


*Month 36

regress linear_pos_36_comp T4Period* 
predict linear_pos_36_comp_spline

regress linear_pos_36_comp T4Change* 
label variable linear_pos_36_comp "Simulated inflection at Month 36"
label variable linear_pos_36_comp_spline "Simulated inflection at Month 36"

 twoway  (scatter linear_pos_36_comp moyear ,msymbol(O) msize(tiny) xlabel(#40, labsize(vsmall) angle(45)) xtitle("Months") ylabel(,labsize(small) nogrid) mcolor(maroon) ytitle("Mortality rate, %")) (line linear_pos_36_comp_spline moyear ,lcolor(maroon) legend(off) sort) , xline(572.75 602.5 632.25, lcolor(black)) graphregion(color(white)) bgcolor(white)
 
 graph save "simulation HRRP 36 mortality.gph", replace
graph export "simulation HRRP 36 mortality.pdf", as(pdf) replace
graph export "simulation HRRP 36 mortality.svg", as(svg) replace
graph export "simulation HRRP 36 mortality.tif", as(tif) replace


*********************************************************
********* RESULTS FOR MORTALITY BY PERIODS **************
*********************************************************

sort The4periods moyear
by The4periods: sum linear_pos_comp

by The4periods: sum linear_pos_48_comp

by The4periods: sum linear_pos_36_comp


