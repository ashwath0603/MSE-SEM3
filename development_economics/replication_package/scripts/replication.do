* =============================================================================
* replication.do: replication of Baland, Cassan & Decerf (2021), "Too Young to
*                 Die", AEJ: Applied Economics 13(4): 226-257, on the data in
*                 the authors' replication package
*
* Run:    from replication_package/ (or its scripts/ folder):
*             do scripts/replication.do
*         or in batch mode:  stata -b do scripts/replication.do
*         Run it as a do-file, not by pasting into the Command window: it uses
*         /// line breaks. Stata 17 or later; no user-written packages; ~1 min.
* Input:  data/119941-V1/   the authors' openICPSR package, unchanged
*         data/hmd/         Human Mortality Database, France (Figure 5 only)
*         See data/README.md for where each file came from.
* Output: output/tables/    Tables 1-4; targets.csv = every number quoted in
*                           Section IV, ours vs the paper; gd_countries.csv
*         output/figures/   Figures 2-10 (pdf and png)
*
* Intermediate datasets are written to a scratch folder in Stata's temp
* directory and deleted at the end, so data/ only ever holds source files.
*
* Steps
*   1  GBD 2017 deaths and rates -> population by age bin
*   2  PovCalNet headcount -> annual, interpolated
*   3  merge, the 113-country sample, regional and World aggregates
*   4  age bins -> single years 0..95
*   5  Generated Deprivation (GD) and its parts
*   6  Inherited Deprivation (ID) from GBD (Haiti, ahat = 5)
*   7  Figure 7 counterfactuals: 1990 births / mortality held fixed
*   8  Figure 5: France, HMD period life tables
*   9  Tables 1-2, Figures 2 and 4 (simulations, no data)
*   10 Tables 3-4 and every number quoted in Section IV
*   11 Figures 2-10
*   12 optional check against the authors' own code and Excel
* =============================================================================
version 17
clear all
set more off
set varabbrev off

* ---- locate this folder ----------------------------------------------------
capture confirm file "scripts/replication.do"
if _rc cd ..
confirm file "scripts/replication.do"

global ROOT  "`c(pwd)'"
global RAW   "$ROOT/data/119941-V1/Data"
global HMD   "$ROOT/data/hmd"
global TAB   "$ROOT/output/tables"
global FIG   "$ROOT/output/figures"
global CLEAN "`c(tmpdir)'/tytd_replication_work"

* ---- normative parameters --------------------------------------------------
* AHAT: age thresholds (years) below which a death is premature. 50 is the
*       paper's baseline; 5 is for Haiti (Figure 3), 40 for France (Figure 5),
*       80 for the "above 60%" sensitivity claim on p.251.
* GAMMA: weight of one person-year prematurely lost (PYPL) relative to one
*        person-year in alive deprivation (PYAD). The paper uses 1.
* PLINE: poverty line, as in the PovCalNet file names (1_9 = $1.90/day).
global AHAT  "5 40 50 80"
global GAMMA 1
global PLINE "1_9"

* SAMPLE: "paper" drops the three countries the authors' name join lost (see
*         step 3), so the sample is the paper's 113. "iso" joins on ISO3 codes
*         and keeps them (116), a robustness check.
global SAMPLE "paper"

* rmtree: delete a folder and everything in it (portable, no shell call)
capture program drop rmtree
program define rmtree
    args d
    local files : dir "`d'" files "*", respectcase
    foreach f of local files {
        erase "`d'/`f'"
    }
    local subs : dir "`d'" dirs "*", respectcase
    foreach s of local subs {
        rmtree "`d'/`s'"
    }
    rmdir "`d'"
end

foreach d in "$ROOT/output" "$TAB" "$FIG" {
    capture mkdir "`d'"
}
capture rmtree "$CLEAN"
mkdir "$CLEAN"

* =============================================================================
* STEP 1: GBD 2017 deaths -> population and deaths by age bin
*
* Input : $RAW/GBD/IHME-GBD_2017_DATA-f89cefb0-1.csv
*         (all-cause deaths, both sexes, 1990-2017, Number and Rate/100k)
*         $RAW/PovCalNet/PovCalNet1_9_2019.csv (only for its ISO3 codes)
* Output: $CLEAN/gbd_bins.dta: one row per iso3 x year x age bin
*
* GBD does not publish population in this extract. Since
*     rate = deaths / population * 100,000,
* the population alive at the start of the year in each bin is recovered as
*     pop_start = deaths / (rate / 100,000),
* truncated to whole persons, as the authors do.
* =============================================================================
* ---- 1. GBD name -> ISO3 crosswalk -----------------------------------------
* PovCalNet carries ISO3 codes; GBD carries only names. Exact name matches are
* taken as they are; the rest are listed by hand below. Countries outside
* PovCalNet are irrelevant: they have no headcount.
import delimited using "$RAW/PovCalNet/PovCalNet1_9_2019.csv", ///
    varnames(1) encoding("utf-8") clear
keep countrycode countryname
duplicates drop
rename (countrycode countryname) (iso3 gbd_name)
tempfile pcn_names
save `pcn_names'

clear
input str3 iso3 str40 gbd_name
"COD" "Democratic Republic of the Congo"
"COG" "Congo"
"CPV" "Cape Verde"
"EGY" "Egypt"
"FSM" "Federated States of Micronesia"
"GMB" "The Gambia"
"IRN" "Iran"
"KGZ" "Kyrgyzstan"
"KOR" "South Korea"
"LAO" "Laos"
"LCA" "Saint Lucia"
"MKD" "Macedonia"
"PSE" "Palestine"
"SVK" "Slovakia"
"SWZ" "Swaziland"
"SYR" "Syria"
"VEN" "Venezuela"
"YEM" "Yemen"
end
* Not in GBD 2017 at all: Tuvalu (TUV), Kosovo (XKX). They cannot enter.
append using `pcn_names'
duplicates drop gbd_name, force       // a hand entry and an exact match never collide
tempfile xwalk
save `xwalk'

* ---- 2. read GBD, keep the 21 mutually exclusive age bins ------------------
import delimited using "$RAW/GBD/IHME-GBD_2017_DATA-f89cefb0-1.csv", ///
    varnames(1) encoding("utf-8") asdouble clear
assert measure_name == "Deaths" & sex_name == "Both" & cause_name == "All causes"

* Bin start age and width, from the GBD label
gen int age_lo = .
gen int width  = .
replace age_lo = 0  if age_name == "<1 year"
replace width  = 1  if age_name == "<1 year"
replace age_lo = 1  if age_name == "1 to 4"
replace width  = 4  if age_name == "1 to 4"
forvalues a = 5(5)90 {
    replace age_lo = `a' if age_name == "`a' to `=`a'+4'"
    replace width  = 5   if age_name == "`a' to `=`a'+4'"
}
replace age_lo = 95 if age_name == "95 plus"
replace width  = 1  if age_name == "95 plus"   // nobody survives 95+: treated as age 95 only
keep if !missing(age_lo)                         // drops overlapping aggregates (Under 5, 80 plus, ...)

keep location_name year age_lo width metric_name val
replace metric_name = lower(metric_name)
reshape wide val, i(location_name year age_lo width) j(metric_name) string
rename (valnumber valrate) (deaths rate_100k)

