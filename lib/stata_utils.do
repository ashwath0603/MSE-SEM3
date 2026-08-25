* =============================================================================
* Title:    Shared Stata helpers for MSE-SEM3 coursework
* Author:   Ashwath Balasubramanian
* Created:  2026-08-25
* Purpose:  Standard batch-mode setup + export helpers. Include at the top of
*           every unit do-file with:  do "../../lib/stata_utils.do"
* =============================================================================

version 17
clear all
set more off
set varabbrev off        // abbreviations silently pick the wrong variable — never worth it

* ---- programs ---------------------------------------------------------------

* Export the last estimation result to output/ as a readable table.
* Usage:  regress y x
*         exp_est "ols_baseline"
capture program drop exp_est
program define exp_est
    args name
    capture mkdir "output"
    esttab using "output/`name'.csv", replace se r2 label ///
        star(* 0.10 ** 0.05 *** 0.01)
    display as text "wrote output/`name'.csv"
end

* Export the dataset currently in memory to data/clean/.
capture program drop exp_clean
program define exp_clean
    args name
    capture mkdir "data"
    capture mkdir "data/clean"
    save "data/clean/`name'.dta", replace
    export delimited "data/clean/`name'.csv", replace
    display as text "wrote data/clean/`name'.{dta,csv}"
end

* Guard: stop with a clear message if a required raw file is missing, rather
* than failing 40 lines later with an opaque error.
capture program drop need_raw
program define need_raw
    args f
    capture confirm file "data/raw/`f'"
    if _rc {
        display as error "Missing required raw file: data/raw/`f'"
        display as error "Download it from the course portal into data/raw/ and re-run."
        exit 601
    }
end
