* =============================================================================
* 20_compare.do: verify our replication against the authors' own output
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
if "$ROOT" == "" {
    display as error "Run via scripts/00_master.do"
    exit 198
}

local BENCH "$ROOT/benchmark/Data/CleanedData/PovertyMortalityWorld.dta"
capture confirm file "`BENCH'"
if _rc {
    display as error "Benchmark not built. Run: zsh benchmark/apply_patches.sh, then"
    display as error "cd benchmark && stata -b do Code/Master.do"
    exit 601
}

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
local XL "$ROOT/data/raw/119941-V1/Figure 4/Figure_4_MortalityShocks.xlsx"
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
local BHMD "$ROOT/benchmark/Data/CleanedData/HMD_mortality.dta"
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
