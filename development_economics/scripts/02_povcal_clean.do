* =============================================================================
* 02_povcal_clean.do: PovCalNet headcount ratio -> annual country series
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
if "$ROOT" == "" {
    display as error "Run via scripts/00_master.do"
    exit 198
}

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
