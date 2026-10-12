# Paper notes: Baland, Cassan & Decerf (2021), "Too Young to Die"

> Baland, J.-M., Cassan, G., & Decerf, B. (2021). "Too Young to Die": Deprivation measures
> combining poverty and premature mortality. *American Economic Journal: Applied Economics,
> 13*(4), 226–257. <https://doi.org/10.1257/app.20200122>
>
> PDF: [`../assignment/baland_cassan_decerf_2021.pdf`](../assignment/baland_cassan_decerf_2021.pdf).
> **Page numbers below are journal pages (226–257).** PDF page = journal page − 224
> (the JSTOR cover is PDF page 1).
>
> Replication package: openICPSR **E119941V1**, <https://doi.org/10.3886/E119941V1>. Per fn 27,
> its code lets you vary â, γ and the poverty line.

These are working notes for retrieval: **no prose here should go into the submission.** The
course plagiarism and AI policy applies (see the unit README).

---

## 0. Quick lookup

### The paper in one paragraph

Standard poverty measures count only the living, so a person who dies young simply leaves
the denominator. That ignores premature death, and it can even make poverty look *lower*
when poor people die (the "mortality paradox"). The paper treats dying before an age
threshold **â** as a deprivation in its own right (**life-span deprivation**). It adds
person-years lost to premature death (**PYPLs**) to person-years spent alive and poor
(**PYADs**), with weight **γ**, *before* dividing by one common reference population.
There are two indexes: **ID** (Inherited Deprivation, based on past deaths) and **GD**
(Generated Deprivation, based on current-year deaths). Both are axiomatically
characterised. They coincide in stationary populations. Empirically (GD, â = 50, γ = 1,
113 LMICs, 1990–2015), ignoring mortality understates total deprivation by **27% (1990)
to 36% (2015)**. In about **8.4%** of 5-year country comparisons, the trend in GD has the
opposite sign to the trend in the head-count ratio.

### Key numbers → where they appear

| Number | Meaning | Location |
|---|---|---|
| 63.6 → 45.6 yrs | Botswana life expectancy, 1990 → 2000 | p.226 intro |
| 33.6% → 29.5% | Botswana extreme poverty, 1990 → 2000 | p.226 intro |
| 36% | Minimum underestimate of world deprivation in 2015 | Abstract |
| 27–36% | Underestimate over the whole period | p.229 |
| **705 m** | Income poor in 2015 (intro). **Table 3 says 703 m** | p.229 vs p.251 |
| 402 m | PYPLs in 2015 | p.229, Table 3 |
| 8% / 8.4% | Country-periods where GD and HC move in opposite directions | p.229 / p.255 |
| 26.9% | Same share as γ → ∞ | p.255 |
| 315,000 | Haiti 2010 earthquake deaths (GBD) | fn 13, p.237 |
| 2% → 1% | Mortality shocks in the Figure 4 simulations | p.238 |
| â = 50, γ = 1 | Baseline normative parameters for the empirical work | p.249 |
| 64 yrs | Median age at death in their data | p.249 |
| 850 / 127 / 113 | PovCalNet surveys / countries in PovCalNet / countries in sample | p.250 |
| $1.90/day | Extreme poverty line used | p.250 |
| 52.8% → 17.2% | World GD₁, 1990 → 2015 | Table 3, p.251 |
| 44.9% → 11.7% | World HC, 1990 → 2015 | Table 3 |
| 27% → >36% | Life-span share of total deprivation | p.251, Figure 6 |
| >60% | Underestimate in 2015 if â = 80 | p.251 |
| ~80% → ~70% | Share of GD life-span component from deaths at age ≤5, 1990 → 2015 | p.251 |
| 6.6% → 3.4% | Newborn mortality rate, 1990 → 2015 | p.252 |
| +2.8% | Change in natality, 1990–2015 (described as stable) | p.252 |
| 19th → 38th | Gabon rank, HC → GD, 1993 | p.253 |
| 21st → 32nd | Morocco rank, HC → GD, 1993 | p.253 |
| 67 vs 59 yrs | Life expectancy, Morocco vs Gabon, 1993 | p.253 |
| 4.1 | Average rank change from HC to GD, whole period | p.253 |
| 4.4 → 4.9 | Average rank change, 1990 → 2015 | p.253 |
| 26 ranks | Azerbaijan's loss in 2010 and 2014 (largest) | p.253 |
| +60% / −23% | Comoros HC / GD, 1990–2015 | p.253 |
| ~+50% | Comoros population growth over the same period | p.254 |
| −12% / +0.7% | Botswana HC / GD, 1990–2001 (HIV) | p.255 |
| ~1/3 | Share of world total deprivation from premature mortality | p.255 |

### Every table and figure