* ---- 3. attach ISO3 --------------------------------------------------------
rename location_name gbd_name
merge m:1 gbd_name using `xwalk', keep(master match)
* GBD countries not in PovCalNet (mostly high-income) have no headcount
keep if _merge == 3
drop _merge

* ---- 4. population at the start of the year --------------------------------
gen double pop_start = floor(deaths / (rate_100k / 100000))
replace pop_start = 0 if deaths == 0 & missing(pop_start)

* ---- checks ----------------------------------------------------------------
* every country-year has all 21 bins, and population is non-negative
bysort iso3 year: assert _N == 21
assert pop_start >= 0 & !missing(pop_start)
assert deaths >= 0 & !missing(deaths)
isid iso3 year age_lo

order iso3 gbd_name year age_lo width deaths rate_100k pop_start
sort iso3 year age_lo
label var age_lo    "First age in the GBD age bin"
label var width     "Number of single years in the bin"
label var deaths    "Deaths during the year (GBD point estimate)"
label var rate_100k "Death rate per 100,000 (GBD point estimate)"
label var pop_start "Population alive at start of year = deaths/(rate/1e5), whole persons"
compress
save "$CLEAN/gbd_bins.dta", replace

quietly levelsof iso3
display as result "step 1: " r(r) " PovCalNet countries found in GBD"

* =============================================================================
* STEP 2: PovCalNet headcount ratio -> annual country series
*
* Input : $RAW/PovCalNet/PovCalNet<line>_2019.csv for each line in $PLINE
*         ("economies table", downloaded by the authors on 11 Dec 2019)
* Output: $CLEAN/povcal_hc.dta: one row per iso3 x year (1981-2015),
*         hc_<line> = share of population below the line (0-1)
*
* PovCalNet reports estimates only for "request years" (1981, 1984, ..., 2008,
* then 2010-2013 and 2015). Years in between are filled by linear interpolation
* within each country, never extrapolated beyond the first or last request year.
* =============================================================================
local first 1
foreach line of global PLINE {
    import delimited using "$RAW/PovCalNet/PovCalNet`line'_2019.csv", ///
        varnames(1) encoding("utf-8") asdouble clear
    * Coverage: N = national, A = national aggregate of separate urban/rural
    * surveys (China, India, Indonesia). R and U are the rural/urban parts.
    keep if inlist(coveragetype, "N", "A")
    keep countrycode requestyear headcount
    rename (countrycode requestyear headcount) (iso3 year hc_`line')
    isid iso3 year
    if !`first' merge 1:1 iso3 year using `pov', nogen
    tempfile pov
    save `pov'
    local first 0
}

* ---- fill every calendar year, then interpolate ----------------------------
summarize year, meanonly
local y0 = r(min)
local y1 = r(max)
* a full country x calendar-year grid, so ipolate has rows to fill
preserve
    keep iso3
    duplicates drop
    expand `y1' - `y0' + 1
    bysort iso3: gen int year = `y0' + _n - 1
    tempfile grid
    save `grid'
restore
merge 1:1 iso3 year using `grid', nogen

foreach line of global PLINE {
    bysort iso3 (year): ipolate hc_`line' year, gen(tmp)
    replace hc_`line' = tmp
    drop tmp
}

* ---- high-income flag ------------------------------------------------------
* "Absolute deprivation is irrelevant for high-income countries" (authors'
* code). Their list: the high-income economies in PovCalNet, accessed Feb 2020.
gen byte highincome = inlist(iso3, "AUS","AUT","BEL","CAN","CHL","HRV","CYP","CZE") ///
                    | inlist(iso3, "DNK","EST","FIN","FRA","DEU","GRC","HUN","ISL") ///
                    | inlist(iso3, "IRL","ISR","ITA","JPN","KOR","LVA","LTU","LUX") ///
                    | inlist(iso3, "MLT","NLD","NOR","PAN","POL","PRT","SYC","SVK") ///
                    | inlist(iso3, "SVN","ESP","SWE","CHE","TTO","GBR","USA","URY")
quietly count if highincome & year == `y0'
assert r(N) == 40

* ---- checks ----------------------------------------------------------------
isid iso3 year
foreach line of global PLINE {
    assert inrange(hc_`line', 0, 1) if !missing(hc_`line')
    label var hc_`line' "Headcount ratio, poverty line `line' USD/day (share), interpolated"
}
label var highincome "High-income economy (authors' list), excluded from the sample"
sort iso3 year
compress
save "$CLEAN/povcal_hc.dta", replace

* =============================================================================
* STEP 3: merge mortality and poverty, fix the sample, build aggregates
*
* Input : $CLEAN/gbd_bins.dta, $CLEAN/povcal_hc.dta, $RAW/region/WB_class.xls
* Output: $CLEAN/panel_bins.dta: one row per unit x year x age bin, where a
*         unit is a country (ISO3), a World Bank region, or the World
*
* Sample rule (paper p.250): low- and middle-income countries with a headcount
* in every year 1990-2015, observed in both GBD and PovCalNet.
* =============================================================================
* ---- 1. World Bank regions (by ISO3) ---------------------------------------
import excel using "$RAW/region/WB_class.xls", sheet("List of economies") ///
    firstrow clear
keep Code Region
rename (Code Region) (iso3 region)
keep if !missing(region) & strlen(iso3) == 3
tempfile regions
save `regions'

* ---- 2. merge mortality with poverty ---------------------------------------
use "$CLEAN/gbd_bins.dta", clear
merge m:1 iso3 year using "$CLEAN/povcal_hc.dta", keep(match) nogen
* GBD starts in 1990, PovCalNet ends in 2015: the overlap is 1990-2015
drop if highincome
drop highincome

* complete headcount series 1990-2015 only
local firstline : word 1 of $PLINE
bysort iso3: egen n_years = total(!missing(hc_`firstline') & age_lo == 0)
keep if n_years == 26
drop n_years

merge m:1 iso3 using `regions', keep(master match)
assert _merge == 3                   // every sample country has a WB region
drop _merge

* ---- 3. paper sample vs ISO3 sample ----------------------------------------
* Three eligible countries are missing from the authors' sample of 113:
*   - Eswatini (SWZ) and West Bank and Gaza (PSE): the authors join GBD and
*     PovCalNet on country *names*, and GBD calls them "Swaziland" and
*     "Palestine", so the join misses them.
*   - Kiribati (KIR): it is listed by name among the Japanese prefectures and
*     Mexican states that MergingGBDandPovcalNet.do drops as "subnational
*     entities", apparently by accident.
* Joining on ISO3 keeps all three (116 countries). "paper" reproduces the 113.
if "$SAMPLE" == "paper" drop if inlist(iso3, "SWZ", "PSE", "KIR")

quietly levelsof iso3
local n_countries = r(r)
display as result "step 3: sample = " `n_countries' " countries (SAMPLE = $SAMPLE)"
if "$SAMPLE" == "paper" assert `n_countries' == 113

gen str7 level = "country"
gen unit = iso3
tempfile countries
save `countries'

* ---- 4. regional and World aggregates --------------------------------------
* Deaths and population are summed bin by bin. The headcount is averaged with
* weights equal to each country's total start-of-year population.
bysort iso3 year: egen double pop_total = total(pop_start)
foreach line of global PLINE {
    gen double poor_`line' = hc_`line' * pop_total if age_lo == 0   // one row per country-year
}

foreach agg in region world {
    use `countries', clear
    bysort iso3 year: egen double pop_total = total(pop_start)
    foreach line of global PLINE {
        gen double poor_`line' = hc_`line' * pop_total if age_lo == 0
    }
    if "`agg'" == "world" replace region = "World"
    collapse (sum) deaths pop_start poor_* pop_total_c = pop_total ///
        (first) width, by(region year age_lo)
    * pop_total_c is summed over bins, so it repeats the country totals 21 times
    bysort region year: egen double denom = total(pop_total_c * (age_lo == 0))
    foreach line of global PLINE {
        bysort region year: egen double num = total(poor_`line')
        gen double hc_`line' = num / denom
        drop num
    }
    drop poor_* pop_total_c denom
    gen str7 level = cond("`agg'" == "world", "world", "region")
    gen unit = region
    tempfile agg_`agg'
    save `agg_`agg''
}

use `countries', clear
append using `agg_region' `agg_world'

* ---- checks ----------------------------------------------------------------
isid unit year age_lo
bysort unit year: assert _N == 21
foreach line of global PLINE {
    assert inrange(hc_`line', 0, 1)
}
* World totals equal the sum of the countries
preserve
    collapse (sum) deaths pop_start, by(level year)
    reshape wide deaths pop_start, i(year) j(level) string
    assert reldif(deathsworld, deathscountry) < 1e-9
    assert reldif(pop_startworld, pop_startcountry) < 1e-9
restore

order level unit iso3 gbd_name region year age_lo width deaths rate_100k pop_start hc_*
sort level unit year age_lo
label var level "country / region / world"
label var unit  "ISO3 for countries; region name; World"
compress
save "$CLEAN/panel_bins.dta", replace

* =============================================================================
* STEP 4: split GBD age bins into single years of age 0..95
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

* =============================================================================
* STEP 5: Generated Deprivation index, GD (paper eqs. 2-3, Section IV)
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

* =============================================================================
* STEP 6: Inherited Deprivation, ID (paper eq. 1), from GBD deaths
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

* =============================================================================
* STEP 7: Figure 7, what drove the fall in life-span deprivation?
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
* marginally otherwise; step 12 reports the gap.
* =============================================================================
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
* the "actual" scenario must reproduce step 5's World life-span component
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

* =============================================================================
* STEP 8: Figure 5, France 1816-today, life-span components of ID
*                   and GD at ahat = 40, from the Human Mortality Database
*
* Input : $HMD/lt_both.zip      period life tables, both sexes (bltper_1x1.txt)
*         $HMD/population.zip   population by single age, Jan 1 (Population.txt)
*         Both are HMD bulk files for all countries; France total = "FRATNP".
* Output: $CLEAN/hmd_france.dta: year x (ID and GD life-span components,
*         q0 and q20 in %)
*
* The paper's data readme asks for COHORT life tables, but Figure 5 can only
* be drawn from PERIOD tables: cohort tables stop at the 1933 cohort and date
* the WWI deaths of 20-year-olds to their birth year (1894), not to 1914-18.
* See notes/paper_notes.md section 3.
*
* With deaths dated at the start of the year (as in step 5):
*   D(y,a)  = N(y,a) * q(y,a)                deaths at age a in year y
*   GD_ls   = sum_a D(y,a)(ahat - a) / (N_y + that sum)
*   ID_ls   = d_y / (N_y + d_y), where d_y = deaths in years t <= y among
*             cohorts born after y - ahat (each death is "inherited" by the
*             ahat - a years in which the person would still be under ahat)
* N_y is the total population on 1 January. ID needs ahat years of history,
* so it starts in 1816 + ahat.
* =============================================================================
local ahat 40
local pop  FRATNP

foreach z in lt_both population {
    capture confirm file "$HMD/`z'.zip"
    if _rc {
        display as error "Missing $HMD/`z'.zip: see data/README.md"
        exit 601
    }
}

* ---- unzip into a scratch folder (raw zips stay untouched) -----------------
local tmp "$CLEAN/_hmd_unzipped"
capture mkdir "`tmp'"
local here "`c(pwd)'"
cd "`tmp'"
unzipfile "$HMD/lt_both.zip", replace
unzipfile "$HMD/population.zip", replace
cd "`here'"

* ---- period life table: q(y,a) ---------------------------------------------
* Line 1 is a title, line 2 blank, line 3 the column names.
import delimited using "`tmp'/bltper_1x1/bltper_1x1.txt", ///
    delimiters(" ", collapse) varnames(3) rowrange(4) stringcols(_all) clear
keep if popname == "`pop'"
keep year age qx
replace age = subinstr(age, "+", "", .)          // "110+" -> 110 (open interval)
destring year age qx, replace
tempfile lt
save `lt'

* ---- population on 1 January: N(y,a) ---------------------------------------
import delimited using "`tmp'/Population/Population.txt", ///
    delimiters(" ", collapse) varnames(3) rowrange(4) stringcols(_all) clear
keep if popname == "`pop'"
keep year age total
* Border-change years appear twice: "1914-" (old territory) and "1914+" (new
* territory). Keep the new-territory row, as the authors do.
drop if strpos(year, "-")
replace year = subinstr(year, "+", "", .)
replace age  = subinstr(age, "+", "", .)
destring year age total, replace
rename total N
isid year age
merge 1:1 year age using `lt', keep(match) nogen

* ---- deaths and the GD life-span component ---------------------------------
gen double D  = N * qx
gen double yl = D * max(`ahat' - age, 0)
preserve
    collapse (sum) N_tot = N yl, by(year)
    gen double gd_ls_`ahat' = 100 * yl / (N_tot + yl)
    keep year N_tot gd_ls_`ahat'
    tempfile gd
    save `gd'
restore

* ---- mortality rates at ages 0 and 20 (right panel) ------------------------
preserve
    keep if inlist(age, 0, 20)
    gen double q = 100 * qx
    keep year age q
    reshape wide q, i(year) j(age)
    tempfile q
    save `q'
restore

* ---- the ID life-span component --------------------------------------------
summarize year, meanonly
local y0 = r(min)
local y1 = r(max)
keep if age < `ahat' & year - age >= `y0'        // cohorts observed from birth
gen int span = `ahat' - age
expand span
bysort year age: gen int Y = year + _n - 1
collapse (sum) d = D, by(Y)
rename Y year
drop if year < `y0' + `ahat' | year > `y1'
merge 1:1 year using `gd', keep(using match) nogen
gen double id_ls_`ahat' = 100 * d / (N_tot + d)
merge 1:1 year using `q', nogen

label var gd_ls_`ahat' "GD life-span component (%), ahat=`ahat'"
label var id_ls_`ahat' "ID life-span component (%), ahat=`ahat'"
label var q0  "Mortality rate at age 0 (%)"
label var q20 "Mortality rate at age 20 (%)"
keep year gd_ls_`ahat' id_ls_`ahat' q0 q20
isid year
sort year
save "$CLEAN/hmd_france.dta", replace

* the HMD files are large: drop the unzipped copies
shell rm -r "`tmp'"

* =============================================================================
* STEP 9: the paper's analytical examples (no data needed)
*
* Output: $TAB/table1_composite.csv   Table 1  (composite index inconsistency)
*         $TAB/table2_hc_id.csv       Table 2  (HC vs ID on x, x', x'')
*         $CLEAN/sim_fig2.dta         Figure 2 (transitory shock, ahat = 3)
*         $CLEAN/sim_fig4.dta         Figure 4 (permanent shocks, ahat = 50)
*
* The simulations follow the THEORY timing (Section I): births at the start
* of a period, deaths at the end. So a death at age a loses ahat - (a+1)
* periods (eq. 3), and d(x) counts the dead among cohorts born less than ahat
* periods ago.
* =============================================================================
* ---- Table 1: composite P_w = w*HC + (1-w)*LD is inconsistent --------------
* Two births a year, maximum life 2 years, ahat = 2, w = 0.5.
* Society A: 1-year-olds Poor, Poor; B: Poor, Dead; C: Dead, Dead.
clear
input str9 society poor_1yo dead_1yo
"Society A" 2 0
"Society B" 1 1
"Society C" 0 2
end
gen double HC   = poor_1yo / (2 + poor_1yo)            // poor among the living (2 newborns non-poor)
gen double LD   = dead_1yo / 4                         // dead among the 4 born in the last 2 years
gen double P05  = 0.5 * HC + 0.5 * LD
gen double ID   = (poor_1yo + 1 * dead_1yo) / 4        // ID, gamma = 1, for contrast
format HC LD P05 ID %4.2f
list society HC LD P05 ID, noobs
export delimited society HC LD P05 ID using "$TAB/table1_composite.csv", replace

* ---- Table 2: HC cannot see premature death, ID can ------------------------
* x  = (young,NP), (young,D),  (old,D)
* x' = (young,NP), (young,NP), (old,D)
* x''= (young,NP), (young,AP), (old,D)
clear
input str4 dist young_AP young_NP young_D old_D
"x"    0 1 1 1
"x'"   0 2 0 1
"x''"  1 1 0 1
end
gen double HC = young_AP / (young_AP + young_NP)
* ID's reference population: everyone alive + the young dead (old dead excluded)
gen double ID_gamma1 = (young_AP + 1 * young_D) / (young_AP + young_NP + young_D)
gen double ID_gamma2 = (young_AP + 2 * young_D) / (young_AP + young_NP + young_D)
format HC ID_* %4.2f
list, noobs
export delimited using "$TAB/table2_hc_id.csv", replace

* ---- population simulator --------------------------------------------------
* simulate(): births B every period; MU is a (periods x ages) matrix of death
* rates, row s applying at the END of period s. Row 1 is a pre-shock period
* whose pyramid is stationary under MU[1,.]. Returns, per period,
* (population, d_GD, GD, ID) with gamma = 1 and no alive deprivation.
mata:
mata clear
real matrix simulate(real scalar B, real matrix MU, real scalar ahat)
{
    real scalar S, A, s, a, pop, dgd, d
    real rowvector n, nprev
    real matrix out
    S = rows(MU); A = cols(MU)
    out = J(S, 4, .)
    n = J(1, A, 0); n[1] = B
    for (a = 2; a <= A; a++) n[a] = n[a-1] * (1 - MU[1, a-1])   // stationary start
    for (s = 1; s <= S; s++) {
        if (s > 1) {
            nprev = n
            n[1] = B
            for (a = 2; a <= A; a++) n[a] = nprev[a-1] * (1 - MU[s-1, a-1])
        }
        pop = sum(n)
        dgd = 0; d = 0
        for (a = 1; a <= min((ahat, A)); a++) {
            dgd = dgd + n[a] * MU[s, a] * (ahat - a)      // age a-1 loses ahat-(a-1)-1
            d   = d + (B - n[a])                          // cohort born a-1 periods ago
        }
        for (a = A + 1; a <= ahat; a++) d = d + B         // cohorts older than max life, all dead
        out[s, .] = (pop, dgd, dgd / (pop + dgd), d / (pop + d))
    }
    return(out)
}
end

* ---- Figure 2: one-period shock, everybody dies at t = 0 -------------------
* n* = 1, mu* = (0, 0, 1), ahat = 3; mu^0 = (1, 1, 1). Periods -1..3.
mata:
MU = (0,0,1 \ 1,1,1 \ 0,0,1 \ 0,0,1 \ 0,0,1)
R  = simulate(1, MU, 3)
st_matrix("fig2", ((-1::3), R))
end
clear
svmat double fig2, names(col)
rename (c1 c2 c3 c4 c5) (t pop d_gd gd id)
list, noobs
* paper: ID = 0, 0, 2/3, 1/3, 0 and GD = 0, 1/2, 0, 0, 0
assert reldif(id[3], 2/3) < 1e-12 & reldif(id[4], 1/3) < 1e-12 & id[2] == 0
assert reldif(gd[2], 1/2) < 1e-12 & gd[3] == 0 & gd[4] == 0
save "$CLEAN/sim_fig2.dta", replace

* ---- Figure 4: permanent mortality shocks ----------------------------------
* 1,000 births a year, ages 0..100 (mu = 1 at 100), mu = 2% before the shock.
* The shock (to 1%) hits all ages, age 40 only, or age 10 only, at the end of
* period 0. Periods -1..100.
mata:
real matrix fig4(string scalar shock)
{
    real scalar B, A, S, ahat
    real rowvector pre, post
    B = 1000; A = 101; S = 102; ahat = 50
    pre = J(1, A, .02)
    pre[A] = 1
    post = pre
    if (shock == "all") {
        post = J(1, A, .01)
        post[A] = 1
    }
    if (shock == "age40") post[41] = .01      // column 41 = age 40
    if (shock == "age10") post[11] = .01
    return(((-1::100), simulate(B, pre \ J(S - 1, 1, post), ahat)))
}
st_matrix("fig4_all",   fig4("all"))
st_matrix("fig4_age40", fig4("age40"))
st_matrix("fig4_age10", fig4("age10"))
end
clear
tempfile f4
local first 1
foreach k in all age40 age10 {
    clear
    svmat double fig4_`k', names(col)
    rename (c1 c2 c3 c4 c5) (t pop d_gd gd id)
    gen str5 shock = "`k'"
    if !`first' append using `f4'
    save `f4', replace
    local first 0
}
replace gd = 100 * gd
replace id = 100 * id
label var gd "GD (%)"
label var id "ID (%)"
* stationary start: GD = ID (ID Equivalence), about 29.51%
assert reldif(gd, id) < 1e-12 if t == -1
sort shock t
save "$CLEAN/sim_fig4.dta", replace

* =============================================================================
* STEP 10: Tables 3 and 4 and every number quoted in Section IV
*
* Input : $CLEAN/gd.dta, $CLEAN/single_ages.dta
* Output: $TAB/table3_world.csv    Table 3 (World, 1990 and 2015)
*         $TAB/table4_gab_mar.csv  Table 4 (Gabon and Morocco, 1993)
*         $TAB/targets.csv         every published number: paper vs ours
*         $CLEAN/ranks.dta         country ranks by HC and by GD, per year
*
* A target PASSes when |ours - paper| <= tol (half a unit of the last printed
* digit). For the cells the authors filled in by hand from rounded rows
* (Tables 3 and 4), "ours_pr" redoes that same rounding chain on our numbers
* and the verdict uses it; "ours" is always the unrounded value.
* =============================================================================
tempname T
postfile `T' str8 id str70 target double(paper ours ours_pr tol) str70 note ///
    using "$TAB/targets.dta", replace

* ---- Table 3: World --------------------------------------------------------
use if unit == "World" & inlist(year, 1990, 2015) using "$CLEAN/gd.dta", clear
gen double living_m   = pop_living / 1e6
gen double hc         = hc_pct_1_9
gen double pyad_m     = pyad_1_9 / 1e6
gen double pypl_m     = pypl_50 / 1e6
gen double deprived_m = pyad_m + pypl_m
gen double ref_m      = ref_50 / 1e6
gen double gd1        = gd_50_1_9
preserve
    keep year living_m hc pyad_m pypl_m deprived_m ref_m gd1
    format living_m pyad_m pypl_m deprived_m ref_m %9.0fc
    format hc gd1 %4.1f
    list, noobs
    export delimited using "$TAB/table3_world.csv", replace
restore
foreach y in 1990 2015 {
    foreach v in living_m hc pyad_m pypl_m deprived_m ref_m gd1 {
        summarize `v' if year == `y', meanonly
        local `v'_`y' = r(mean)
    }
}
* The paper fills Table 3 by hand from rounded rows (see DescriptiveStats.do):
* living population to 10 m, HC to 0.1, PYPL to 1 m, then sums and ratios.
foreach y in 1990 2015 {
    local L_`y'    = round(`living_m_`y'', 10)
    local H_`y'    = round(`hc_`y'', .1)
    local A_`y'    = round(`L_`y'' * `H_`y'' / 100)
    local Y_`y'    = round(`pypl_m_`y'')
    local Dp_`y'   = `A_`y'' + `Y_`y''
    local R_`y'    = `L_`y'' + `Y_`y''
    local G_`y'    = 100 * `Dp_`y'' / `R_`y''
}
post `T' ("T3a") ("Table 3: living population 1990 (m)") (4200) (`living_m_1990') (`L_1990') (5) ("rounded to 10 m")
post `T' ("T3b") ("Table 3: living population 2015 (m)") (6010) (`living_m_2015') (`L_2015') (5) ("rounded to 10 m")
post `T' ("T3c") ("Table 3: HC 1990 (%)") (44.9) (`hc_1990') (.) (.05) ("")
post `T' ("T3d") ("Table 3: HC 2015 (%)") (11.7) (`hc_2015') (.) (.05) ("")
post `T' ("T3e") ("Table 3: PYAD 1990 (m)") (1886) (`pyad_m_1990') (`A_1990') (.5) ("paper: 4200 x 0.449 by hand")
post `T' ("T3f") ("Table 3: PYAD 2015 (m)") (703) (`pyad_m_2015') (`A_2015') (.5) ("paper: 6010 x 0.117 by hand; intro says 705")
post `T' ("T3g") ("Table 3: PYPL 1990 (m)") (701) (`pypl_m_1990') (.) (.5) ("")
post `T' ("T3h") ("Table 3: PYPL 2015 (m)") (402) (`pypl_m_2015') (.) (.5) ("")
post `T' ("T3i") ("Table 3: deprived population 1990 (m)") (2587) (`deprived_m_1990') (`Dp_1990') (.5) ("")
post `T' ("T3j") ("Table 3: deprived population 2015 (m)") (1105) (`deprived_m_2015') (`Dp_2015') (.5) ("")
post `T' ("T3k") ("Table 3: reference population 1990 (m)") (4901) (`ref_m_1990') (`R_1990') (.5) ("")
post `T' ("T3l") ("Table 3: reference population 2015 (m)") (6412) (`ref_m_2015') (`R_2015') (.5) ("")
post `T' ("T3m") ("Table 3: GD1 1990 (%)") (52.8) (`gd1_1990') (`G_1990') (.05) ("")
post `T' ("T3n") ("Table 3: GD1 2015 (%)") (17.2) (`gd1_2015') (`G_2015') (.05) ("paper divides rounded rows: 1105/6412")
post `T' ("I1") ("Intro: income poor 2015 (m)") (705) (`pyad_m_2015') (.) (.5) ("")

