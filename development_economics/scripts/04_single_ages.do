* =============================================================================
* 04_single_ages.do: split GBD age bins into single years of age 0..95
*
* Input : $CLEAN/panel_bins.dta
* Output: $CLEAN/single_ages.dta: unit x year x age (0..95)
*         $CLEAN/unit_year.dta: unit x year: living population, headcount
*
* Why: the years a death costs, ahat - a, depend on the exact age a, but GBD
* reports 5-year bins. Within a bin of width T we assume
*   (i)  one constant annual death rate m = deaths / pop_start for the bin, and
*   (ii) cohort sizes that fall geometrically with age at that rate.
* The end-of-year survivors E of the bin are then spread as
*   E_k = c * (1-m)^(k-1),  k = 1..T,  with  c = E*m / (1-(1-m)^T),
* so that sum_k E_k = E. Each single age then has start population
* P_k = E_k / (1-m) and deaths D_k = m * P_k, which add back to the bin's
* deaths exactly. The open bin 95+ is treated as one age at which everyone
* dies (maximum life-span 95), as in the paper (fn 28).
* =============================================================================
if "$ROOT" == "" {
    display as error "Run via scripts/00_master.do"
    exit 198
}

use "$CLEAN/panel_bins.dta", clear

* ---- bin-level death rate and survivors ------------------------------------
replace deaths = pop_start if age_lo == 95            // everyone dies at 95
gen double m       = deaths / pop_start
gen double end_bin = pop_start - deaths               // alive at end of year
assert inrange(m, 0, 1) & !missing(m)

* ---- unit-year file: living population and headcount -----------------------
* "Living population" in the paper = people alive at the END of the year.
preserve
    collapse (sum) pop_living = end_bin (first) hc_* region iso3 gbd_name, ///
        by(level unit year)
    label var pop_living "Living population (alive at end of year)"
    isid unit year
    save "$CLEAN/unit_year.dta", replace
restore

* ---- spread each bin over its single ages ----------------------------------
keep level unit year age_lo width m deaths pop_start end_bin
expand width
bysort unit year age_lo: gen byte k = _n
gen int age = age_lo + k - 1

gen double c = cond(m > 0, end_bin * m / (1 - (1 - m)^width), end_bin / width)
gen double end_a   = c * (1 - m)^(k - 1)
gen double start_a = cond(age == 95, pop_start, end_a / (1 - m))
gen double deaths_a = start_a * m

* ---- checks ----------------------------------------------------------------
* single ages add back to their bin (survivors and deaths)
bysort unit year age_lo: egen double chk_end = total(end_a)
bysort unit year age_lo: egen double chk_dth = total(deaths_a)
assert reldif(chk_end, end_bin)  < 1e-9
assert reldif(chk_dth, deaths) < 1e-9
bysort unit year: assert _N == 96 & age[1] == 0 & age[_N] == 95

keep level unit year age m start_a end_a deaths_a
label var age      "Single year of age"
label var m        "Annual death rate (constant within the GBD bin)"
label var start_a  "Alive at start of year"
label var end_a    "Alive at end of year"
label var deaths_a "Deaths during the year"
sort unit year age
compress
save "$CLEAN/single_ages.dta", replace
