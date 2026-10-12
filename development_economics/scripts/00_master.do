* =============================================================================
* Title:    00_master.do: run the whole replication from raw data
* Project:  Replication of Baland, Cassan & Decerf (2021), "Too Young to Die",
*           AEJ: Applied Economics 13(4): 226-257
* Purpose:  Sets paths and the normative parameters once, then runs every
*           step in order. Each step reads only from data/raw or from the
*           output of an earlier step, so the chain is reproducible.
* Run:      cd development_economics && stata -b do scripts/00_master.do
* =============================================================================

* ---- locate the unit root (works from the unit root or from scripts/) ------
capture confirm file "scripts/00_master.do"
if _rc cd ..
do "../lib/stata_utils.do"            // version 17, clear all, varabbrev off, need_raw, exp_clean

global ROOT  "`c(pwd)'"
global RAW   "$ROOT/data/raw/119941-V1/Data"
global HMD   "$ROOT/data/raw/hmd"
global CLEAN "$ROOT/data/clean"
global TAB   "$ROOT/output/replication/tables"
global FIG   "$ROOT/output/replication/figures"

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

* SAMPLE: "iso" joins GBD and PovCalNet on ISO3 codes, so every eligible
*         country enters. "paper" also drops the countries the authors' name
*         join lost (see 03_panel.do), so the sample is the paper's 113.
*         Use "paper" to replicate; "iso" is reported as a robustness check.
global SAMPLE "paper"

* ---- pipeline --------------------------------------------------------------
do scripts/01_gbd_clean.do            // GBD deaths and rates -> population by age bin
do scripts/02_povcal_clean.do         // PovCalNet headcount -> annual, interpolated
do scripts/03_panel.do                // merge, sample, regional and World aggregates
do scripts/04_single_ages.do          // age bins -> single years 0..95
do scripts/05_gd.do                   // Generated Deprivation (and its pieces)
do scripts/06_id_gbd.do               // Inherited Deprivation from GBD (Haiti, ahat = 5)
do scripts/07_counterfactuals.do      // Figure 7: 1990 births / mortality held fixed
do scripts/08_hmd_france.do           // Figure 5: France, HMD period life tables
do scripts/09_simulations.do          // Tables 1-2, Figures 2 and 4 (no data)
do scripts/10_tables.do               // Tables 3-4 and every number quoted in Section IV
do scripts/11_figures.do              // Figures 2-10
do scripts/20_compare.do              // checks against the authors' own code and Excel

display as result "00_master.do finished: " c(current_date) " " c(current_time)