* ---- life-span share, thresholds, under-5 share ----------------------------
use if unit == "World" using "$CLEAN/gd.dta", clear
foreach y in 1990 2015 {
    summarize gd_lsshare_50_1_9 if year == `y', meanonly
    local sh_`y' = r(mean)
    summarize pypl_u5_50 if year == `y', meanonly
    local u5 = r(mean)
    summarize pypl_50 if year == `y', meanonly
    local u5_`y' = 100 * `u5' / r(mean)
}
summarize gd_lsshare_80_1_9 if year == 2015, meanonly
local sh80 = r(mean)
post `T' ("S1") ("Life-span share of GD 1990 (%)") (27) (`sh_1990') (.) (.5) ("p.251")
post `T' ("S2") ("Life-span share of GD 2015 (%), 'more than 36'") (36) (`sh_2015') (.) (.5) ("p.251")
post `T' ("S3") ("Life-span share of GD 2015, ahat=80 (%), 'more than 60'") (60) (`sh80') (.) (.5) ("p.251")
post `T' ("S4") ("Under-5 deaths, share of PYPL 1990 (%), 'almost 80'") (80) (`u5_1990') (.) (2.5) ("p.251, approximate")
post `T' ("S5") ("Under-5 deaths, share of PYPL 2015 (%), 'close to 70'") (70) (`u5_2015') (.) (2.5) ("p.251, approximate")