| # | Page | What it shows | Data needed | Reproducible? |
|---|---|---|---|---|
| Table 1 | 228 | Composite index P₀.₅ is inconsistent (societies A, B, C) | none (toy) | Yes, by hand |
| Table 2 | 231 | Distributions x, x′, x″ | none (toy) | Yes, by hand |
| Figure 1 | 235 | ID counts dead "vertically", GD counts "horizontally" | none (schematic) | Redraw only |
| Figure 2 | 236 | ID and GD response to a transitory shock (n* = 1, â = 3) | none (toy) | Yes, by hand or code |
| Figure 3 | 237 | Haiti: life-span components of ID and GD, â = 5, 1995–2015 | GBD 2017 | Needs GBD |
| Figure 4 | 238 | Simulated permanent shocks, â = 50, max age 100 | none | **Yes, verified** (§4) |
| Figure 5 | 239 | France 1856–2010: ID and GD life-span components (â = 40); mortality at ages 0 and 20 | Human Mortality Database | Needs HMD (free sign-up) |
| Table 3 | 251 | World GD decomposition, 1990 and 2015 | GBD + PovCalNet | Core result |
| Figure 6 | 252 | World GD stacked (income + life-span), HC, LDC/GD share, 1990–2015 | GBD + PovCalNet | Core result |
| Figure 7 | 253 | Counterfactual life-span component: 1990 births / 1990 mortality / both | GBD | Core result |
| Figure 8 | 254 | Gabon vs Morocco: HC (left), GD (right) | GBD + PovCalNet | Core result |
| Table 4 | 254 | GD decomposition, Gabon vs Morocco, 1993 | GBD + PovCalNet | Core result |
| Figure 9 | 254 | Comoros and Botswana: stacked GD + HC | GBD + PovCalNet | Core result |
| Figure 10 | 256 | Scatter of GDₜ/GDₜ₋₅ against HCₜ/HCₜ₋₅ (HC ratio < 3 only) | GBD + PovCalNet | Core result |

Not in the paper (they sit in the online appendix): all proofs; the list of 113 countries
(Appendix Table 2); the "equal total PYPLs under transitory shocks" result; a second
illustration of GD non-monotonicity.

---

## 1. Notation glossary

| Symbol | Meaning |
|---|---|
| t | Evaluation period (year) |
| xᵢ = (bᵢ, sᵢ) | Individual i's **bundle**: birth year bᵢ ∈ ℤ (bᵢ ≤ t) and status sᵢ |
| sᵢ ∈ 𝒮 = {NP, AP, D} | Alive non-poor / alive poor / dead |
| aᵢ = t − bᵢ | Age i *would* have in t |
| â ∈ ℕ | Life-span threshold. Dying before â is premature. Absolute, not relative |
| a* | Maximal life-span (μ_{a*} = 1) |
| "young" / "old" | Born fewer than â years before t / at least â years before t |
| x = (x₁,…,x_{n(x)}) | Distribution; 𝒳 = the set of non-trivial distributions |
| f(x), p(x) | Number alive non-poor / alive poor |
| d(x) | Number prematurely dead: sᵢ = D **and** â > t − bᵢ |
| nₐ(x) | Number **alive** aged a |
| dₐ(x) | Number **dead** born a years before t |
| μₐ ∈ [0,1] | Age-specific mortality: the share of alive age-a people dying at the end of t |
| μ = (μ₀,…,μ_{a*}) | Current mortality vector; ℳ = the set of such vectors |
| d^GD(x, μ) | PYPLs generated by deaths in t |
| γ > 0 | Weight on one PYPL relative to one PYAD |
| PYAD | Person-year in alive deprivation |
| PYPL | Person-year prematurely lost |
| HC | Head-count ratio = p / (f + p) |
| LD | (Intro only) share of people born in the last â years who are already dead |
| LDC | (Figure 6 legend) life-span deprivation component of GD. Never defined in the text |
| 𝒪 | Domain of (x, μ) pairs with feasible (rational) μₐ = cₐ / nₐ(x) |
| 𝒪* | Stationary pairs within 𝒪 |
| n^ID, n^GD | Reference populations (Figure 2) |

**Timing convention (theory):** births happen at the **start** of the period and deaths at
the **end** (p.229). So status D in t means the person died *before* t, and a newborn
cannot be D (fn 4).
**Timing convention (empirics):** fn 3 says the empirical section assumes deaths happen at
the **start** of the period. → See discrepancy D3.

---

## 2. Chunks by section

### C1 · Introduction (pp.226–229)

- **Epigraph:** Achilles's ghost in the *Odyssey* would rather be a poor labourer alive
  than rule the dead. In the paper's terms, a year dead is worse than a year poor, so γ is
  large.
- **Motivating puzzle (Botswana, 1990–2000):** extreme poverty fell (33.6 → 29.5%) while
  life expectancy collapsed (63.6 → 45.6). How did *total* deprivation change?
- Deprivation is multidimensional (Alkire & Foster 2011). Premature mortality is a source
  of deprivation (Sen 1998; Deaton 2013). The resource is **life-span**. Dying is not a
  deprivation in itself; dying **too young** is.
- fn 2: this differs from "missing poor" (Lefebvre, Pestieau & Ponthiere 2013) and
  "missing women" (Anderson & Ray 2010), which use **counterfactual excess mortality**.
  This paper's approach is **absolute**.
