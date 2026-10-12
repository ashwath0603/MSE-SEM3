* =============================================================================
* 06_id_gbd.do: Inherited Deprivation, ID (paper eq. 1), from GBD deaths
*
* Input : $CLEAN/single_ages.dta, $CLEAN/unit_year.dta
* Output: $CLEAN/id.dta: unit x year, life-span component of ID for each
*         threshold in `id_ahat'
*
* ID counts, in year Y, everybody born less than ahat years before Y who has
* already died: d_Y = sum of deaths in years t <= Y of people whose birth year
* t - a satisfies (t - a) + ahat > Y.
* So a death at age a in year t is "inherited" by every year from t to
* t + (ahat - a - 1); the person would still have been under ahat then.
*
* GBD starts in 1990, so d_Y is complete only from 1990 + ahat onwards. That is
* why the paper computes ID from GBD only for ahat = 5 (Haiti, Figure 3, from
* 1995). Deaths are dated at the start of the year, as in GD.
* =============================================================================
if "$ROOT" == "" {
    display as error "Run via scripts/00_master.do"
    exit 198
}

local id_ahat 5
local first_year 1990

use unit year age deaths_a using "$CLEAN/single_ages.dta", clear
tempfile deaths
save `deaths'

local first 1
foreach ahat of local id_ahat {
    use `deaths' if age < `ahat', clear
    * each death stays in the count for (ahat - a) years: t, t+1, ..., t+ahat-a-1
    gen int span = `ahat' - age
    expand span
    bysort unit year age: gen int Y = year + _n - 1
    collapse (sum) d_`ahat' = deaths_a, by(unit Y)
    rename Y year
    * only years with a full ahat-year death history are valid
    drop if year < `first_year' + `ahat'
    label var d_`ahat' "Prematurely dead (inherited), ahat=`ahat'"
    if !`first' merge 1:1 unit year using `id', nogen
    tempfile id
    save `id'
    local first 0
}

merge 1:1 unit year using "$CLEAN/unit_year.dta", keep(using match) nogen ///
    keepusing(level pop_living hc_*)
foreach ahat of local id_ahat {
    gen double id_ls_`ahat' = 100 * $GAMMA * d_`ahat' / (pop_living + d_`ahat')
    label var id_ls_`ahat' "ID life-span component (%), ahat=`ahat', gamma=$GAMMA"
    foreach line of global PLINE {
        gen double id_`ahat'_`line' = 100 * (pop_living * hc_`line' + $GAMMA * d_`ahat') ///
                                     / (pop_living + d_`ahat')
        label var id_`ahat'_`line' "ID (%), ahat=`ahat', line `line', gamma=$GAMMA"
    }
}
keep level unit year d_* id_*
isid unit year
sort unit year
compress
save "$CLEAN/id.dta", replace