* ---- newborns: mortality and natality --------------------------------------
use if unit == "World" & age == 0 using "$CLEAN/single_ages.dta", clear
foreach y in 1990 2015 {
    summarize m if year == `y', meanonly
    local m0_`y' = 100 * r(mean)
    summarize start_a if year == `y', meanonly
    local b_`y' = r(mean)
}
local natal = 100 * (`b_2015' / `b_1990' - 1)
post `T' ("N1") ("Newborn mortality rate 1990 (%)") (6.6) (`m0_1990') (.) (.05) ("p.252")
post `T' ("N2") ("Newborn mortality rate 2015 (%)") (3.4) (`m0_2015') (.) (.05) ("p.252")
post `T' ("N3") ("Change in births 1990-2015 (%)") (2.8) (`natal') (.) (.05) ("p.252")

* ---- median age at death ---------------------------------------------------
* Deaths at single ages, countries only, pooled over 1990-2015 (as the
* authors' code does, with whole-person frequency weights).
use if level == "country" using "$CLEAN/single_ages.dta", clear
gen long w = int(deaths_a)
summarize age [fw = w], detail
local med_all = r(p50)
summarize age [fw = w] if year == 1990, detail
local med_1990 = r(p50)
post `T' ("A1") ("Median age at death (pooled 1990-2015)") (64) (`med_all') (.) (.5) ("p.249; 1990 alone: `med_1990'")

* ---- ranks -----------------------------------------------------------------
use if level == "country" using "$CLEAN/gd.dta", clear
quietly levelsof unit
post `T' ("C1") ("Number of countries") (113) (r(r)) (.) (0) ("")
* rank 1 = least deprived; ties broken by ISO3 so the result is reproducible
sort year hc_pct_1_9 unit
by year: gen int rank_hc = _n
sort year gd_50_1_9 unit
by year: gen int rank_gd = _n
gen int rank_change = rank_gd - rank_hc
gen int rank_abs    = abs(rank_change)
save "$CLEAN/ranks.dta", replace

summarize rank_abs, meanonly
local r_all = r(mean)
summarize rank_abs if year == 1990, meanonly
local r_1990 = r(mean)
summarize rank_abs if year == 2015, meanonly
local r_2015 = r(mean)
post `T' ("R1") ("Average |rank change| HC->GD, all years") (4.1) (`r_all') (.) (.05) ("p.253")
post `T' ("R2") ("Average |rank change| 1990") (4.4) (`r_1990') (.) (.05) ("p.253")
post `T' ("R3") ("Average |rank change| 2015") (4.9) (`r_2015') (.) (.05) ("p.253")
foreach c in GAB MAR {
    foreach r in hc gd {
        summarize rank_`r' if unit == "`c'" & year == 1993, meanonly
        local `c'_`r' = r(mean)
    }
}
post `T' ("R4") ("Gabon rank by HC, 1993") (19) (`GAB_hc') (.) (0) ("p.253")
post `T' ("R5") ("Gabon rank by GD, 1993") (38) (`GAB_gd') (.) (0) ("p.253")
post `T' ("R6") ("Morocco rank by HC, 1993") (21) (`MAR_hc') (.) (0) ("p.253")
post `T' ("R7") ("Morocco rank by GD, 1993") (32) (`MAR_gd') (.) (0) ("p.253")
foreach y in 2010 2014 {
    summarize rank_change if unit == "AZE" & year == `y', meanonly
    local aze_`y' = r(mean)
}
summarize rank_abs, meanonly
local rmax = r(max)
levelsof unit if rank_abs == `rmax', local(who) clean
levelsof year if rank_abs == `rmax', local(when) clean
post `T' ("R8") ("Azerbaijan ranks lost, 2010") (26) (`aze_2010') (.) (0) ("largest in data: `rmax' (`who' `when')")
post `T' ("R9") ("Azerbaijan ranks lost, 2014") (26) (`aze_2014') (.) (0) ("")

* ---- country trends --------------------------------------------------------
foreach v in hc_pct_1_9 gd_50_1_9 {
    foreach cy in COM_1990 COM_2015 BWA_1990 BWA_2000 BWA_2001 {
        gettoken c y : cy, parse("_")
        local y = subinstr("`y'", "_", "", .)
        summarize `v' if unit == "`c'" & year == `y', meanonly
        local `v'_`cy' = r(mean)
    }
}
post `T' ("K1") ("Comoros HC change 1990-2015 (%)") (60) (100*(`hc_pct_1_9_COM_2015'/`hc_pct_1_9_COM_1990'-1)) (.) (.5) ("p.253")
post `T' ("K2") ("Comoros GD change 1990-2015 (%)") (-23) (100*(`gd_50_1_9_COM_2015'/`gd_50_1_9_COM_1990'-1)) (.) (.5) ("p.253")
post `T' ("K3") ("Botswana HC change 1990-2001 (%)") (-12) (100*(`hc_pct_1_9_BWA_2001'/`hc_pct_1_9_BWA_1990'-1)) (.) (.5) ("p.255")
post `T' ("K4") ("Botswana GD change 1990-2001 (%)") (.7) (100*(`gd_50_1_9_BWA_2001'/`gd_50_1_9_BWA_1990'-1)) (.) (.05) ("p.255")
post `T' ("K5") ("Botswana HC 1990 (%)") (33.6) (`hc_pct_1_9_BWA_1990') (.) (.05) ("p.226, intro")
post `T' ("K6") ("Botswana HC 2000 (%)") (29.5) (`hc_pct_1_9_BWA_2000') (.) (.05) ("p.226, intro")

