* =============================================================================
* constructed.do: the "Too Young to Die" analysis (Baland, Cassan & Decerf
*                 2021) on data we downloaded ourselves from the original
*                 public sources, instead of the authors' extracts
*
* Run:    run ../replication_package/scripts/replication.do FIRST (step 14
*         compares against its tables). Then, from constructed/ (or scripts/):
*             do scripts/constructed.do
*         or in batch mode:  stata -b do scripts/constructed.do
*         Run it as a do-file, not by pasting into the Command window: it uses
*         /// line breaks. Stata 17 or later; no user-written packages; ~1 min.
* Input:  data/gbd2023/              GBD 2023 deaths (and population, as a check)
*         data/wdi_archive_201912/   World Bank WDI archive, Dec 2019: poverty
*                                    headcount, Gini, national accounts
*         data/hmd/                  Human Mortality Database, France (Figure 5)
*         See data/README.md, which also lists every caveat of these data.
*         Borrowed from ../replication_package/data/119941-V1 (no values enter
*         the default run): the PovCalNet country list and names, the World
*         Bank region file, and the authors' GBD 2017 and PovCalNet values for
*         the comparison tables and the switches below.
* Output: output/tables/    as in replication.do, plus compare_*.csv
*         output/figures/   Figures 2-10
*
* SWITCHES. Each input can come from our construction or the authors' package.
* The default uses ours for both. Setting one to "package" isolates the effect
* of the other (e.g. whether a change comes from poverty or from mortality);
* those runs write to output/sensitivity_<name>/ and never overwrite output/.
*   POVERTY   "constructed": our $1.90 line-up from the WDI archive (step 2)
*             "package":     the authors' PovCalNet extract
*   MORTALITY "constructed": GBD 2023 (step 1)
*             "package":     the authors' GBD 2017 extract
* =============================================================================
version 17
clear all
set more off
set varabbrev off

global POVERTY   "constructed"
global MORTALITY "constructed"

* ---- locate this folder ----------------------------------------------------
capture confirm file "scripts/constructed.do"
if _rc cd ..
confirm file "scripts/constructed.do"

assert inlist("$POVERTY", "constructed", "package") & inlist("$MORTALITY", "constructed", "package")
if "$POVERTY" == "package" & "$MORTALITY" == "package" {
    display as error "Both switches on package: that is replication.do"
    exit 198
}
global ROOT     "`c(pwd)'"
global PKG      "$ROOT/../replication_package/data/119941-V1/Data"
global REPL_TAB "$ROOT/../replication_package/output/tables"
global GBD23    "$ROOT/data/gbd2023"
global WDI      "$ROOT/data/wdi_archive_201912"
global HMD      "$ROOT/data/hmd"
global CLEAN    "`c(tmpdir)'/tytd_constructed_work"
global OUTNAME  "constructed"
if "$POVERTY" == "constructed" & "$MORTALITY" == "package" global OUTNAME "sensitivity_poverty_only"
if "$POVERTY" == "package" & "$MORTALITY" == "constructed" global OUTNAME "sensitivity_mortality_only"
global OUT "$ROOT/output"
if "$OUTNAME" != "constructed" global OUT "$ROOT/output/$OUTNAME"
global TAB "$OUT/tables"
global FIG "$OUT/figures"
confirm file "$PKG/PovCalNet/PovCalNet1_9_2019.csv"

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

* SAMPLE: the paper's rule. "paper" also drops the three countries the
*         authors' name join lost (Eswatini, Palestine, Kiribati).
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

foreach d in "$ROOT/output" "$OUT" "$TAB" "$FIG" {
    capture mkdir "`d'"
}
capture rmtree "$CLEAN"
mkdir "$CLEAN"

