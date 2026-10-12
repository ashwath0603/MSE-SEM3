# Part (e): talking points for slides 11 and 12

Numbers-first, in the textbook's manner. The rule throughout: state the number,
then say what it *means* that the number moved (or didn't), then why.

---

# SLIDE 11 — the table (about 2:15)

## 1. Orient, 20 seconds. Then stop describing.

- Six columns: pooled OLS, FE, RE — first **without** year dummies, then **with**.
- Cluster-robust standard errors by country throughout.
- Column five, **FE with year dummies**, is the preferred specification.
- Income group is blank under FE. Not missing — FE absorbs anything
  time-invariant, exactly as the zero within-SDs two slides ago predicted.
- Year dummies jointly significant in all three: F = 4.29 pooled, F = 6.51 FE,
  χ² = 58.56 RE.

## 2. The headline framing: our table is the mirror image of the textbook's

> In Wooldridge's wage example the **marriage premium collapses**, .108 → .047,
> a 57 per cent fall, and that is the finding. In our table the variable of
> interest is the one that **barely moves**, and it is the control variables
> that collapse.

- **Income elasticity: 0.800 pooled → 0.744 FE.** A fall of 0.056, only **7 per
  cent**, and roughly half of one FE standard error.
- **Ageing: 0.041 pooled → −0.000 FE.** A fall of **100 per cent**.

That contrast is the whole story of part (e), and each half means something
different.

## 3. What it means that income *doesn't* move

- Pooled says 0.800, FE says 0.744. Pooled is **higher**, so
  Cov(country effect, income) > 0.
- **Interpretation:** rich countries have fixed features that raise health
  spending on their own — deeper insurance systems, higher relative medical
  prices, more hospital capacity. Some of the cross-country gradient is those
  features, not income.
- **But the size is the point.** The overstatement is 0.056 against a standard
  error of 0.102. Economically and statistically small.
- **So:** unlike the marriage premium, the country effect is *not* materially
  confounding our parameter of interest. A result that survives all three
  estimators is a result you can lean on.

## 4. What it means that ageing and TB *do* move — and the two-step decomposition

Take the change in two stages: pooled → FE removes **country** effects;
FE → FE+years removes the **common time** effect.

| | pooled | FE | FE + years | from country effects | from common trend |
|---|---|---|---|---|---|
| Log GDP per capita | 0.798 | 0.773 | 0.744 | 46% | 54% |
| Govt final consumption | 0.014 | 0.020 | 0.017 | 67% | 33% |
| **Population 65+** | 0.041 | 0.023 | −0.000 | **44%** | **56%** |
| **Log TB incidence** | −0.090 | −0.074 | 0.002 | **17%** | **83%** |
| NCD mortality | −0.013 | −0.014 | −0.007 | 13% | 88% |

- **Ageing, in plain numbers.** Pooled says a 1 percentage point higher 65+
  share goes with **4.1 per cent** higher health spending per capita. FE cuts
  that to 2.3 per cent, and year dummies take the rest to zero.
  - The first cut (44%) is cross-country confounding: **old countries are rich
    countries**, and they had big health systems already.
  - The second cut (56%) is a shared trend: **every** country is ageing while
    **every** country's health spending is rising. Without year effects, FE
    credits that common drift to whichever regressor drifts alongside it.
- **TB is 83 per cent a trend story.** Pooled says 1 per cent higher TB
  incidence goes with 0.089 per cent *lower* spending; under FE with years it is
  0.002, i.e. nothing.
- **State the honest conclusion out loud:** this is not evidence that ageing
  does not matter for health spending. It is that twelve years of
  within-country variation, net of a common trend, **cannot identify it**.

## 5. The one coefficient where the bias runs the *other* way

- Government consumption: pooled **0.014**, FE **0.017**. Pooled is *lower* —
  it **understates** by 21 per cent.
- So Cov(country effect, fiscal share) < 0. Countries that persistently run
  large government consumption shares tend to be poorer, and spend less per head
  on health.
- **Meaning:** comparing across countries *masks* the effect. Within a country,
  a 1 percentage point rise in the government consumption share goes with
  **1.7 per cent** higher health spending per capita, against the 1.4 per cent
  the cross-country comparison suggests.
- This is also the **only regressor significant in all six columns**, and not a
  coincidence: it is the only one with real within-country variation (12 per
  cent of its variance, and year dummies take only 3 per cent of that).

## 6. The price of fixed effects, in standard errors

FE against pooled, with year dummies:

| | pooled SE | FE SE | increase |
|---|---|---|---|
| Log GDP per capita | 0.063 | 0.102 | **+62%** |
| Govt final consumption | 0.004 | 0.007 | +75% |
| **Population 65+** | 0.004 | 0.012 | **+200%** |
| Log TB incidence | 0.028 | 0.031 | +11% |
| NCD mortality | 0.004 | 0.006 | +50% |

- FE is **not free**. It buys consistency by discarding the between-country
  variation, and you pay in precision.
- The **triple** on ageing is the sharpest single number here: FE has so little
  within-country movement in age structure to work with that the standard error
  triples.
- Tie it back: only **0.7 per cent** of the variance in log GDP is
  within-country, so the 62 per cent rise on income is exactly what the summary
  statistics predicted.

## 7. Where RE sits — and it is not halfway for everything

Percentage of the distance travelled from pooled toward FE:

| | RE lands at | % of the way to FE |
|---|---|---|
| Log GDP per capita | 0.746 | **96%** |
| Govt final consumption | 0.017 | 100% |
| Population 65+ | 0.021 | 49% |
| Log TB incidence | −0.041 | 53% |
| NCD mortality | −0.010 | 50% |

- RE is **essentially at FE** for income and fiscal capacity, but only **about
  halfway** for the slow-moving controls.
- **Why, and resist the easy answer.** It is not λ. At λ = 0.872 the transformed
  regressor is still **70 per cent** between-country. What removes the
  between-country identification for income is the **income group dummies**,
  which explain **87 per cent** of the cross-country variation in log GDP.
- **The check:** replace the income dummies with region dummies and RE moves to
  **0.818**, while FE stays at **0.744** whatever control we use.

## 8. Two things to say before someone asks

- **R² of 0.953 vs 0.445 is not a comparison.** The first is overall fit,
  dominated by between-country variation; the second is within-country fit.
- **Income group is the one real disagreement.** FE absorbs it; pooled finds it
  insignificant because log GDP already carries the gradient; RE recovers a high
  income premium of 0.604. Treat that with caution — identified purely off
  between-country variation, which Hausman tells us not to trust, and the
  classification is measured from 2025 GNI.

---

# SLIDE 12 — the income coefficient (about 1:30)

## 1. Say it in one sentence, stressing *within*

> A one per cent rise in real GDP per capita **within a country** is associated
> with a **0.744 per cent** rise in real health expenditure per capita, holding
> fiscal capacity, ageing, disease burden and common year effects constant.

- Not "rich countries spend more than poor countries." The **same country**,
  spending more as it grows. That distinction is the entire reason for panel
  data.

## 2. It is the elasticity, so the research question is one test

- Log-log, so β₁ **is** the income elasticity — no transformation needed.
- **t(144) = −2.51**, p = 0.013 two-sided. Equivalently F(1,144) = 6.29, since
  F = t² for a single restriction.
- 144 df because there are 145 clusters.
- **95% CI = [0.542, 0.946]** — excludes 1. Same answer a third way.

## 3. What "below one" means in numbers, not adjectives

- The elasticity of the health **share** of GDP with respect to income is
  β₁ − 1 = **−0.256**.
- So a **10 per cent** rise in income per head lowers the health share by about
  **2.4 per cent**.
- Over a decade at 3 per cent growth a year — a 34 per cent income rise — the
  health share falls about **7 per cent**: a country at 7.9 per cent of GDP
  drifts to roughly **7.3 per cent**.
- **The policy point:** you cannot explain rising health shares by saying
  countries got richer. Growth on its own predicts a **falling** share. The rise
  has to come from somewhere else — medical technology, relative price growth in
  a labour-intensive sector, ageing, or deliberate policy expansion.

## 4. Against Xu et al., in our own standard errors

- Their range is 0.75 to 0.95. Ours is 0.744.
- **0.06 standard errors** below their lower bound — indistinguishable.
- **2.02 standard errors** below their upper bound.
- **So:** we are not claiming a lower elasticity. We are reproducing the same
  one, on a different decade, a revised accounting standard, an extra regressor,
  and a window containing a pandemic. The conclusion is robust.

## 5. Close by conceding the limit before anyone presses it

- This is a **conditional within-country association**, not a causal elasticity.
- Health spending is a **component** of GDP, so income is not strictly
  exogenous — the thing we are explaining sits inside the thing we are
  explaining it with.
- That is the first item on the next slide.