* ---- 5-year reversals (Figure 10) ------------------------------------------
* Share of country-years in which GD and HC move in opposite directions over
* five years. "gamma -> infinity" compares the life-span component alone.
xtset, clear
encode unit, gen(cid)
xtset cid year
gen double r_hc = hc_pct_1_9 / L5.hc_pct_1_9
gen double r_gd = gd_50_1_9  / L5.gd_50_1_9
gen double r_ls = gd_ls_50   / L5.gd_ls_50
gen byte rev_gd = (r_gd > 1 & r_hc < 1) | (r_gd < 1 & r_hc > 1) if !missing(r_gd, r_hc)
gen byte rev_ls = (r_ls > 1 & r_hc < 1) | (r_ls < 1 & r_hc > 1) if !missing(r_ls, r_hc)
summarize rev_gd, meanonly
local rev_gd = 100 * r(mean)
summarize rev_ls, meanonly
local rev_ls = 100 * r(mean)
post `T' ("V1") ("Reversals HC vs GD, 5-year, gamma=1 (%)") (8.4) (`rev_gd') (.) (.05) ("p.255")
post `T' ("V2") ("Reversals, gamma -> infinity (%)") (26.9) (`rev_ls') (.) (.05) ("p.255")
keep unit year r_hc r_gd r_ls rev_gd rev_ls
save "$CLEAN/reversals.dta", replace

