* =============================================================================
* 10_tables.do: Tables 3 and 4 and every number quoted in Section IV
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
if "$ROOT" == "" {
    display as error "Run via scripts/00_master.do"
    exit 198
}

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
display as result "10_tables: " _N - r(N) " of " _N " published numbers reproduced; " r(N) " differ (see note column)"
export delimited using "$TAB/targets.csv", replace
erase "$TAB/targets.dta"