- **Table 1 example:** two births a year, maximum life of 2 years, â = 2.
  - Society A: newborns NP,NP; 1-year-olds AP,AP → HC .5, LD 0, P₀.₅ .25
  - Society B: one 1-year-old dies instead → HC .33, LD .25, P₀.₅ .29
  - Society C: both die → HC 0, LD .5, P₀.₅ .25
  - Each step swaps one *poor* person for one *dead* person, yet P₀.₅ rises and then falls
    → **inconsistent**. The cause is different reference populations (living for HC, total
    for LD). The Human Poverty Index has the same problem (Watkins 2006).
- **Three lessons (p.228):**
  1. Life-span deprivation is **exclusive**: the dead cannot also be poor, so it is
     **added** to alive deprivation.
  2. Measure it in **time units** (person-years). HC is also implicitly in person-years:
     poor people in a given year = poor person-years that year.
  3. Arbitrary weights are a familiar critique of composites. Here the analysis gives a
     normative **lower bound γ ≥ 1**.
- The indexes measure **incidence, not intensity**.
- **Headline empirics (p.229):** GBD + PovCalNet, 1990–2015. Underestimate is at least
  27–36%. 2015: 705 m poor (PYADs) and 402 m PYPLs. The life-span share is rising. 8% of
  country-periods are reversals.

### C2 · Section I.A: Basic framework (pp.229–231)

- Bundles, statuses, timing and â are defined as in the glossary above.
- A deprivation index is P: 𝒳 → ℝ₊ with â fixed.
- The three-status setup is deliberately restrictive. It extends to multidimensional or
  continuous alive deprivation (fn 6, à la Alkire–Foster scores).
- **Table 2 example:**
  - x = ((young,NP),(young,D),(old,D))
  - x′: person 2 is NP
  - x″: person 2 is AP
  - HC(x) = 0/1 = 0, HC(x′) = 0/2 = 0, HC(x″) = 1/2.
  - HC cannot see that x′ is better than x. Whether x″ is worse than x depends on how you
    weigh poverty against premature death.
  - fn 7: x″ vs x is the **mortality paradox**. HC is higher in x″ only *because* the poor
    person survived.

### C3 · Section I.B: Inherited Deprivation, ID (pp.231–233)

**Equation (1):**

```
ID_γ(x) = p(x) / [f(x)+p(x)+d(x)]   +   γ · d(x) / [f(x)+p(x)+d(x)]
           └─ alive deprivation ─┘        └─ life-span deprivation ─┘
```

- The **reference population** is everyone alive, plus everyone born less than â years ago
  who has died. Old people who died, and young people who died long ago, are excluded.
- **Independence of Dead** (satisfied by classical indexes, including HC): adding any dead
  person leaves the index unchanged, so classical indexes ignore premature death. fn 8: HC
  is affected only *instrumentally*, through selective mortality (Ravallion 2005).
- ID instead satisfies **Weak Independence of Dead**: adding a dead person changes nothing
  only if that person was born at least â years before t.
- On Table 2: ID(x) > ID(x′). ID(x) ≥ ID(x″) when γ ≥ 1, so ID contradicts HC.
- **Two normative choices: â and γ.**
- **Case for γ ≥ 1:** a year not lived while young is at least as bad as a year poor.
  - Revealed-preference argument: suicide is an available outside option.
  - Caveat: Bantjes et al. (2016) link poverty, mental illness and suicide. γ ≥ 1 is fine
    as long as few young people prefer death to poverty.
  - fn 9: with γ < 1, a policy that only delays a poor person's premature death by one
    year would *raise* deprivation.
- **Additive separability** follows from exclusivity, so ID is simple accounting. By
  contrast, income and health deprivation are *not* exclusive and need not be additive.
- **Data constraint (p.233):** a distribution does not record status and survival chances
  jointly per person. Few datasets link lifetime with deprivation status, so the measures
  are **indifferent to the joint distribution** of PYADs and PYPLs across people. This is
  discussed again at the end of Section III.

### C4 · Section I.C: Generated Deprivation, GD (pp.233–235)

- **Problems with ID:**
  - It needs cohort mortality for every one of the â years before t.
  - It has **inertia**: shocks take decades to wash out. Example: Rwanda's ID today still
    counts children killed in the 1994 genocide. That is an accurate picture but useless
    for evaluating current policy.
- GD uses **current** mortality μ.

**Equation (2):**

```
GD_γ(x, μ) = p(x) / [f(x)+p(x)+d^GD(x,μ)]  +  γ · d^GD(x,μ) / [f(x)+p(x)+d^GD(x,μ)]
```

**Equation (3):**

```
d^GD(x, μ) = Σ_{a=0}^{â−1}  nₐ(x) · μₐ · (â − (a+1))
```

- A death at age a < â loses â − (a+1) periods. GD books them all **in the year of death**.
  ID books them across the following years.
- The denominator is the number alive plus the PYPLs.
- **Shared features of ID and GD:**
  - mature deaths are excluded from the reference population
  - all PYPLs carry equal weight
  - γ is constant
  - both are additively decomposable
