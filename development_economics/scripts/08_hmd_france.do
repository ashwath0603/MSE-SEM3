* =============================================================================
* 08_hmd_france.do: Figure 5, France 1816-today, life-span components of ID
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
* With deaths dated at the start of the year (as in 05_gd.do):
*   D(y,a)  = N(y,a) * q(y,a)                deaths at age a in year y
*   GD_ls   = sum_a D(y,a)(ahat - a) / (N_y + that sum)
*   ID_ls   = d_y / (N_y + d_y), where d_y = deaths in years t <= y among
*             cohorts born after y - ahat (each death is "inherited" by the
*             ahat - a years in which the person would still be under ahat)
* N_y is the total population on 1 January. ID needs ahat years of history,
* so it starts in 1816 + ahat.
* =============================================================================
if "$ROOT" == "" {
    display as error "Run via scripts/00_master.do"
    exit 198
}

local ahat 40
local pop  FRATNP

foreach z in lt_both population {
    capture confirm file "$HMD/`z'.zip"
    if _rc {
        display as error "Missing $HMD/`z'.zip: see data/raw/README.md"
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
