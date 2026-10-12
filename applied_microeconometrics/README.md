# Applied Microeconometrics 2026 — Computer Assignment 1 (Panel Data)

Group: **G3**

Team members: _TBD_

Reference paper: Xu, K., Saksena, P., & Holly, A. (2011). *The Determinants of Health
Expenditure: A Country-Level Panel Data Analysis.* World Health Organization / Results for
Development Institute Working Paper. → [`assignment/G3paper.pdf`](assignment/G3paper.pdf)

Assignment brief: [`assignment/assignment.pdf`](assignment/assignment.pdf)

## Deadlines

| Deliverable | Due |
|---|---|
| ~~Reference paper (`G3paper.pdf`)~~ | ~~19 Aug 2026~~ ✅ |
| **Data file (`G3.dta`)** | **29 Aug 2026** |
| Analysis PDF (`G3.pdf`) | 2 Sep 2026 |
| Presentation | week of 7 Sep 2026 |

## Pipeline

```
World Bank API ──00_fetch_raw.R──►  data/raw/*.csv ──01_build_panel.R──►  data/G3.dta
(WDI + GHED via SH.XPD.*)          (superset: all                        (balanced panel,
                                    countries/years)                      145 x 12)
                                                          │                      │
                        02_checks.R (asserts N≥50, N>>T, ─┘                      │
                        ≥2 time-varying, ≥1 time-invariant)                      ▼
                                                                          analysis.do
                                                                              │
                                              output/figures/*.pdf ◄───────────┘
                                                          │
                                                          ▼
                                              writeup/main.tex (Overleaf)
```

**R builds the data, Stata does the econometrics.** R handles the wide→long reshape, the
ISO3 joins and the missingness audit far more cleanly than Stata; Stata owns `xtsum`,
`xtreg` and `hausman` because those are what the course grades.

Tables are written by hand into `writeup/main.tex` rather than exported from Stata, so
the write-up stays a single self-contained file that pastes into Overleaf. `analysis.do`
prints every number those tables contain.

## Running it

```bash
# from this directory
Rscript scripts/00_fetch_raw.R        # pulls WDI+GHED extracts into data/raw/ (~9 MB)
Rscript scripts/01_build_panel.R      # writes data/G3.dta
Rscript scripts/02_checks.R           # fails loudly if a constraint is violated
stata -b do scripts/analysis.do       # prints all results, writes output/figures/
```

Only the last step is needed to reproduce the write-up, since `data/G3.dta` is committed.
Open `analysis.do` in the Do-file Editor and click Execute; nothing needs installing.

`00_fetch_raw.R` is cached — it skips anything already in `data/raw/` unless given
`--force`. Raw extracts are git-ignored, so that is the first command to run on a fresh
clone.

The `stata` alias resolves to Stata SE 17's console binary (defined in `~/.zshrc`).

## Design decisions — TO CONFIRM

These are open and shape the whole build:

| Decision | Options | Leaning |
|---|---|---|
| Time window | 2000–2022 (T=23) vs 2010–2022 (T=13) | 2010–2022 — cleaner, keeps N>>T comfortable, still covers COVID |
| Dependent variable | total / government / out-of-pocket health expenditure | Total health expenditure p.c., PPP, logged |
| Time-invariant variable | income group (base year) / region / landlocked | Income group, mirrors the paper |

## Departure from the reference paper (assignment Q2)

The paper covers **1995–2008** under the pre-SHA-2011 accounting standard. WHO's GHED has
since migrated to **SHA 2011**, redefining the expenditure aggregates, and now runs to 2022.
The intended departure is therefore to re-estimate on a **modern panel under current
definitions**, spanning the post-2008 crisis and the **COVID-19 shock** — a period wholly
absent from the original.

Note the paper estimates static FE and then Blundell–Bond system GMM (`xtdpdsys`). This
assignment asks instead for **Pooled / FE / RE with and without time dummies**, plus the
three model-comparison tests. The GMM is out of scope and deliberately not replicated.

## Constraints the assignment grades

- N ≥ 50 cross-section entities, and N >> T
- ≥ 2 regressors that are both entity-variant and time-variant
- ≥ 1 time-invariant regressor (FE will drop it — that contrast is part of the answer)
- Tables formatted via `outreg2`; **raw Stata output pasted into the PDF loses marks**
- Every test stated with H₀, H₁, statistic, df, decision
