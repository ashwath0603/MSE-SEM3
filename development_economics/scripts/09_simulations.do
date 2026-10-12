* =============================================================================
* 09_simulations.do: the paper's analytical examples (no data needed)
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
if "$ROOT" == "" {
    display as error "Run via scripts/00_master.do"
    exit 198
}

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
