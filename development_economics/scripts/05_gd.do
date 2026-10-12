* =============================================================================
* 05_gd.do: Generated Deprivation index, GD (paper eqs. 2-3, Section IV)
*
* Input : $CLEAN/single_ages.dta, $CLEAN/unit_year.dta
* Output: $CLEAN/gd.dta: unit x year, for every ahat in $AHAT and line in $PLINE
*
* Definitions, for one unit and year (gamma = $GAMMA):
*   PYPL_ahat = sum_{a < ahat} D_a * (ahat - a)    person-years prematurely lost
*   PYAD      = L * HC                             person-years in alive deprivation
*   REF       = L + PYPL                           reference population
*   GD        = (PYAD + gamma * PYPL) / REF
* where L is the living population and D_a are deaths at age a during the year.
*
* Timing: deaths are dated at the START of the year (paper fn 3), so a death
* at age a loses ahat - a years and a newborn's death loses exactly ahat
* (p.251). Equation (3)'s ahat - (a+1) is the end-of-year convention used only
* in the theory section.
* =============================================================================
if "$ROOT" == "" {
    display as error "Run via scripts/00_master.do"
    exit 198
}

* ---- person-years prematurely lost, by threshold ---------------------------
use "$CLEAN/single_ages.dta", clear
foreach ahat of global AHAT {
    gen double yl_`ahat'    = deaths_a * max(`ahat' - age, 0)
    gen double yl_u5_`ahat' = yl_`ahat' * (age < 5)
}
collapse (sum) yl_*, by(unit year)
foreach ahat of global AHAT {
    rename yl_`ahat'    pypl_`ahat'
    rename yl_u5_`ahat' pypl_u5_`ahat'
    label var pypl_`ahat'    "Person-years prematurely lost, ahat=`ahat'"
    label var pypl_u5_`ahat' "... of which from deaths under age 5"
}
merge 1:1 unit year using "$CLEAN/unit_year.dta", assert(match) nogen

* ---- GD for every threshold and line ---------------------------------------
foreach line of global PLINE {
    gen double pyad_`line' = pop_living * hc_`line'
    label var pyad_`line' "Person-years in alive deprivation, line `line'"
    foreach ahat of global AHAT {
        local s `ahat'_`line'
        capture confirm variable ref_`ahat'
        if _rc gen double ref_`ahat' = pop_living + pypl_`ahat'
        gen double gd_`s'         = 100 * (pyad_`line' + $GAMMA * pypl_`ahat') / ref_`ahat'
        gen double gd_inc_`s'     = 100 * pyad_`line' / ref_`ahat'
        capture confirm variable gd_ls_`ahat'
        if _rc gen double gd_ls_`ahat' = 100 * $GAMMA * pypl_`ahat' / ref_`ahat'
        gen double gd_lsshare_`s' = 100 * gd_ls_`ahat' / gd_`s'
        label var ref_`ahat'      "Reference population = living + PYPL, ahat=`ahat'"
        label var gd_`s'          "GD (%), ahat=`ahat', line `line', gamma=$GAMMA"
        label var gd_inc_`s'      "GD alive-deprivation component (%), ahat=`ahat', line `line'"
        label var gd_ls_`ahat'    "GD life-span component (%), ahat=`ahat', gamma=$GAMMA"
        label var gd_lsshare_`s'  "Life-span component as % of GD, ahat=`ahat', line `line'"
    }
    gen double hc_pct_`line' = 100 * hc_`line'
    label var hc_pct_`line' "Headcount ratio (%), line `line'"
}

* ---- checks ----------------------------------------------------------------
foreach line of global PLINE {
    foreach ahat of global AHAT {
        * components add up, and GD = HC when nobody dies prematurely
        assert reldif(gd_`ahat'_`line', gd_inc_`ahat'_`line' + gd_ls_`ahat') < 1e-9
        assert inrange(gd_`ahat'_`line', 0, 100)
    }
}
isid unit year
order level unit iso3 gbd_name region year pop_living hc_* pyad_* pypl_* ref_* gd_*
sort level unit year
compress
save "$CLEAN/gd.dta", replace
