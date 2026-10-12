* =============================================================================
* G3 - Applied Microeconometrics 2026, Computer Assignment 1
*
* Produces everything the write-up needs, in question order.
*   Q6  three figures  ->  output/figures/
*   Q7  xtsum
*   Q8  pooled / FE / RE, with and without time dummies, + F tests
*   Q9  Pooled vs FE, Pooled vs RE, FE vs RE
*
* Open in the Do-file Editor and click Execute. Nothing to install.
* =============================================================================

clear all
set more off

cd "/Users/a91733/Documents/GitHub/MSE-SEM3/applied_microeconometrics"
use "data/G3.dta", clear

encode iso3, gen(country_id)
xtset country_id year

global Y  "l_che"
global X  "l_gdp gfce_gdp over65 l_tb ncd_mort"
global TI "i.inc_group_n"

label define inc4 1 "Low" 2 "Lower mid" 3 "Upper mid" 4 "High", replace
label values inc_group_n inc4

* =============================================================================
* Q6  Figures
* =============================================================================

local C1 "26 150 65"
local C2 "253 141 60"
local C3 "44 105 154"
local C4 "158 44 66"
local OPT graphregion(color(white)) plotregion(color(white)) scheme(s1color)
local LEG legend(order(1 "Low" 2 "Lower mid" 3 "Upper mid" 4 "High") position(6) rows(1) size(small) region(lstyle(none)))
local MC  mcolor("`C1'%55" "`C2'%55" "`C3'%55" "`C4'%55")
local LC  lcolor("`C1'" "`C2'" "`C3'" "`C4'")

* Fig 1  income against expenditure, by income group
separate $Y, by(inc_group_n)
twoway scatter l_che1 l_che2 l_che3 l_che4 l_gdp, msize(small) `MC' xtitle("Log GDP per capita (2021 PPP int. dollars)") ytitle("Log health expenditure per capita") `LEG' `OPT'
graph export "output/figures/fig1_che_vs_gdp.pdf", replace
drop l_che1 l_che2 l_che3 l_che4

* Fig 2  median health share of GDP, by year and income group
gen che_gdp = 100*che_pc_ppp/gdp_pc_ppp

preserve
    collapse (median) che_gdp, by(year inc_group_n)
    separate che_gdp, by(inc_group_n)
    twoway line che_gdp1 che_gdp2 che_gdp3 che_gdp4 year, lwidth(medthick) `LC' xtitle("") ytitle("Median health expenditure (% of GDP)") xlabel(2010(2)2020) `LEG' `OPT'
    graph export "output/figures/fig2_trend_by_income.pdf", replace
restore

* Fig 3  disease burden by income group (TB panel in logs)
graph box l_tb, over(inc_group_n, label(labsize(small))) ytitle("Log TB incidence per 100,000") title("Infectious burden") `OPT' nodraw name(tb, replace)
graph box ncd_mort, over(inc_group_n, label(labsize(small))) ytitle("NCD mortality, ages 30-70 (%)") title("Chronic burden") `OPT' nodraw name(ncd, replace)
graph combine tb ncd, cols(2) imargin(l=6 r=6) `OPT' xsize(9) ysize(4.2)
graph export "output/figures/fig3_disease_burden.pdf", replace
graph drop _all

drop che_gdp

* =============================================================================
* Q7  Summary statistics
* =============================================================================

xtdescribe
xtsum $Y $X

* The income dummies are summarised too.  Their within SD is exactly zero: no
* country changes World Bank group over 2010-2021, which is the arithmetic
* reason fixed effects cannot identify them.
tab inc_group_n, gen(incd)
xtsum incd1 incd2 incd3 incd4
drop incd1 incd2 incd3 incd4

* =============================================================================
* Q8  Pooled / FE / RE, with and without time dummies
* Cluster-robust standard errors by country throughout.
* =============================================================================

regress $Y $X $TI, vce(cluster country_id)
estimates store POOLED

xtreg $Y $X $TI, fe vce(cluster country_id)
estimates store FE

xtreg $Y $X $TI, re vce(cluster country_id)
estimates store RE

regress $Y $X $TI i.year, vce(cluster country_id)
estimates store POOLED_T
testparm i.year

xtreg $Y $X $TI i.year, fe vce(cluster country_id)
estimates store FE_T
testparm i.year

xtreg $Y $X $TI i.year, re vce(cluster country_id)
estimates store RE_T
testparm i.year

mata: mata clear
estimates table POOLED FE RE POOLED_T FE_T RE_T, b(%9.3f) se(%9.3f) stats(N N_g r2 r2_w)

* Q8f  income elasticity against unity
xtreg $Y $X $TI i.year, fe vce(cluster country_id)
test l_gdp = 1

* =============================================================================
* Q9  Model comparison tests
* Conventional standard errors: none of these is reported under vce(cluster).
* =============================================================================

* (a) Pooled vs FE.  Read the "F test that all u_i=0" line at the foot.
xtreg $Y $X $TI, fe
xtreg $Y $X $TI i.year, fe

* (b) Pooled vs RE.  Breusch-Pagan LM.
* The theta option prints lambda, the quasi-demeaning weight, which the
* presentation reports alongside the tests.  It is only shown on request, and
* only for balanced panels.
xtreg $Y $X $TI, re theta
xttest0
xtreg $Y $X $TI i.year, re theta
xttest0

* (c) FE vs RE.  Hausman.  Income group is dropped: FE cannot identify a
* time-invariant regressor, and hausman needs a shared coefficient vector.
xtreg $Y $X, fe
estimates store fe_h
xtreg $Y $X, re
estimates store re_h
hausman fe_h re_h, sigmamore

xtreg $Y $X i.year, fe
estimates store fe_ht
xtreg $Y $X i.year, re
estimates store re_ht
hausman fe_ht re_ht, sigmamore
