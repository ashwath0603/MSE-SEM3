* =============================================================================
* 03_panel.do: merge mortality and poverty, fix the sample, build aggregates
*
* Input : $CLEAN/gbd_bins.dta, $CLEAN/povcal_hc.dta, $RAW/region/WB_class.xls
* Output: $CLEAN/panel_bins.dta: one row per unit x year x age bin, where a
*         unit is a country (ISO3), a World Bank region, or the World
*
* Sample rule (paper p.250): low- and middle-income countries with a headcount
* in every year 1990-2015, observed in both GBD and PovCalNet.
* =============================================================================
if "$ROOT" == "" {
    display as error "Run via scripts/00_master.do"
    exit 198
}

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
display as result "03_panel: sample = " `n_countries' " countries (SAMPLE = $SAMPLE)"
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
