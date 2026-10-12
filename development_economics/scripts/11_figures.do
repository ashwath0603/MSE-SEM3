* =============================================================================
* 11_figures.do: Figures 2-10 of the paper (Figure 1 is a schematic)
*
* Input : $CLEAN/{gd,id,counterfactuals,reversals,sim_fig2,sim_fig4}.dta
*         $CLEAN/hmd_france.dta (Figure 5, only if 08_hmd_france.do has run)
* Output: $FIG/figNN_*.pdf and .png
* =============================================================================
if "$ROOT" == "" {
    display as error "Run via scripts/00_master.do"
    exit 198
}

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
    display as error "Figure 5 skipped: run 08_hmd_france.do once data/raw/hmd/ is filled"
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
