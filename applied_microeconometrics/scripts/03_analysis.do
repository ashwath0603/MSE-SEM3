* =============================================================================
* Title:    G3 — Estimation, tests and figures
* Author:   Ashwath Balasubramanian
* Created:  2026-08-25
* Purpose:  Everything the assignment grades, in question order:
*             Q6  graphs        Q7  xtsum
*             Q8  Pooled / FE / RE, with and without time dummies + F-tests
*             Q9  Pooled-vs-FE, Pooled-vs-RE, FE-vs-RE
*           Tables are written as .tex fragments into output/tables/ and pulled
*           into writeup/main.tex with \input{} — never copy-pasted.
* Run:      stata -b do scripts/03_analysis.do        (from the unit root)
* =============================================================================

version 17
clear all
set more off
set varabbrev off

* Batch mode runs in the directory it was invoked from (the unit root), so all
* paths below are relative to that. Do not cd.

* Dependencies: outreg2 and estout. Install once with
*   ssc install outreg2
*   ssc install estout
capture which outreg2
if _rc {
    display as error "outreg2 not installed. Run once:  ssc install outreg2"
    exit 111
}

* Load -----------------------------------------------------------------------
use "data/G3.dta", clear

* Declare the panel. encode gives xtset a numeric entity id.
encode iso3, generate(country_id)
xtset country_id year

* Local macro holding the regressor list, so every model below stays identical
* and there is one place to change the specification.
local X "l_gdp gge_gdp over60 l_tb"
local DEP "l_che"

* Q6: Graphs ------------------------------------------------------------------
* Keep these uncluttered — marks are deducted for busy graphs.

* graph box `DEP', over(inc_group) ///
*     title("Health expenditure by income group") ///
*     ytitle("Log health expenditure p.c. (PPP int$)")
* graph export "output/figures/fig1_box_by_income.pdf", replace

* Mean trajectory by income group — one line per group, nothing else.
* preserve
*     collapse (mean) `DEP', by(year inc_group)
*     xtset inc_group year
*     xtline `DEP', overlay ///
*         title("Mean health expenditure over time, by income group") ///
*         ytitle("Log health expenditure p.c.") xtitle("Year")
*     graph export "output/figures/fig2_trend_by_income.pdf", replace
* restore

* Q7: Summary statistics ------------------------------------------------------
* xtsum decomposes each variable into overall / between / within variation.
* The between-vs-within split is what motivates FE, so discuss it explicitly.

* xtsum `DEP' `X'

* Q8: Coefficient estimates ---------------------------------------------------
* Six models: {Pooled, FE, RE} x {no time dummies, time dummies}.
eststo clear

* --- without time dummies ---
* eststo pooled:  regress `DEP' `X' inc_group, vce(cluster country_id)
* eststo fe:      xtreg   `DEP' `X' inc_group, fe  vce(cluster country_id)
* eststo re:      xtreg   `DEP' `X' inc_group, re  vce(cluster country_id)

* NOTE: FE will drop inc_group (time-invariant, absorbed by the country effect).
* That is expected and is part of the answer to Q8e / Q9 — do not "fix" it.

* --- with time dummies ---
* eststo pooled_t: regress `DEP' `X' inc_group i.year, vce(cluster country_id)
*     testparm i.year                                  // Q8d: F-test on year dummies
*     estadd scalar F_year = r(F)
*     estadd scalar p_year = r(p)
* eststo fe_t:     xtreg `DEP' `X' inc_group i.year, fe vce(cluster country_id)
*     testparm i.year
*     estadd scalar F_year = r(F)
*     estadd scalar p_year = r(p)
* eststo re_t:     xtreg `DEP' `X' inc_group i.year, re vce(cluster country_id)
*     testparm i.year
*     estadd scalar F_year = r(chi2)
*     estadd scalar p_year = r(p)

* --- export as a formatted LaTeX fragment ---
* esttab pooled fe re pooled_t fe_t re_t using "output/tables/t1_estimates.tex", ///
*     replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
*     mtitles("Pooled" "FE" "RE" "Pooled+T" "FE+T" "RE+T") ///
*     stats(N N_g r2 F_year p_year, labels("Observations" "Countries" "R-squared" ///
*           "F: year dummies" "p-value")) ///
*     title("Determinants of health expenditure\label{tab:estimates}")

* Q9: Model comparison tests --------------------------------------------------
* State H0, H1, statistic, df and decision for each in the writeup.

* (a) Pooled vs FE — H0: all country effects equal zero.
*     xtreg reports this F-test automatically at the foot of the fe output.
* quietly xtreg `DEP' `X', fe
* display "F(all u_i=0) = " e(F_f) "  p = " Ftail(e(df_a), e(df_r), e(F_f))

* (b) Pooled vs RE — Breusch-Pagan LM test. H0: Var(u_i) = 0.
* quietly xtreg `DEP' `X' inc_group, re
* xttest0

* (c) FE vs RE — Hausman. H0: RE is consistent (no correlation between u_i and X).
*     Estimate both WITHOUT cluster-robust SEs: hausman requires the efficient
*     estimator under H0, and clustering breaks that assumption.
* quietly xtreg `DEP' `X', fe
* estimates store fe_h
* quietly xtreg `DEP' `X', re
* estimates store re_h
* hausman fe_h re_h

display as text "03_analysis.do is a scaffold — uncomment once data/G3.dta exists."
