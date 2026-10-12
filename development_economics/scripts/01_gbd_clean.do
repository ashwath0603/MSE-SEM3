* =============================================================================
* 01_gbd_clean.do: GBD 2017 deaths -> population and deaths by age bin
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
if "$ROOT" == "" {
    display as error "Run via scripts/00_master.do"
    exit 198
}

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
display as result "01_gbd_clean: " r(r) " PovCalNet countries found in GBD"