* ---- Table 4: Gabon and Morocco, 1993 --------------------------------------
use if inlist(unit, "GAB", "MAR") & year == 1993 using "$CLEAN/gd.dta", clear
gen double living_k   = pop_living / 1e3
gen double hc         = hc_pct_1_9
gen double pyad_k     = pyad_1_9 / 1e3
gen double pypl_k     = pypl_50 / 1e3
gen double deprived_k = pyad_k + pypl_k
gen double ref_k      = ref_50 / 1e3
gen double gd1        = gd_50_1_9
keep unit living_k hc pyad_k pypl_k deprived_k ref_k gd1
format living_k pyad_k pypl_k deprived_k ref_k %9.0fc
format hc gd1 %4.1f
list, noobs
export delimited using "$TAB/table4_gab_mar.csv", replace
foreach c in GAB MAR {
    foreach v in living_k hc pyad_k pypl_k ref_k gd1 {
        summarize `v' if unit == "`c'", meanonly
        local `c'_`v' = r(mean)
    }
}
* Table 4 is also typed by hand: Gabon's living population is truncated
* (1043.76 -> 1043), Morocco's rounded; HC to 0.1; PYPL to 1,000.
local gL = floor(`GAB_living_k')
local gY = round(`GAB_pypl_k')
local gA = round(`gL' * round(`GAB_hc', .1) / 100)
local gR = `gL' + `gY'
local gG = 100 * (`gA' + `gY') / `gR'
post `T' ("T4a") ("Table 4: Gabon living population (k)") (1043) (`GAB_living_k') (`gL') (.5) ("")
post `T' ("T4b") ("Table 4: Gabon HC (%)") (5.2) (`GAB_hc') (.) (.05) ("")
post `T' ("T4c") ("Table 4: Gabon PYPL (k)") (174) (`GAB_pypl_k') (.) (.5) ("")
post `T' ("T4d") ("Table 4: Gabon reference population (k)") (1217) (`GAB_ref_k') (`gR') (.5) ("")
post `T' ("T4e") ("Table 4: Gabon GD1 (%)") (17.9) (`GAB_gd1') (`gG') (.05) ("authors' do-file: 1043+174 typed as 1271")
post `T' ("T4f") ("Table 4: Morocco living population (k)") (26449) (`MAR_living_k') (.) (.5) ("")
post `T' ("T4g") ("Table 4: Morocco HC (%)") (5.8) (`MAR_hc') (.) (.05) ("")
post `T' ("T4h") ("Table 4: Morocco PYPL (k)") (3100) (`MAR_pypl_k') (.) (.5) ("")
post `T' ("T4i") ("Table 4: Morocco GD1 (%)") (15.7) (`MAR_gd1') (.) (.05) ("")

postclose `T'

* ---- verdicts --------------------------------------------------------------
use "$TAB/targets.dta", clear
gen double ours_cmp = cond(missing(ours_pr), ours, ours_pr)
gen str4 status = cond(abs(ours_cmp - paper) <= tol + 1e-9, "PASS", "DIFF")
drop ours_cmp
format paper ours ours_pr %12.2f
list id paper ours ours_pr status note, noobs abbreviate(8) separator(0) linesize(200)
count if status == "DIFF"
display as result "step 10: " _N - r(N) " of " _N " published numbers reproduced; " r(N) " differ (see note column)"
export delimited using "$TAB/targets.csv", replace
erase "$TAB/targets.dta"

* ---- country GD by year: a table of its own, and the input that
* constructed.do compares against --------------------------------------------
use level iso3 gbd_name region year pop_living hc_pct_1_9 gd_50_1_9 if level == "country" using "$CLEAN/gd.dta", clear
drop level
sort iso3 year
export delimited using "$TAB/gd_countries.csv", replace

* =============================================================================
* STEP 11: Figures 2-10 of the paper (Figure 1 is a schematic)
*
* Input : $CLEAN/{gd,id,counterfactuals,reversals,sim_fig2,sim_fig4}.dta
*         $CLEAN/hmd_france.dta (Figure 5, only if step 8 has run)
* Output: $FIG/figNN_*.pdf and .png
* =============================================================================
set scheme s1mono
local dark  "gs5"
local light "gs12"

capture program drop savefig
program define savefig
    args name
    graph export "$FIG/`name'.pdf", replace
    graph export "$FIG/`name'.png", replace width(2000)
end

* ---- Figure 2: transitory shock, ID vs GD (ahat = 3) -----------------------
use "$CLEAN/sim_fig2.dta", clear
twoway (connected id t, lpattern(solid) msymbol(O)) ///
       (connected gd t, lpattern(dash) msymbol(T)), ///
    xlabel(-1(1)3) ylabel(0 "0" .3333 "1/3" .5 "1/2" .6667 "2/3", angle(0)) ///
    xtitle("Period (shock in t = 0)") ytitle("Deprivation") ///
    legend(order(1 "ID" 2 "GD") rows(1) position(6))
savefig fig02_transitory_shock