* =============================================================================
* STEP 1: GBD 2023 deaths -> the 21 age bins of the GBD 2017 file
*
* Always run. Step 3 turns both GBD rounds into country bins; the MORTALITY
* switch then picks which one feeds the analysis.
*
* Input : $GBD23/  six downloads from the GBD 2023 Results tool, 2026-10-15
*         (all-cause deaths, both sexes, every country, 1990-2017, Number and
*         Rate/100k; plus population, used only as a check). See
*         data/README.md for which file holds which ages.
* Output: $CLEAN/gbd2023_bins.dta: location x year x age bin, with deaths and
*         rate_100k, the same bins as step 3 keeps from GBD 2017
*
* Why a separate step: GBD 2023 no longer publishes ages 1-4. It splits them
* into "12-23 months" and "2-4 years". We add the two back:
*     deaths(1-4) = deaths(12-23m) + deaths(2-4y)
*     pop(1-4)    = pop(12-23m) + pop(2-4y),  pop = deaths / (rate / 100,000)
*     rate(1-4)   = deaths(1-4) / pop(1-4) * 100,000
* GBD's "<5 years" is dropped: it is <1 + 1-4, which the checks confirm.
* =============================================================================
local deaths_zip 24182c5b 5c757971 51274382
local pop_zip    b9533d8b ae868de3
local deaths_csv "$GBD23/IHME-GBD_2023_DATA-75c4dc7e-1/IHME-GBD_2023_DATA-75c4dc7e-1.csv"
foreach z of local deaths_zip {
    confirm file "$GBD23/IHME-GBD_2023_DATA-`z'-1.zip"
}
foreach z of local pop_zip {
    confirm file "$GBD23/IHME-GBD_2023_DATA-`z'-1.zip"
}
confirm file "`deaths_csv'"

