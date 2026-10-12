* =============================================================================
* 07_counterfactuals.do: Figure 7, what drove the fall in life-span deprivation?
*
* Input : $CLEAN/single_ages.dta (World rows)
* Output: $CLEAN/counterfactuals.dta: year x scenario, GD life-span
*         component at ahat = 50
*
* Three counterfactual worlds, each holding one driver at its 1990 value
* (paper p.252):
*   births    : number of newborns (start-of-year population at age 0) = 1990
*   mortality : the whole age-specific death-rate vector m_a = 1990
*   both      : births and mortality both at 1990
* Everything else is the actual World pyramid of that year. Deaths and
* end-of-year survivors are recomputed single age by single age:
*   D_a = m_a * P_a,   E_a = (1 - m_a) * P_a.
*
* Method note: the authors aggregate these counterfactual single ages back to
* GBD bins and re-split them (VariableConstruction.do). We compute directly on
* single ages, which avoids a second round of the within-bin approximation.
* The two coincide for "births" (age 0 is its own bin) and differ only
* marginally otherwise; 20_compare.do reports the gap.
* =============================================================================
if "$ROOT" == "" {
    display as error "Run via scripts/00_master.do"
    exit 198
}

local ahat 50
local base 1990

use if unit == "World" using "$CLEAN/single_ages.dta", clear
keep year age m start_a

* 1990 values, attached to every year
preserve
    keep if year == `base'
    rename (m start_a) (m_base start_base)
    drop year
    tempfile base_vals
    save `base_vals'
restore
merge m:1 age using `base_vals', assert(match) nogen

local scenarios actual births mortality both
foreach s of local scenarios {
    gen double P_`s' = start_a
    gen double m_`s' = m
}
replace P_births = start_base if age == 0
replace P_both   = start_base if age == 0
replace m_mortality = m_base
replace m_both      = m_base

foreach s of local scenarios {
    gen double D_`s'  = m_`s' * P_`s'
    gen double E_`s'  = (1 - m_`s') * P_`s'
    gen double YL_`s' = D_`s' * max(`ahat' - age, 0)
}
collapse (sum) E_* YL_*, by(year)

foreach s of local scenarios {
    gen double ls_`s' = 100 * $GAMMA * YL_`s' / (E_`s' + YL_`s')
}
keep year ls_*
label var ls_actual    "World"
label var ls_births    "World, 1990 births"
label var ls_mortality "World, 1990 mortality"
label var ls_both      "World, 1990 births and mortality"

* ---- checks ----------------------------------------------------------------
* the "actual" scenario must reproduce 05_gd's World life-span component
preserve
    use unit year gd_ls_`ahat' if unit == "World" using "$CLEAN/gd.dta", clear
    drop unit
    tempfile world
    save `world'
restore
merge 1:1 year using `world', assert(match) nogen
assert reldif(ls_actual, gd_ls_`ahat') < 1e-9
* in 1990 every scenario is the actual world
foreach s in births mortality both {
    assert reldif(ls_`s', ls_actual) < 1e-12 if year == `base'
}
drop gd_ls_`ahat'
sort year
save "$CLEAN/counterfactuals.dta", replace