* ---- Figure 3: Haiti, life-span components, ahat = 5 -----------------------
use if unit == "HTI" & year >= 1995 using "$CLEAN/gd.dta", clear
merge 1:1 unit year using "$CLEAN/id.dta", keep(master match) nogen keepusing(id_ls_5)
twoway (line gd_ls_5 year, lpattern(solid)) (line id_ls_5 year, lpattern(dash)), ///
    xlabel(1995(5)2015) ylabel(.5(.5)2, angle(0)) xtitle("Year") ytitle("Percent") ///
    legend(order(1 "Life-span deprivation (GD)" 2 "Life-span deprivation (ID)") ///
           cols(1) position(7) ring(0))
savefig fig03_haiti

* ---- Figure 4: permanent mortality shocks, ahat = 50 -----------------------
use "$CLEAN/sim_fig4.dta", clear
local t_all   "Permanent shock to all mortality rates"
local t_age40 "Permanent shock to mortality rate at age 40"
local t_age10 "Permanent shock to mortality rate at age 10"
foreach k in all age40 age10 {
    twoway (line gd t if shock == "`k'", lpattern(dash)) ///
           (line id t if shock == "`k'", lpattern(solid)), ///
        title("`t_`k''", size(medium)) xlabel(-1 4(5)99, labsize(small)) ///
        ylabel(, angle(0) format(%5.2f)) xtitle("Years since permanent shock") ///
        ytitle("Deprivation (%)") legend(order(1 "GD" 2 "ID") rows(1) position(1) ring(0)) ///
        name(f4_`k', replace) nodraw
}
graph combine f4_all f4_age40 f4_age10, cols(1) ysize(9) xsize(6.5)
savefig fig04_permanent_shocks

* ---- Figure 5: France (needs the HMD files) --------------------------------
capture confirm file "$CLEAN/hmd_france.dta"
if _rc {
    display as error "Figure 5 skipped: run step 8 once data/hmd/ is filled"
}
else {
    use "$CLEAN/hmd_france.dta", clear
    twoway (line gd_ls_40 year, lpattern(solid)) (line id_ls_40 year, lpattern(dash)) ///
        if inrange(year, 1846, 2017) & !missing(id_ls_40), ///
        xlabel(1850(50)2000) ylabel(, angle(0)) xtitle("Year") ytitle("Percent") ///
        title("Life-span component of ID and GD, ahat = 40", size(medsmall)) ///
        legend(order(1 "GD's life-span component" 2 "ID's life-span component") cols(1) ///
               position(1) ring(0)) name(f5a, replace) nodraw
    twoway (line q0 year, lpattern(solid)) (line q20 year, lpattern(dash)) ///
        if inrange(year, 1846, 2017), ///
        xlabel(1850(50)2000) ylabel(, angle(0)) xtitle("Year") ytitle("Percent") ///
        title("Mortality rates at ages 0 and 20", size(medsmall)) ///
        legend(order(1 "0 years old" 2 "20 years old") cols(1) position(1) ring(0)) ///
        name(f5b, replace) nodraw
    graph combine f5a f5b, rows(1) xsize(10) ysize(4.5)
    savefig fig05_france
}

* ---- Figure 6: World GD decomposition, ahat = 50 ---------------------------
use if unit == "World" using "$CLEAN/gd.dta", clear
twoway (area gd_50_1_9 year, color(`dark')) ///
       (area gd_ls_50 year, color(`light')) ///
       (line hc_pct_1_9 year, lcolor(black) lwidth(medthick)) ///
       (line gd_lsshare_50_1_9 year, yaxis(2) lcolor(black) lpattern(dash) lwidth(medthick)), ///
    xlabel(1990(2)2014, angle(90)) xtitle("Year") ///
    ylabel(0(10)70, angle(0)) ytitle("Percent") ///
    ylabel(15(5)70, axis(2) angle(0)) ytitle("Percent", axis(2)) ///
    legend(order(1 "Income deprivation" 2 "Life-span deprivation (LDC)" ///
                 3 "Head-count ratio" 4 "LDC/GD (right axis)") cols(1) position(1) ring(0))
savefig fig06_world_decomposition

* ---- Figure 7: counterfactual worlds ---------------------------------------
use "$CLEAN/counterfactuals.dta", clear
twoway (line ls_actual year, lpattern(solid)) ///
       (line ls_mortality year, lpattern(shortdash)) ///
       (line ls_births year, lpattern(dash)) ///
       (line ls_both year, lpattern(longdash_dot)), ///
    xlabel(1990(2)2014, angle(90)) ylabel(6(2)14, angle(0)) xtitle("Year") ytitle("Percent") ///
    legend(order(1 "World" 2 "World, 1990 mortality" 3 "World, 1990 births" ///
                 4 "World, 1990 births and mortality") cols(1) position(7) ring(0))
savefig fig07_counterfactuals

* ---- Figure 8: Gabon vs Morocco --------------------------------------------
use if inlist(unit, "GAB", "MAR") using "$CLEAN/gd.dta", clear
twoway (line hc_pct_1_9 year if unit == "GAB", lpattern(dash)) ///
       (line hc_pct_1_9 year if unit == "MAR", lpattern(solid)), ///
    title("Head-count ratio", size(medium)) xlabel(1990(5)2015) ylabel(, angle(0)) ///
    xtitle("Year") ytitle("Percent") legend(order(1 "Gabon" 2 "Morocco") cols(1) ///
    position(7) ring(0)) name(f8a, replace) nodraw
twoway (line gd_50_1_9 year if unit == "GAB", lpattern(dash)) ///
       (line gd_50_1_9 year if unit == "MAR", lpattern(solid)), ///
    title("Total deprivation (GD)", size(medium)) xlabel(1990(5)2015) ylabel(, angle(0)) ///
    xtitle("Year") ytitle("Percent") legend(order(1 "Gabon" 2 "Morocco") cols(1) ///
    position(7) ring(0)) name(f8b, replace) nodraw
graph combine f8a f8b, rows(1) xsize(10) ysize(4.5)
savefig fig08_gabon_morocco

* ---- Figure 9: Comoros and Botswana ----------------------------------------
use if inlist(unit, "COM", "BWA") using "$CLEAN/gd.dta", clear
local n_COM "Comoros"
local n_BWA "Botswana"
local y_COM "0(10)30"
local y_BWA "0(10)50"
foreach c in COM BWA {
    twoway (area gd_50_1_9 year if unit == "`c'", color(`dark')) ///
           (area gd_ls_50 year if unit == "`c'", color(`light')) ///
           (line hc_pct_1_9 year if unit == "`c'", lcolor(black) lpattern(shortdash) lwidth(medthick)), ///
        title("`n_`c''", size(medium)) xlabel(1990(2)2014, angle(90)) ylabel(`y_`c'', angle(0)) ///
        xtitle("Year") ytitle("Percent") ///
        legend(order(1 "Income deprivation" 2 "Life-span deprivation" 3 "Head-count ratio") cols(1) size(small)) ///
        name(f9_`c', replace) nodraw
}
graph combine f9_COM f9_BWA, rows(1) xsize(10) ysize(4.5)
savefig fig09_comoros_botswana

* ---- Figure 10: five-year trends, GD vs HC ---------------------------------
use "$CLEAN/reversals.dta", clear
twoway (scatter r_gd r_hc if r_hc < 3, msize(vsmall) mcolor(gs6)) ///
       (function y = x, range(0.3 2) lpattern(dash) lcolor(black)), ///
    xline(1, lpattern(dash) lcolor(black)) yline(1, lpattern(dash) lcolor(black)) ///
    xlabel(0(1)3) ylabel(0(1)3, angle(0)) ///
    xtitle("HC{sub:t}/HC{sub:t-5}") ytitle("GD{sub:t}/GD{sub:t-5}") legend(off) aspectratio(1)
savefig fig10_trend_reversals

* =============================================================================
* STEP 12: verify our replication against the authors' own output
*
* Input : $CLEAN/gd.dta (ours)
*         benchmark/Data/CleanedData/PovertyMortalityWorld.dta (authors' code,
*         run unmodified apart from macOS patches; see benchmark/PATCHES.md)
* Output: $TAB/compare_benchmark.csv: for each variable, the number of
*         observations compared and the largest absolute and relative gaps.
*         Covers GD and its parts (05), ID (06), the counterfactual worlds (07)
*         and the Figure 4 simulation (09, against the authors' Excel sheet).
*
* The benchmark is used ONLY here. Nothing upstream reads it.
* =============================================================================
local BENCH "$ROOT/../benchmark/Data/CleanedData/PovertyMortalityWorld.dta"
* Optional: runs only if the authors' code has been run in ../benchmark/
* (zsh benchmark/apply_patches.sh, then cd benchmark && stata -b do Code/Master.do).
local have_bench = 1
capture confirm file "`BENCH'"
if _rc {
    local have_bench = 0
    display as text "STEP 12 skipped: the authors' code has not been run in ../benchmark/"
}
if `have_bench' {

    * ---- authors' output, renamed to our variable names ------------------------
    use "`BENCH'", clear
    * Their unit key is a name stripped of spaces and punctuation; ours is ISO3 for
    * countries and the region name for aggregates.
    gen unit = cond(country == region, country, country_code)
    keep unit year tot_pop_alive_end HC_1_9 gd_income_poor_1_9 ///
         gd_tot_lifespan_poor_* gd_pop_total_* gd_totalpoor_sh_*_1_9_1 ///
         gd_lifespanpoor_sh_*_1 gd_ratio_*_1_9_1 id_lifespanpoor_sh_5_1
    drop if strpos(unit, "World_point")         // counterfactual worlds: below
    rename (tot_pop_alive_end HC_1_9 gd_income_poor_1_9) (b_pop_living b_hc_pct_1_9 b_pyad_1_9)
    foreach ahat of global AHAT {
        rename gd_tot_lifespan_poor_`ahat'    b_pypl_`ahat'
        rename gd_pop_total_`ahat'            b_ref_`ahat'
        rename gd_totalpoor_sh_`ahat'_1_9_1   b_gd_`ahat'_1_9
        rename gd_lifespanpoor_sh_`ahat'_1    b_gd_ls_`ahat'
        rename gd_ratio_`ahat'_1_9_1          b_gd_lsshare_`ahat'_1_9
    }
    rename id_lifespanpoor_sh_5_1 b_id_ls_5
    keep unit year b_*
    tempfile bench
    save `bench'

    * ---- ours ------------------------------------------------------------------
    use "$CLEAN/gd.dta", clear
    * aggregate names in the authors' style: no spaces or punctuation
    replace unit = ustrregexra(unit, "[ &,.'-]", "") if level != "country"
    merge 1:1 unit year using "$CLEAN/id.dta", keepusing(id_ls_5) nogen
    merge 1:1 unit year using `bench'
    quietly count if _merge != 3
    if r(N) {
        display as error "Unit-years not in both files:"
        list unit year _merge if _merge != 3
    }
    keep if _merge == 3
    drop _merge

    * ---- gap table -------------------------------------------------------------
    local vars pop_living hc_pct_1_9 pyad_1_9
    foreach ahat of global AHAT {
        local vars `vars' pypl_`ahat' ref_`ahat' gd_`ahat'_1_9 gd_ls_`ahat' gd_lsshare_`ahat'_1_9
    }
    local vars `vars' id_ls_5
    tempname h
    postfile `h' str24 variable long n double max_abs_gap max_rel_gap using "$TAB/compare_benchmark.dta", replace
    foreach v of local vars {
        quietly {
            gen double _a = abs(`v' - b_`v')
            gen double _r = reldif(`v', b_`v')
            count if !missing(`v', b_`v')
            local n = r(N)
            summarize _a, meanonly
            local ma = r(max)
            summarize _r, meanonly
            local mr = r(max)
            drop _a _r
        }
        post `h' ("`v'") (`n') (`ma') (`mr')
    }

    * ---- counterfactual worlds (Figure 7) --------------------------------------
    use if strpos(country, "World") using "`BENCH'", clear
    keep country year gd_lifespanpoor_sh_50_1
    replace country = subinstr(country, "World_point", "", .)
    rename gd_lifespanpoor_sh_50_1 b
    reshape wide b, i(year) j(country) string
    merge 1:1 year using "$CLEAN/counterfactuals.dta", assert(match) nogen
    foreach pair in "ls_births bbirths" "ls_mortality bmortality" "ls_both bmortalitynatality" {
        gettoken ours theirs : pair
        quietly {
            gen double _a = abs(`ours' - `theirs')
            gen double _r = reldif(`ours', `theirs')
            summarize _a, meanonly
            local ma = r(max)
            summarize _r, meanonly
            local mr = r(max)
            count
            local n = r(N)
            drop _a _r
        }
        post `h' ("cf_`ours'") (`n') (`ma') (`mr')
    }

    * ---- Figure 4 simulation vs the authors' Excel sheet -----------------------
    * Columns FC-FF of each sheet: population, d_GD, GD, ID (shares),
    * rows 13 (t*-1) to 114 (t*+100).
    local XL "$ROOT/data/119941-V1/Figure 4/Figure_4_MortalityShocks.xlsx"
    foreach k in all age40 age10 {
        local sheet = cond("`k'" == "all", "Permanent_shock_uniform", ///
                      cond("`k'" == "age40", "Permanent_shock_40", "Permanent_shock_10"))
        import excel using "`XL'", sheet("`sheet'") cellrange(FC13:FF114) clear
        rename (FC FD FE FF) (x_pop x_dgd x_gd x_id)
        gen int t = _n - 2
        gen str5 shock = "`k'"
        merge 1:1 shock t using "$CLEAN/sim_fig4.dta", keep(match) nogen keepusing(gd id)
        foreach v in gd id {
            quietly {
                gen double _a = abs(`v' - 100 * x_`v')
                gen double _r = reldif(`v', 100 * x_`v')
                summarize _a, meanonly
                local ma = r(max)
                summarize _r, meanonly
                local mr = r(max)
                count
                local n = r(N)
                drop _a _r
            }
            post `h' ("fig4_`k'_`v'") (`n') (`ma') (`mr')
        }
    }
    * ---- France, HMD (Figure 5) -------------------------------------------------
    local BHMD "$ROOT/../benchmark/Data/CleanedData/HMD_mortality.dta"
    capture confirm file "`BHMD'"
    if !_rc {
        use year gd_lifespanpoor_sh_40_1 id_lifespanpoor_sh_40_1 using "`BHMD'", clear
        merge 1:1 year using "$CLEAN/hmd_france.dta", keep(match) nogen
        foreach pair in "gd_ls_40 gd_lifespanpoor_sh_40_1" "id_ls_40 id_lifespanpoor_sh_40_1" {
            gettoken ours theirs : pair
            quietly {
                gen double _a = abs(`ours' - `theirs')
                gen double _r = reldif(`ours', `theirs')
                count if !missing(`ours', `theirs')
                local n = r(N)
                summarize _a, meanonly
                local ma = r(max)
                summarize _r, meanonly
                local mr = r(max)
                drop _a _r
            }
            post `h' ("france_`ours'") (`n') (`ma') (`mr')
        }
    }
    postclose `h'
    use "$TAB/compare_benchmark.dta", clear
    format max_abs_gap max_rel_gap %12.3g
    list, noobs abbreviate(24)
    export delimited using "$TAB/compare_benchmark.csv", replace
    erase "$TAB/compare_benchmark.dta"
}

* ---- remove the scratch folder ---------------------------------------------
rmtree "$CLEAN"
display as result "replication.do finished: " c(current_date) " " c(current_time)