- **Stationary pair** (p.234): for some n* and all a,
  - nₐ + dₐ = n* (constant natality)
  - nₐ₊₁ = nₐ(1 − μₐ) (identical pyramid next period)

  In a stationary pair μ is redundant given x, so the index should equal ID. This is the
  **ID Equivalence** axiom, and GD satisfies it.
- fn 11: these are the long-run pyramids under constant rates (Preston, Heuveline &
  Guillot 2000).
- **Figure 1 intuition:** d counts dead individuals "vertically" (by cohort), while d^GD
  counts "horizontally" (by age group, years lost by this year's deaths). The two shaded
  areas coincide when the pyramid matches current mortality.

### C5 · Section I.D: Dynamics (pp.235–240)

**Transitory shock (Figure 2):**

- Setup: n* = 1, everyone non-poor (HC = 0), μ* = (0,0,1) so everyone lives exactly 3
  periods. γ = 1, â = 3. The shock at t = 0 is μ⁰ = (1,1,1).
- ID: 0 at t = 0 (deaths happen at the end of the period), **2/3** at t = 1, **1/3** at
  t = 2, then 0. n^ID = 3 throughout.
- GD: at t = 0 the newborn loses 2 PYPLs and the 1-year-old loses 1, giving
  n^GD = 3 alive + 3 = 6 and **GD = 1/2**. Then 0 at t = 1 (n^GD = 1) and 0 at t = 2
  (n^GD = 2).
- **Both books total 3 PYPLs. They differ only in timing.** The general result is in the
  online appendix.
- fn 12: the one-period return to zero is special. With n* = 4, μ⁰ = (1/2,1,1),
  μ* = (0,1/2,1) the return takes longer.

**Haiti 2010 earthquake (Figure 3):**

- â = 5, chosen because the data end in 2015 (fn 14). fn 13: 315,000 deaths per GBD.
- The two components are similar over 1995–2009. GD spikes in 2010 (~1.9%) and is back on
  trend in 2011. ID has a smaller spike (~1.3%) and stays elevated until 2015 (â years
  later).

**Permanent shocks (Figure 4):**

- Simulation: constant natality, no alive deprivation, â = 50, maximum age 100, baseline
  μ = 2% at every age.
- Three shocks, each 2% → 1%: (i) all ages, (ii) age 40 only, (iii) age 10 only.
- ID is unchanged in the shock period, then adjusts smoothly and monotonically.
- GD **jumps immediately**, then adjusts slowly as the pyramid changes.
- The two are equal in the long run. When mortality falls, GD < ID during the transition.
- **GD can be non-monotone** in transition (bottom panel, age-10 shock) because cohort
  sizes in the pyramid shift.

**France (Figure 5):**

- Human Mortality Database; French series from 1816. â = 40 so the pre-1870 period can be
  covered. Plot runs 1856–2010.
- Before 1870 ID ≈ GD, so the population was near-stationary.
- **1870 Franco-Prussian war:** GD spikes, while ID jumps less but for much longer.
  World War I and World War II show the same pattern.
- Without further shocks, ID and GD should reconverge by 1910. They do not, because infant
  mortality falls sharply from the late 19th century. That is a sequence of negative
  permanent shocks: GD reflects each one instantly, ID lags.
- **1919 drop in ID:** Alsace-Lorraine (German 1870–1918) returns to France. Its living
  population is added, but its death history is not.
- fn 15: ID is *over*-estimated during 1870–1910, because pre-1870 deaths in the region
  still count for France after its living population left. The same happens during the
  WWII annexation.
- **Lesson:** ID needs stable borders over â years (think of the USSR in the 1990s).

### C6 · Section II: Axiomatic characterisation (pp.240–245)

Domain 𝒳 excludes trivial distributions (nobody alive and nobody prematurely dead).

**Axioms for ID (Proposition 1):**

| # | Axiom | Content |
|---|---|---|
| 1 | Independence of Dead | Adding *any* dead person leaves P unchanged. Classical indexes satisfy it; ID does **not** |
| 2 | **Weak Independence of Dead** | Adding a dead person born at least â years before t leaves P unchanged |
| 3 | **Least Deprivation** | With one person: P(NP) < P(AP) and P(NP) < P(D) |
| 4 | **Weak Independence of Birth Year** | Within the reference population only status matters (conditional on d unchanged). A newborn dying in t − 1 counts the same as a 48-year-old dying in t − 1 *in period t*, but the newborn's death recurs in more future periods |
| 5 | **Subgroup Consistency** | If deprivation falls in one subgroup and the rest is unchanged (same reference size), total deprivation falls. fn 17: weaker than Foster–Shorrocks (1991) |
| 6 | **Anonymity** | Permutations do not matter |
| 7 | **Replication Invariance** | P(xᵏ) = P(x) |
| 8 | **Young Continuity** | Continuity on a discrete domain (Young 1975) |

> **Proposition 1:** P is *ordinally equivalent* to ID_γ for some γ > 0 **iff** P satisfies
> 2, 3, 4, 5, 6, 7 and 8. Proofs are in the online appendix. The result extends to
> continuous or multidimensional alive deprivation with adapted axioms.

**Axioms for GD (Proposition 2):** the domain is 𝒪, with μ in ℳ and rational feasible rates
(fn 18 handles empty age cells).

| # | Axiom | Content |
|---|---|---|
| 9 | **ID Equivalence** | There is a γ with P(x, μ) = ID_γ(x) on stationary pairs 𝒪* |
| 10 | **Additive Decomposability** | P of a merged population = size-weighted average of the subgroup Ps (eq. 4), with size function η additive. Strengthens Subgroup Consistency. Allows comparisons by sex, race and so on |
| 11 | **Independence of Dead*** | Adding any dead person leaves P unchanged. GD looks only at current mortality |

> **Proposition 2:** P = GD_γ for some γ > 0 **iff** P satisfies 9, 10 and 11.

**Monotonicity (Proposition 3):**

- GD's reference population *grows* with premature mortality, so GD could fall when
  mortality rises.
- **Axiom 12, Monotonicity in Current Mortality:** if μₐ ≥ μ′ₐ for all a ≤ â − 2, then
  P(x, μ) ≥ P(x, μ′).

> **Proposition 3:** GD_γ satisfies Monotonicity in Current Mortality **iff γ ≥ 1**.
> fn 20: for one specific society the condition is **γ ≥ HC** of that society.
> Proposition 3 needs γ ≥ 1 because 𝒪 contains societies with HC = 1. So the constraint
> binds less when poverty is low.

### C7 · Section III: Comparison with alternative approaches (pp.245–249)

**A. Composite indexes** (HDI-style, P_w, HPI):

- They aggregate a weighted sum of components, each normalised by a **different reference
  population**. The implicit trade-off between one PYAD and one PYPL therefore varies with
  the levels of poverty and life expectancy (Ravallion 2012b).
- HPI: HPI_w = w · HC + (1 − w) · HC_â, where HC_â = the probability a newborn dies
  before â.
- fn 22: a stationary-society version of Table 1. Four births a year. A: HC .5, HC_â 0,
  HPI .25 → B: .33, .25, .29 → C: 0, .5, .25.
- fn 21: inconsistency arises for every w ∈ (0,1).
- **This paper's fix:** add PYADs and PYPLs *first*, then divide by one denominator, so γ
  is constant. The indexes also nest HC: with no premature death, GD = ID = HC.

**B. Preference-based indicators** (Becker, Philipson & Soares 2005; Grimm & Harttgen
2008; Jones & Klenow 2016):

- They calibrate one intertemporal utility function. A year of life is implicitly worth
  more in richer countries. The HDI has the same property (Ravallion 2012a, b).
- **This paper instead:**
  - compares deprivation *statuses*, not achievements
  - uses only two transparent parameters (â, γ)
  - under a common utility function a status gives the same utility everywhere (fn 23:
    two people below $1.90 have the same low utility), so a **fixed γ is natural**
- Subgroup Consistency rules out γ varying with the level of deprivation, because a single
  individual can form a subgroup. fn 24: for GD, such a γ would depend on p(x) or d^GD.
- γ is conceptually different from the HDI's income–life-expectancy trade-off, but
  related. Given the nonlinear maps from mean income to poverty and from life expectancy to
  life-span deprivation, γ implies a **money value of an extra life-year**. That value
  → 0 as γ → 0 and → ∞ as γ → ∞.

**C. Mortality-paradox corrections** (Kanbur & Mukherjee 2007; Lefèbvre, Pestieau &
Ponthiere 2013, 2018):

- They impute fictitious incomes to the dead, so mortality matters only
  **instrumentally**. This paper treats premature death as **intrinsic** deprivation.
- **Populations A vs B:** identical, except A's dead would have been poor. This paper says
  equal deprivation; the corrections say A is worse.
- **Men vs women scenario:** all start poor. Surviving women become non-poor; surviving men
  stay poor.
  - Scenario A: women die, men survive.
  - Scenario B: men die, women survive.
  - This paper: A is worse. The corrections: equal.
- **Bees and flowers analogy:** U(b, f) is evaluated without the causal links between b
  and f. Positive (causal) links between poverty and death matter for policy, not for
  normative measurement.
- Lefèbvre et al.'s "missing" = deaths **in excess** of a rich-country reference vector
  (Norway, US). So some premature deaths do not count, while an 80-year-old's excess death
  does.
- Kanbur–Mukherjee give the rich dead incomes above the line. This paper does not
  distinguish the poor dead from the non-poor dead, partly because mortality by income
  group is rarely available.
- **Concentration** (Bourguignon & Chakravarty 2003): it is worse if the same people suffer
  both deprivations. Possible extension: "total poverty" = more than k person-years of
  PYPL + PYAD, in the Alkire–Foster k-cutoff style (fn 25).
  - This needs mortality by income group **and** mobility in and out of poverty, which are
    typically unavailable.
  - fn 26: with low mobility and mortality concentrated among the poor, the indexes
    approximate the person-years the poor lose.

### C8 · Section IV.A: Data and parameters (pp.249–250)

- **Only GD is estimated.** ID needs deaths by age for â past years. HMD countries differ
  from the poverty-relevant ones, and borders change (Section I.D).
- **γ = 1** (conservative). A higher γ only widens the gap from HC.
- **â = 50** (normative, like a poverty line). This is below the median age at death in the
  data (64). A higher â inflates the indexes.
- fn 27: the online code allows other â, γ and poverty lines.
- **Mortality and population: Global Burden of Disease, 2017 round** (GBD Collaborative
  Network 2018).
  - Covers 1990–2017. Built from vital statistics, fertility histories and catastrophe
    data, then modelled (Dicker et al. 2018; Murray et al. 2018).
  - fn 28 processing:
    - point estimates only, with no confidence intervals (cf. the critique in Høyland,
      Moene & Willumsen 2012)
    - 5-year age bins, except under-5 split into 0–1 and 1–5
    - converted to 1-year ages assuming a **uniform death rate within each bin**
    - top bin "95+" treated as maximum age 95 (irrelevant because â ≪ 95)
- **Alive deprivation: PovCalNet** (World Bank Development Research Group 2019).
  - More than 850 surveys, 127 LMICs, 1981–2015, income or consumption.
  - Estimates come on a **three-year basis**, so they are **linearly interpolated** to annual
    values. fn 30: this smooths HC, which looks less reactive than mortality in
    catastrophes.
  - Documented in Chen & Ravallion (2013).
  - **$1.90/day** extreme poverty line (Ferreira et al. 2016).
- **Merge** at country-year level. Sample: **113 LMICs, 1990–2015** (the list is in online
  Appendix Table 2).

### C9 · Section IV.B: Worldwide deprivation (pp.250–252)

**Table 3** (â = 50, γ = 1; developing world):

| Row | Unit | 1990 | 2015 | How computed |
|---|---|---|---|---|
| Living population | PY (m) | 4,200 | 6,010 | GBD |
| HC | % | 44.9 | 11.7 | PovCalNet |
| Alive deprivation (PYAD) | PY (m) | 1,886 | 703 | Living population × HC |
| Life-span deprivation (PYPL) | PY (m) | 701 | 402 | Equation (3) |
| Deprived population | PY (m) | 2,587 | 1,105 | PYAD + PYPL |
| Reference population | PY (m) | 4,901 | 6,412 | Living population + PYPL |
| **GD₁** | % | **52.8** | **17.2** | Deprived ÷ Reference |

Arithmetic checks out (`4200 × .449 = 1885.8`; `2587 / 4901 = 52.79%`;
`1105 / 6412 = 17.23%`). Implied life-span component as a share of the reference
population: 701/4901 = **14.3%**, 402/6412 = **6.27%**. These match the endpoints of the
"World" line in Figure 7.

- **Figure 6:**
  - Stacked areas: income deprivation (dark) on top of life-span deprivation (light); the
    total height is GD.
  - Lines: HC (solid) and LDC/GD on the right axis (dashed), roughly 27% → 36%.
  - GD and HC trend together at world level; world deprivation fell sharply.
  - fn 31: GD and HC are not strictly comparable (different reference populations).
- The **life-span share rose** from 27% (1990) to more than 36% (2015): more progress
  against poverty than against premature death. These are **lower bounds** given the
  conservative parameters. With â = 80, the 2015 underestimate is above 60%.
- **Child mortality dominates:** deaths at age 5 or below are ~80% of GD's life-span
  component in 1990 and ~70% in 2015. Two reasons: high under-5 mortality rates, and a
  newborn death generates exactly **â** PYPLs.
- **Three possible drivers** of the fall in life-span deprivation:
  1. falling natality
  2. falling mortality
  3. pyramid composition inherited from pre-1990 dynamics
- **Figure 7** counterfactuals for the life-span component: 1990 births held fixed; 1990
  mortality held fixed; both held fixed (pyramid only).
  - The actual World line falls ~14.3 → ~6.3. The 1990-births line is almost identical to
    it, so **natality does not matter** (natality actually rose 2.8%).
  - The 1990-mortality and both-fixed lines fall only to ~11.5.
  - **Drivers: the mortality decline (newborn mortality 6.6% → 3.4%) and pyramid
    composition.**
  - fn 32: falling mortality is a succession of negative permanent shocks, so ID > GD over
    1990–2015.

### C10 · Section IV.C: Country level (pp.252–255)

**Levels: Gabon vs Morocco (Figure 8, Table 4)**

- HC is similar in the 1990s (both around 4–8%). GD is much higher for Gabon (about 17–20
  vs 14–16).
- 1993 ranks, least poor first: Gabon 19th (HC) → 38th (GD); Morocco 21st → 32nd. The
  paper says "That's a difference of 9 ranks out of 113". See D8: the arithmetic does not
  obviously give 9.
- Life expectancy in 1993: Morocco 67, Gabon 59.

**Table 4** (1993, thousands of PY):

| Row | Gabon | Morocco |
|---|---|---|
| Living population | 1,043 | 26,449 |
| HC (%) | 5.2 | 5.8 |
| PYAD | 54 | 1,534 |
| PYPL | 174 | 3,100 |
| Deprived | 228 | 4,634 |
| Reference | 1,217 | 29,549 |
| **GD₁ (%)** | **17.9** ⚠ | **15.7** |

⚠ See discrepancy D1: 228/1217 = **18.7%**, not 17.9.

**Re-ranking in general:**

- Average |rank change| HC → GD = **4.1** over the whole period; 4.4 in 1990, 4.9 in 2015.
- Ex-USSR countries and some African countries rank worse under GD. Latin America ranks
  better.
- The largest change is **Azerbaijan, −26 ranks in 2010 and 2014**: poverty is almost
  gone, but life-span deprivation remains high.
- Ranking critique: Høyland, Moene & Willumsen (2012).

**Trends (Figure 9):**

- **Comoros 1990–2015:** HC +60% but GD −23%. PYADs grew faster than population, PYPLs
  fell sharply, total deprived PY stayed roughly constant, and population grew ~50%.
- **Botswana 1990–2001:** HC −12%, GD +0.7% (roughly flat). The cause is the rise in
  HIV/AIDS mortality. This answers the intro puzzle.

**Figure 10:**

- Scatter of GDₜ/GDₜ₋₅ against HCₜ/HCₜ₋₅ for every country and t, with 45° and unit lines.
  Only HC ratio < 3 is shown.
- Mostly the two agree, but the slope is **flatter than 45°**: HC moved more than GD.
- **8.4%** of points lie in the NW or SE quadrants (opposite verdicts). That rises to
  **26.9%** as γ → ∞. Reversals should become more frequent as the life-span share grows.

### C11 · Section V: Conclusion (pp.255–256)

- Recap: additive time-unit aggregation follows from exclusivity. GD is the practical
  choice; ID is conceptually clean but data-hungry.
- The explicit lower bound γ ≥ 1 implies roughly **1/3 of world deprivation comes from
  premature mortality and 2/3 from poverty**. The mortality share will keep rising.
- Country-level levels **and** trends are biased if mortality is ignored.
- **Policy framing:** life-saving versus cost trade-offs are usually expressed via the
  value of a statistical life (Viscusi 1993), which the public finds opaque. The trade-off
  can instead be expressed as **"years in poverty that can be generated to save one year
  of life"**, which may allow a more peaceful deliberation.

---

## 3. Discrepancies and replication flags

**Status after running the authors' own code** (`benchmark/`, 2026-10-11). "Benchmark" =
the authors' package on its own raw data.

| ID | Paper says | Benchmark gives | Verdict |
|---|---|---|---|
| **D1** | Table 4: Gabon GD₁ = **17.9%** | **18.71%** (`228/1217`). Their do-file has `di 1043+174 // 1271` and then `228/1271 = 17.9%` | **Authors' arithmetic typo** (1271 instead of 1217). The correct value is 18.7%. Gabon's 1993 rank of 38 is unaffected because ranks use the code value |
| **D2** | 705 m poor in 2015 (intro) vs **703 m** (Table 3) | **705 m** (`gd_income_poor_1_9`) | Table 3's 703 is the hand product 6010 × 0.117, using the *rounded* HC. The intro is correct. Same story for GD₁ 2015: code 17.28 vs printed 17.2 |
| **D3** | Eq. (3): â − (a+1). fn 3: empirics assume start-of-period deaths | Code: `gd_ndeath * (age_line - age)`, i.e. **â − a** | **Resolved.** Empirical GD uses â − a; theory and the Figure 4 Excel use â − (a+1) |
| **D4** | Average re-rank **4.4 in 1990 → 4.9 in 2015** ("larger over time") | **4.92 in 1990, 4.34 in 2015**; whole period 4.14 ✓ | **The years are swapped in the paper**, so the "re-rankings have become larger over time" claim is not supported by the code |
| D5 | "LDC" in the Figure 6 legend | The code labels it "Lifespan Deprivation (LDC)" | The life-span deprivation component of GD |
| D6 | "Section ID" | — | Means Section I.D |
| D7 | Haiti uses â = 5 because "data end in 2015" | The merged panel ends in 2015 because PovCalNet does | Fine |
| D8 | Gabon/Morocco: "a difference of 9 ranks" | Gabon 19→38 (+19), Morocco 21→32 (+11) ✓ | Ranks match. The "9" still doesn't match any obvious arithmetic (relative swing = 8). Minor |
| **D9** | Median age at death = **64** (p.249) | `DescriptiveStats`-equivalent code in `VariableConstruction.do` gives a median of **58** (pooled 1990–2015, countries only) and 49 in 1990 | **Unexplained.** Possibly an earlier data vintage or a different weighting. Report it |
| **D10** | Azerbaijan loses **26 ranks in 2010 and 2014** | Benchmark: maximum 26 in 2008; 25 in 2014. **Our pipeline** (ties broken by ISO3): 26 in 2010 and 2014, maximum 27 in 2011 | **Explained by ties.** Several countries have HC ≈ 0, so their HC ranks are arbitrary (Stata's `gsort` breaks ties at random). Rank statistics near the top of the table are not robust. Worth a sentence |
| D11 | Comoros GD **−23%**; Botswana GD **+0.7%** | −22.0% and +0.54% (HC +60.9% ✓, −11.4% ✓) | Close. Rounding or vintage. Minor |

| **D12** | Sample of **113 countries** | Joining on ISO3 gives **116** | The authors' name-based join silently drops **Eswatini** (GBD "Swaziland") and **West Bank & Gaza** (GBD "Palestine"). **Kiribati** sits in their list of Japanese and Mexican sub-national units to drop, apparently by accident. `$SAMPLE = "paper"` reproduces the 113 |
| D13 | Newborn mortality 6.6% → 3.4%; births +2.8% (p.252) | 6.76% → 3.47%; +3.27% | Not computed anywhere in the authors' code; the definition is unknown. Minor |
| D14 | Table 3 cells | Code values: PYAD 1,883.7 / 705.2; GD 52.76 / 17.28 | Table 3 is **hand-filled from rounded rows** (living population to 10 m, HC to 0.1). Redoing that rounding on our numbers reproduces every cell. Same for Table 4, where Gabon's population is truncated (1043.76 → 1043) |

| **D15** | Package readme (HMD): download **cohort** life tables | Cohort tables stop at the 1933 cohort and put the WWI deaths of 20-year-olds at their birth year (1894). Figure 5 runs to 2010 with age-20 spikes at 1870/1914–18/1940–44 | **Figure 5 must have used period life tables.** The readme is wrong. We use `bltper_1x1` |
| D16 | Figure 5: discrete fall in ID in **1919** (Alsace-Lorraine) | With HMD data downloaded 2026-10-11: the fall comes in **1920** | Today's HMD dates France's border change "1920±"; the 2019 vintage evidently used 1919. A data-vintage difference. Shape otherwise identical |

**Benchmark matches exactly (after rounding):**
- Table 3: 4,200 / 6,010; 44.9 / 11.7; 701 / 402; GD 52.8 / 17.3
- Life-span share 27.1% → 36.3%; above 60% (60.35) at â = 80
- Average re-rank over the whole period 4.1
- Gabon 19→38, Morocco 21→32
- Reversals 8.42%; 26.88% as γ → ∞
- 113 countries
- Botswana HC 33.6 (1990)

**Data vintage: settled.** The package ships the original GBD 2017 extract and the
PovCalNet 2019 tables, so the replication uses these exact files. Only the **HMD**
(Figure 5) has to be downloaded fresh, which needs registration, and those numbers may
drift from the 2019 vintage.

**How the code builds things** (useful for the methodology section):
- Population at the start of the year = GBD deaths ÷ (GBD rate / 100,000), truncated to an
  integer. "Living population" = population alive at the **end** of the year
  (start − deaths).
- Age bins (<1, 1–4, 5–9, …, 90–94, 95+) are split into single years assuming a constant
  annual death rate within the bin and geometrically declining cohort sizes. Everyone in
  95+ dies that year.
- Regional and World aggregates are built by summing deaths and population **by age bin**,
  then applying the same single-year split. HC is aggregated with population weights.
- Sample: PovCalNet national (N) and aggregated (A) coverage; HC linearly interpolated
  between survey request years. Keep countries with an HC value in **every** year
  1990–2015. Drop 40 high-income countries (hard-coded list). Must merge with WB regions.
- ID from GBD assumes **past cohort deaths = today's age-specific rates** applied to the
  current pyramid. It is only computable once â years of data exist (1995+ for â = 5).
- Ranks: ascending sort by year (least deprived = 1). Average of |rank_GD − rank_HC|.
- Reversals: share of country-years with GDₜ/GDₜ₋₅ and HCₜ/HCₜ₋₅ on opposite sides of 1,
  among non-missing ratios.

---

## 4. Verified understanding

**Figure 4 baseline reproduced** (2026-10-11 session, Python, no data). Inputs: stationary
pyramid nₐ = 0.98ᵃ for a = 0…100, â = 50, no poverty.

| Quantity | Computed | Figure 4 |
|---|---|---|
| ID = d / (alive + d) | 29.51% | ≈ 29.5 (all three panels start here) |
| GD with eq. (3) | 29.51%, identical to ID | ✓ the ID-Equivalence check holds |
| GD right after the all-ages 2→1% shock (old pyramid, new μ) | 17.31% | ≈ 17 (top-panel jump) |
| New steady state at 1% | 14.14% | ≈ 14 (top-panel long run) |

The simulations therefore use eq. (3) **as printed**, with â − (a+1) and end-of-period
deaths. That matters for D3: the theory and simulation sections use one convention, and
the empirics may use another.