* ---- unzip into a scratch folder (raw zips stay untouched) -----------------
local tmp "$CLEAN/_gbd2023_unzipped"
capture mkdir "`tmp'"
local here "`c(pwd)'"
cd "`tmp'"
foreach z in `deaths_zip' `pop_zip' {
    unzipfile "$GBD23/IHME-GBD_2023_DATA-`z'-1.zip", replace
}
cd "`here'"
foreach z of local deaths_zip {
    local deaths_csv `"`deaths_csv' "`tmp'/IHME-GBD_2023_DATA-`z'-1.csv""'
}

* ---- 1. deaths, every age group --------------------------------------------
local first 1
foreach f of local deaths_csv {
    import delimited using "`f'", varnames(1) encoding("utf-8") asdouble clear
    keep measure_name sex_name cause_name location_id location_name age_name metric_name year val
    if !`first' append using `deaths'
    tempfile deaths
    save `deaths'
    local first 0
}
assert measure_name == "Deaths" & sex_name == "Both" & cause_name == "All causes"
assert inrange(year, 1990, 2017)
drop measure_name sex_name cause_name
replace metric_name = lower(metric_name)
reshape wide val, i(location_id location_name year age_name) j(metric_name) string
rename (valnumber valrate) (deaths rate_100k)
assert deaths > 0 & rate_100k > 0 & !missing(deaths, rate_100k)
gen double pop = deaths / (rate_100k / 100000)
save `deaths', replace

* ---- 2. check: <1 + 12-23 months + 2-4 years = <5 --------------------------
gen byte part = inlist(age_name, "<1 year", "12-23 months", "2-4 years")
keep if part | age_name == "<5 years"
collapse (sum) deaths pop, by(location_id year part)
reshape wide deaths pop, i(location_id year) j(part)
assert reldif(deaths1, deaths0) < 1e-9 & reldif(pop1, pop0) < 1e-9

* ---- 3. check: population implied by deaths/rate = GBD population ----------
local first 1
foreach z of local pop_zip {
    import delimited using "`tmp'/IHME-GBD_2023_DATA-`z'-1.csv", varnames(1) encoding("utf-8") asdouble clear
    assert measure_name == "Population" & sex_name == "Both"
    keep location_id year age_name val
    keep if inrange(year, 1990, 2017)
    if !`first' append using `popfile'
    tempfile popfile
    save `popfile'
    local first 0
}
* the two population files overlap at ages 40-69: they must agree
duplicates tag location_id year age_name, gen(dup)
bysort location_id year age_name (val): assert reldif(val[1], val[_N]) < 1e-9
duplicates drop location_id year age_name, force
drop dup
rename val pop_gbd
merge 1:1 location_id year age_name using `deaths', keepusing(pop)
* matched: every age group in both files; deaths-only: <1, 12-23m, 2-4y
assert _merge == 3 | (_merge == 2 & inlist(age_name, "<1 year", "12-23 months", "2-4 years"))
assert reldif(pop, pop_gbd) < 1e-6 if _merge == 3
count if _merge == 3
display as result "step 1: deaths/rate = GBD population in all " r(N) " cells"

* ---- 4. the 21 bins ---------------------------------------------------------
use `deaths', clear
drop if age_name == "<5 years"
gen int age_lo = .
gen int width  = .
replace age_lo = 0  if age_name == "<1 year"
replace width  = 1  if age_name == "<1 year"
replace age_lo = 1  if inlist(age_name, "12-23 months", "2-4 years")
replace width  = 4  if inlist(age_name, "12-23 months", "2-4 years")
forvalues a = 5(5)90 {
    replace age_lo = `a' if age_name == "`a'-`=`a'+4' years"
    replace width  = 5   if age_name == "`a'-`=`a'+4' years"
}
replace age_lo = 95 if age_name == "95+ years"
replace width  = 1  if age_name == "95+ years"
assert !missing(age_lo, width)
collapse (sum) deaths pop, by(location_id location_name year age_lo width)
gen double rate_100k = deaths / pop * 100000
drop pop

* ---- checks ----------------------------------------------------------------
bysort location_id year: assert _N == 21
isid location_id year age_lo
quietly levelsof location_id
display as result "step 1: " r(r) " locations x " 2017 - 1990 + 1 " years x 21 bins"

order location_id location_name year age_lo width deaths rate_100k
sort location_id year age_lo
label var location_id   "GBD location id"
label var location_name "GBD 2023 location name"
label var age_lo        "First age in the GBD age bin"
label var width         "Number of single years in the bin"
label var deaths        "Deaths during the year (GBD 2023 point estimate)"
label var rate_100k     "Death rate per 100,000 (GBD 2023; 1-4 built from 12-23m and 2-4y)"
compress
save "$CLEAN/gbd2023_bins.dta", replace

* ---- remove the scratch folder ---------------------------------------------
local files : dir "`tmp'" files "*"
foreach f of local files {
    erase "`tmp'/`f'"
}
rmdir "`tmp'"

* =============================================================================
* STEP 2: rebuild the PovCalNet $1.90 line-up from public data
*
* Input : $WDI/wdi_201912_long.csv  WDI Database Archives, release 2019 Dec:
*                                   headcount and Gini (survey years only),
*                                   GDP and household consumption per capita
*         $WDI/countries.csv        to drop aggregates and flag Sub-Saharan Africa
*         $PKG/PovCalNet/PovCalNet1_9_2019.csv  country LIST only (not values),
*                                   so the constructed series covers the same countries
* Output: $CLEAN/povcal_lineup.dta: iso3 x request year, hc_1_9 (0-1),
*         plus how each value was obtained (method)
*
* PovCalNet published poverty for fixed "request years". For a year without a
* survey it moved the nearest survey's distribution with national-accounts
* growth, keeping inequality fixed. We do the same, with two simplifications:
*   1. Each survey's distribution is log-normal with the survey's Gini
*      (PovCalNet used the full survey distribution, which is not public for
*      the 2011-PPP vintage any more).
*   2. The survey mean is the one the log-normal implies at the published
*      headcount (the archive has no survey means).
* Growth: household consumption per capita, except Sub-Saharan Africa, which
* uses GDP per capita (PovCalNet's rule); GDP fills years without consumption.
* Between two surveys: if survey means and national accounts move the same way
* and the reference year's national accounts lie between the two surveys', the
* mean is interpolated on national accounts; otherwise each survey is moved
* separately. Either way the two headcounts are weighted by distance in time.
* =============================================================================
local z = 1.9
local reqyears 1981 1984 1987 1990 1993 1996 1999 2002 2005 2008 2010 2011 2012 2013 2015

* ---- 1. countries: drop aggregates, flag Sub-Saharan Africa -----------------
import delimited using "$WDI/countries.csv", varnames(1) stringcols(_all) clear
replace region = strtrim(region)
drop if region == "Aggregates"
gen byte ssa = region_id == "SSF"
keep iso3 ssa
tempfile ctry
save `ctry'

* same country universe as the authors' file (national coverage only)
import delimited using "$PKG/PovCalNet/PovCalNet1_9_2019.csv", ///
    varnames(1) encoding("utf-8") clear
keep if inlist(coveragetype, "N", "A")
keep countrycode
duplicates drop
rename countrycode iso3
tempfile pcn_list
save `pcn_list'

* ---- 2. archive values, one row per country x year -------------------------
import delimited using "$WDI/wdi_201912_long.csv", varnames(1) asdouble clear
replace series = subinstr(series, ".", "_", .)
reshape wide value, i(iso3 year) j(series) string
rename (valueSI_POV_DDAY valueSI_POV_GINI valueNY_GDP_PCAP_KD valueNE_CON_PRVT_PC_KD) ///
       (hc gini gdp hfce)
merge m:1 iso3 using `ctry', keep(match) nogen
merge m:1 iso3 using `pcn_list', keep(match) nogen
fillin iso3 year
drop _fillin
bysort iso3 (ssa): replace ssa = ssa[1]

* ---- 3. national-accounts index, chained from yearly growth ----------------
* A year without either series breaks the chain: surveys and reference years
* in different segments are never compared.
sort iso3 year
by iso3: gen double g = hfce / hfce[_n-1] if !ssa & year == year[_n-1] + 1
by iso3: replace g = gdp / gdp[_n-1] if missing(g) & year == year[_n-1] + 1
* each missing growth rate starts a new segment; lna = 0 in its first year
by iso3: gen int seg = sum(missing(g))
bysort iso3 seg (year): gen double lna = sum(ln(g))
replace lna = . if missing(gdp) & missing(hfce)
tempfile na
save `na'

* ---- 4. surveys: implied log-normal and mean -------------------------------
keep if !missing(hc)
* Gini for surveys without one: the nearest survey year with a Gini in the
* same country (earlier year on ties); none at all: the median survey Gini
preserve
    keep if !missing(gini)
    keep iso3 year gini
    rename (year gini) (gyear gini_near)
    tempfile ginis
    save `ginis'
    summarize gini_near, detail
    local gini_median = r(p50)
restore
gen byte gini_fill = missing(gini)
joinby iso3 using `ginis', unmatched(master)
gen gap = abs(gyear - year)
bysort iso3 year (gap gyear): keep if _n == 1
replace gini = gini_near if missing(gini)
replace gini = `gini_median' if missing(gini)
replace gini_fill = 2 if gini_fill & missing(gini_near)
drop gyear gini_near gap _merge

gen double H     = hc / 100
gen double Hc    = min(max(H, 0.0005), 0.9995)   // 0 and 100 are rounded (0.1 pp)
gen double sigma = sqrt(2) * invnormal((gini / 100 + 1) / 2)
gen double lnmu  = ln(`z') - sigma * invnormal(Hc) + sigma^2 / 2
keep iso3 year H sigma lnmu lna seg gini_fill
rename year sy
tempfile surveys
save `surveys'

* ---- 5. reference years x surveys ------------------------------------------
use `na', clear
gen byte req = 0
foreach t of local reqyears {
    replace req = 1 if year == `t'
}
keep if req
keep iso3 year lna seg
rename (lna seg) (lna_t seg_t)
joinby iso3 using `surveys'
* keep the survey just below and just above each reference year
bysort iso3 year: egen lo = max(cond(sy <= year, sy, .))
bysort iso3 year: egen hi = min(cond(sy >= year, sy, .))
keep if sy == lo | sy == hi
* a survey is usable for year t only if no break in national accounts between
gen byte ok = seg == seg_t & !missing(lna, lna_t)
replace ok = 1 if sy == year
gen side = cond(sy == lo, "lo", "hi")
replace side = "lo" if lo == hi
drop lo hi
keep iso3 year side sy H sigma lnmu lna ok gini_fill lna_t
reshape wide sy H sigma lnmu lna ok gini_fill, i(iso3 year) j(side) string

* ---- 6. the line-up ---------------------------------------------------------
* A log-normal with dispersion s and log mean m has headcount
* normal((ln z - m) / s + s / 2) below the line z.
gen double hc_1_9 = .
gen str14 method = ""
* (a) a survey in the reference year itself
replace hc_1_9 = Hlo if sylo == year
replace method = "survey" if sylo == year
* (b) only one usable side: move that survey with national accounts
gen byte only_lo = missing(hc_1_9) & oklo == 1 & okhi != 1
gen byte only_hi = missing(hc_1_9) & okhi == 1 & oklo != 1
foreach s in lo hi {
    replace hc_1_9 = normal((ln(`z') - (lnmu`s' + lna_t - lna`s')) / sigma`s' ///
        + sigma`s' / 2) if only_`s'
    replace method = "extrap_`s'" if only_`s'
}
* (c) bracketed by two usable surveys
gen byte both = missing(hc_1_9) & oklo == 1 & okhi == 1
gen double w  = (syhi - year) / (syhi - sylo) if both
gen double dmu = exp(lnmuhi) - exp(lnmulo)
gen double dna = exp(lnahi) - exp(lnalo)
* monotonic: survey means and national accounts move the same way, and the
* reference year's national accounts lie between the two surveys'
gen byte mono = both & dna != 0 & sign(dmu) == sign(dna) ///
    & inrange(lna_t, min(lnalo, lnahi), max(lnalo, lnahi))
* monotonic: one mean, interpolated on national accounts
gen double mu_t = exp(lnmulo) + dmu * (exp(lna_t) - exp(lnalo)) / dna if mono
gen double m_lo = cond(mono, ln(mu_t), lnmulo + (lna_t - lnalo)) if both
gen double m_hi = cond(mono, ln(mu_t), lnmuhi + (lna_t - lnahi)) if both
replace hc_1_9 = w * normal((ln(`z') - m_lo) / sigmalo + sigmalo / 2) ///
         + (1 - w) * normal((ln(`z') - m_hi) / sigmahi + sigmahi / 2) if both
replace method = cond(mono, "interp_mono", "interp_nonmono") if both
* Gini borrowed from another survey or the median, for the surveys used
gen byte gini_filled = 0 if !missing(hc_1_9)
replace gini_filled = gini_filllo > 0 if method == "extrap_lo"
replace gini_filled = gini_fillhi > 0 if method == "extrap_hi"
replace gini_filled = gini_filllo > 0 | gini_fillhi > 0 if both

* ---- 7. checks and save ----------------------------------------------------
keep iso3 year hc_1_9 method gini_filled
assert inrange(hc_1_9, 0, 1) if !missing(hc_1_9)
isid iso3 year
tab method, missing
label var hc_1_9 "Headcount ratio at 1.90 USD/day (share), constructed line-up"
label var method "How the value was obtained"
label var gini_filled "Gini borrowed from another survey year or the median"
compress
save "$CLEAN/povcal_lineup.dta", replace

* =============================================================================
* STEP 3: GBD deaths -> population and deaths by age bin
*
* Input : $CLEAN/gbd2023_bins.dta from step 1 (GBD 2023)
*         $PKG/GBD/IHME-GBD_2017_DATA-f89cefb0-1.csv (GBD 2017, the authors')
*         $PKG/PovCalNet/PovCalNet1_9_2019.csv (only for its ISO3 codes)
* Output: $CLEAN/gbd_bins_2023.dta and gbd_bins_2017.dta: iso3 x year x age bin
*         $CLEAN/gbd_bins.dta: the one the MORTALITY switch picks
*         Both rounds are always built: step 14 compares them.
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
import delimited using "$PKG/PovCalNet/PovCalNet1_9_2019.csv", ///
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
"BOL" "Bolivia (Plurinational State of)"
"CIV" "Côte d'Ivoire"
"CZE" "Czechia"
"FSM" "Micronesia (Federated States of)"
"GMB" "Gambia"
"IRN" "Iran (Islamic Republic of)"
"KOR" "Republic of Korea"
"MDA" "Republic of Moldova"
"TUR" "Türkiye"
"TZA" "United Republic of Tanzania"
"USA" "United States of America"
"VEN" "Venezuela (Bolivarian Republic of)"
"VNM" "Viet Nam"
end
* The last 13 rows are GBD 2023 names (mostly UN names; step 1).
* They match nothing in GBD 2017.
* Not in GBD 2017 at all: Tuvalu (TUV), Kosovo (XKX). They cannot enter.
* GBD 2023 has Tuvalu, so here it can enter.
append using `pcn_names'
duplicates drop gbd_name, force       // a hand entry and an exact match never collide
tempfile xwalk
save `xwalk'

foreach src in 2017 2023 {
    * ---- 2. read GBD, keep the 21 mutually exclusive age bins ------------------
    if "`src'" == "2023" {
        use location_name year age_lo width deaths rate_100k using "$CLEAN/gbd2023_bins.dta", clear
    }
    else {
        import delimited using "$PKG/GBD/IHME-GBD_2017_DATA-f89cefb0-1.csv", ///
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
    }

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
    save "$CLEAN/gbd_bins_`src'.dta", replace

    quietly levelsof iso3
    display as result "step 3: GBD `src': " r(r) " PovCalNet countries found"
}
local src = cond("$MORTALITY" == "constructed", "2023", "2017")
copy "$CLEAN/gbd_bins_`src'.dta" "$CLEAN/gbd_bins.dta", replace
display as result "step 3: analysis uses GBD `src'"

* =============================================================================
* STEP 4: PovCalNet headcount ratio -> annual country series
*
* Input : $PKG/PovCalNet/PovCalNet<line>_2019.csv for each line in $PLINE
*         ("economies table", downloaded by the authors on 11 Dec 2019)
* Output: $CLEAN/povcal_hc.dta: one row per iso3 x year (1981-2015),
*         hc_<line> = share of population below the line (0-1)
*
* PovCalNet reports estimates only for "request years" (1981, 1984, ..., 2008,
* then 2010-2013 and 2015). Years in between are filled by linear interpolation
* within each country, never extrapolated beyond the first or last request year.
* =============================================================================
* POVERTY = "constructed": request-year values from step 2 instead
* of the authors' file. Everything below (interpolation, high-income flag) is
* the same for both.
if "$POVERTY" == "constructed" {
    use iso3 year hc_1_9 if !missing(hc_1_9) using "$CLEAN/povcal_lineup.dta", clear
}
else {
    local first 1
    foreach line of global PLINE {
        import delimited using "$PKG/PovCalNet/PovCalNet`line'_2019.csv", ///
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
* STEP 5: merge mortality and poverty, fix the sample, build aggregates
*
* Input : $CLEAN/gbd_bins.dta, $CLEAN/povcal_hc.dta, $PKG/region/WB_class.xls
* Output: $CLEAN/panel_bins.dta: one row per unit x year x age bin, where a
*         unit is a country (ISO3), a World Bank region, or the World
*
* Sample rule (paper p.250): low- and middle-income countries with a headcount
* in every year 1990-2015, observed in both GBD and PovCalNet.
* =============================================================================
* ---- 1. World Bank regions (by ISO3) ---------------------------------------
import excel using "$PKG/region/WB_class.xls", sheet("List of economies") ///
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
display as result "step 5: sample = " `n_countries' " countries (SAMPLE = $SAMPLE)"
* No fixed count here: constructed poverty loses countries whose line-up has
* gaps, and GBD 2023 adds Tuvalu. The paper's 113 is checked in replication.do.

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
* STEP 6: split GBD age bins into single years of age 0..95
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
* empty bin: under one person, floored to 0 (only Tuvalu 95+, GBD 2023)
replace m = 0 if pop_start == 0 & deaths == 0
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
* STEP 7: Generated Deprivation index, GD (paper eqs. 2-3, Section IV)
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
* STEP 8: Inherited Deprivation, ID (paper eq. 1), from GBD deaths
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
* STEP 9: Figure 7, what drove the fall in life-span deprivation?
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
* the "actual" scenario must reproduce step 7's World life-span component
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
* STEP 10: Figure 5, France 1816-today, life-span components of ID
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
* With deaths dated at the start of the year (as in step 7):
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
* STEP 11: the paper's analytical examples (no data needed)
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
* STEP 12: Tables 3 and 4 and every number quoted in Section IV
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
display as result "step 12: " _N - r(N) " of " _N " published numbers reproduced; " r(N) " differ (see note column)"
export delimited using "$TAB/targets.csv", replace
erase "$TAB/targets.dta"

* ---- country GD by year: a table of its own, and the input that
* constructed.do compares against --------------------------------------------
use level iso3 gbd_name region year pop_living hc_pct_1_9 gd_50_1_9 if level == "country" using "$CLEAN/gd.dta", clear
drop level
sort iso3 year
export delimited using "$TAB/gd_countries.csv", replace

* =============================================================================
* STEP 13: Figures 2-10 of the paper (Figure 1 is a schematic)
*
* Input : $CLEAN/{gd,id,counterfactuals,reversals,sim_fig2,sim_fig4}.dta
*         $CLEAN/hmd_france.dta (Figure 5, only if step 10 has run)
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
    display as error "Figure 5 skipped: run step 10 once data/hmd/ is filled"
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
* STEP 14: constructed data vs the authors' data
*
* Input : $CLEAN/povcal_lineup.dta, $CLEAN/gbd_bins_2017.dta,
*         $CLEAN/gbd_bins_2023.dta, $CLEAN/gd.dta, $TAB/targets.csv
*         $PKG/PovCalNet/PovCalNet1_9_2019.csv      the authors' line-up
*         $REPL_TAB/targets.csv, gd_countries.csv  replication.do's output
* Output: $TAB/compare_lineup.csv   constructed - authors' headcount at the
*                                   request years 1990-2015, by how the value
*                                   was built (poverty constructed only)
*         $TAB/compare_gbd.csv      GBD 2023 / GBD 2017 deaths by age bin,
*                                   common countries 1990-2017 (mortality
*                                   constructed only)
*         $TAB/compare_sample.csv   countries in one sample but not the other
*         $TAB/compare_targets.csv  every published number: paper,
*                                   replication, constructed
*         $TAB/compare_ranks.csv    rank correlation, replication vs
*                                   constructed, by year
* The last three need replication.do to have been run first.
* =============================================================================
local have_repl = 1
foreach f in targets.csv gd_countries.csv {
    capture confirm file "$REPL_TAB/`f'"
    if _rc local have_repl = 0
}
if !`have_repl' display as text "compare_sample/targets/ranks skipped: run replication.do first"

* ---- 1. the line-up itself -------------------------------------------------
if "$POVERTY" == "constructed" {
    import delimited using "$PKG/PovCalNet/PovCalNet1_9_2019.csv", ///
        varnames(1) encoding("utf-8") asdouble clear
    keep if inlist(coveragetype, "N", "A")
    keep countrycode requestyear headcount
    rename (countrycode requestyear headcount) (iso3 year hc_pkg)
    merge 1:1 iso3 year using "$CLEAN/povcal_lineup.dta", keep(match) nogen
    keep if inrange(year, 1990, 2015) & !missing(hc_pkg, hc_1_9)
    gen double abs_gap_pp = 100 * abs(hc_1_9 - hc_pkg)
    gen byte within1 = abs_gap_pp <= 1
    gen byte within5 = abs_gap_pp <= 5
    quietly corr hc_1_9 hc_pkg
    local rho = r(rho)
    tempfile cells
    save `cells'
    collapse (count) n = abs_gap_pp (mean) mean_abs = abs_gap_pp ///
        (p50) p50_abs = abs_gap_pp (p90) p90_abs = abs_gap_pp (max) max_abs = abs_gap_pp ///
        (mean) within1 within5, by(method)
    tempfile bymethod
    save `bymethod'
    use `cells', clear
    collapse (count) n = abs_gap_pp (mean) mean_abs = abs_gap_pp ///
        (p50) p50_abs = abs_gap_pp (p90) p90_abs = abs_gap_pp (max) max_abs = abs_gap_pp ///
        (mean) within1 within5
    gen method = "all"
    gen double corr = `rho'
    append using `bymethod'
    order method n corr
    export delimited using "$TAB/compare_lineup.csv", replace
    display as result "step 14: line-up corr = " %5.3f `rho'
}

* ---- 1b. mortality: GBD 2023 vs GBD 2017, by age bin -----------------------
* Ratio of total deaths, and how often a country-year cell is within 10% / 25%
* of the package value, or off by more than 50%.
if "$MORTALITY" == "constructed" {
    use iso3 year age_lo deaths rate_100k using "$CLEAN/gbd_bins_2017.dta", clear
    rename (deaths rate_100k) (deaths_pkg rate_pkg)
    merge 1:1 iso3 year age_lo using "$CLEAN/gbd_bins_2023.dta", keepusing(deaths rate_100k) keep(match) nogen
    gen double ratio = deaths / deaths_pkg
    gen byte within10 = abs(ln(ratio)) <= ln(1.10)
    gen byte within25 = abs(ln(ratio)) <= ln(1.25)
    gen byte off50    = abs(ln(ratio)) >  ln(1.50)
    tempfile bins
    save `bins'
    collapse (count) n = ratio (sum) deaths_pkg deaths (p50) median_ratio = ratio (mean) within10 within25 off50, by(age_lo)
    tostring age_lo, gen(bin)
    tempfile byage
    save `byage'
    use `bins', clear
    collapse (count) n = ratio (sum) deaths_pkg deaths (p50) median_ratio = ratio (mean) within10 within25 off50
    gen bin = "all"
    append using `byage'
    gen double total_ratio = deaths / deaths_pkg
    order bin n deaths_pkg deaths total_ratio median_ratio within10 within25 off50
    drop age_lo
    list, clean noobs
    export delimited using "$TAB/compare_gbd.csv", replace
}

if `have_repl' {
    * ---- 2. sample -------------------------------------------------------------
    import delimited using "$REPL_TAB/gd_countries.csv", varnames(1) clear
    keep iso3
    duplicates drop
    rename iso3 unit
    gen byte in_replication = 1
    tempfile pkg_units
    save `pkg_units'
    use unit level if level == "country" using "$CLEAN/gd.dta", clear
    drop level
    duplicates drop
    gen byte in_constructed = 1
    merge 1:1 unit using `pkg_units', nogen
    replace in_replication = 0 if missing(in_replication)
    replace in_constructed = 0 if missing(in_constructed)
    keep if in_replication != in_constructed
    rename unit iso3
    * why: request years 1990-2015 with no constructed value
    if "$POVERTY" == "constructed" {
        preserve
            use "$CLEAN/povcal_lineup.dta", clear
            keep if inrange(year, 1990, 2015)
            gen byte miss = missing(hc_1_9)
            collapse (sum) n_missing_req_years = miss, by(iso3)
            tempfile miss
            save `miss'
        restore
        merge 1:1 iso3 using `miss', keep(master match) nogen
    }
    list, clean noobs
    export delimited using "$TAB/compare_sample.csv", replace

    * ---- 3. published numbers --------------------------------------------------
    import delimited using "$REPL_TAB/targets.csv", varnames(1) bindquote(strict) clear
    keep id target paper ours status
    rename (ours status) (replication replication_status)
    tempfile t_pkg
    save `t_pkg'
    import delimited using "$TAB/targets.csv", varnames(1) bindquote(strict) clear
    keep id ours status
    rename (ours status) (constructed constructed_status)
    merge 1:1 id using `t_pkg', assert(match) nogen
    gen double constructed_minus_replication = constructed - replication
    order id target paper replication constructed constructed_minus_replication replication_status constructed_status
    sort id
    export delimited using "$TAB/compare_targets.csv", replace

    * ---- 4. country rankings, common countries ---------------------------------
    import delimited using "$REPL_TAB/gd_countries.csv", varnames(1) clear
    keep iso3 year hc_pct_1_9 gd_50_1_9
    rename (iso3 hc_pct_1_9 gd_50_1_9) (unit hc_pkg gd_pkg)
    merge 1:1 unit year using "$CLEAN/gd.dta", keepusing(hc_pct_1_9 gd_50_1_9) keep(match) nogen
    tempname R
    postfile `R' int year int n double(spearman_hc spearman_gd) using "$TAB/compare_ranks.dta", replace
    forvalues y = 1990/2015 {
        quietly spearman hc_pkg hc_pct_1_9 if year == `y'
        local s_hc = r(rho)
        quietly spearman gd_pkg gd_50_1_9 if year == `y'
        post `R' (`y') (r(N)) (`s_hc') (r(rho))
    }
    postclose `R'
    use "$TAB/compare_ranks.dta", clear
    export delimited using "$TAB/compare_ranks.csv", replace
    erase "$TAB/compare_ranks.dta"
}

display as result "step 14: done ($OUTNAME)"

* ---- remove the scratch folder ---------------------------------------------
rmtree "$CLEAN"
display as result "constructed.do finished ($OUTNAME): " c(current_date) " " c(current_time)
