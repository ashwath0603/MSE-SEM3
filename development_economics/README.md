# Development Economics 2026: Replication and Extension Project

Team members (3): Ashwath, Drishti, Johan

Group leader / contact: Drishti (email and phone: _to add_)

Reference paper: Baland, J.-M., Cassan, G., & Decerf, B. (2021). "Too Young to Die":
Deprivation measures combining poverty and premature mortality. *American Economic Journal:
Applied Economics, 13*(4), 226–257. <https://doi.org/10.1257/app.20200122>
→ [`assignment/baland_cassan_decerf_2021.pdf`](assignment/baland_cassan_decerf_2021.pdf)

Project brief: [`assignment/project_guidelines.pdf`](assignment/project_guidelines.pdf)

Section-by-section reading notes, every number with its page, and known discrepancies:
[`notes/paper_notes.md`](notes/paper_notes.md)

## Deadlines

| Deliverable | Due | Where |
|---|---|---|
| 1-page proposal (paper, dataset, members, leader's email and phone) | 15 Sep 2026 | Classroom → "Project Proposal". _Status: confirm it was submitted_ |
| **Replication PDF** | **17 Oct 2026** | Classroom → "Replication Submission" |
| Presentation (≤ 15 min including Q&A) | first ~1.5 weeks of Nov 2026 | In class |
| **Final project PDF** | **14 Nov 2026 (Sat), 17:00 IST** | Classroom → "Final Submission" |

Dates may change; the instructor announces changes in class.

## What each submission must contain

**Replication PDF (17 Oct):**

- Title
- Introduction
- Data
- Methodology
- Replication, with the replicated tables and figures
- **If anything fails to match:** an extra section explaining plausible reasons. Discrepancies
  already spotted in the published paper are listed in
  [`notes/paper_notes.md` §3](notes/paper_notes.md).

**Final PDF (14 Nov), in this order:**

1. Title page (authors and affiliation)
2. Abstract (150–200 words)
3. Introduction
4. Literature review
5. **Extension** (gap, motivation, relevance)
6. Data and methodology
7. Results and discussion, contrasted with the replication
8. Policy implications
9. Conclusion
10. References in **APA** style, with in-text citations
11. Tables and figures placed in the body: **tables titled above, figures titled below**
12. Appendix
13. Each member's contribution
14. AI-use declaration

**Formatting:**

- Times New Roman 12 pt, 1.5 line spacing, 2.54 cm margins
- Page numbers and section numbers
- Short sentences, active voice, present tense (past tense only for past facts)

## Grading (40 marks)

| Component | Marks | What is assessed |
|---|---|---|
| Replication | 15 | Motivation and literature. **Theoretical mechanism mapped explicitly.** Baseline equations and notation stated correctly. Tables and figures reproduced accurately. Divergences explained |
| Extension | 10 | Gap identified and verified as unstudied. Quality of analysis. Robustness checks. Policy implications |
| Guidelines, writing, formatting | 5 | All instructions followed. Labelling. References |
| Presentation | 10 | Motivation, existing evidence, results |

## Integrity rules: read before writing anything

- **Plagiarism**, including copied text, uncredited paraphrase, or *work generated entirely
  by external tools*, scores **zero for the whole team**. Submissions are checked
  automatically.
- **AI is allowed only for:**
  1. ideation and brainstorming
  2. help with literature search
  3. cleaning code and fixing syntax
  4. grammar and sentence construction

  Usage **must be self-declared**. So: the team writes the report prose; AI assists. The
  [AI-use log](#ai-use-log) below exists so the declaration can be written accurately.

## Data the paper uses

| Input | Source (as used in the paper) | Status today | Needed for |
|---|---|---|---|
| Population and deaths by age, country and year | Global Burden of Disease, **2017 round** (IHME), 1990–2017 | Later GBD rounds revise history. **Verify** whether the GBD 2017 extract is still downloadable or ships in the package | Table 3, Figures 3, 6–10, Table 4 |
| Head-count ratio at **$1.90/day** | **PovCalNet** (World Bank), 3-yearly, linearly interpolated | PovCalNet has been retired (succeeded by PIP), and the line has been rebased since. **Verify** | Table 3, Figures 6, 8–10, Table 4 |
| French mortality from 1816 | Human Mortality Database | ✅ Downloaded 2026-10-11 (period tables, not the cohort tables the package readme asks for) | Figure 5 only |
| None | Analytical simulation | Baseline already reproduced (paper_notes §4) | Figures 2 and 4, Tables 1 and 2 |
| Code and data | openICPSR **E119941V1** (<https://doi.org/10.3886/E119941V1>) | **First thing to fetch.** Determines how feasible a faithful replication is | Everything |

## Design decisions: TO CONFIRM

| Decision | Options | Leaning |
|---|---|---|
| Replication scope | Every table and figure vs core empirics | ✅ Everything except Figure 1 (a schematic) |
| Data vintage for the replication | Package extracts vs fresh GBD/PIP downloads | ✅ **Decided:** package extracts (GBD 2017, PovCalNet 2019). Fresh data belongs in the extension |
| Software | R / Stata / Python | ✅ **Decided:** Stata, written independently of the authors' do-files |
| Sample | Paper's 113 vs ISO3 join (116) | ✅ 113 for the replication (`$SAMPLE = "paper"`); 116 as a robustness check |
| Writeup tool | LaTeX (Overleaf) vs Word | _TBD_. Must meet the Times New Roman / 1.5 / 2.54 cm spec |
| Extension direction | See ideas below | Not yet decided. Revisit after the replication |

## Extension: candidate directions (brainstorm, not decided)

Each candidate must be checked against the literature to confirm nobody has done it.
The full reasoning is in the 2026-10-11 chat; the shortlist is below.

| # | Idea | Gap it fills | Main data | Notes |
|---|---|---|---|---|
| 1 | **Indian states:** GD with state MPI or HC, NFHS-4 → NFHS-5 | The paper covers countries only. Do Indian state rankings flip? | SRS age-specific death rates; NITI Aayog MPI or HCES poverty; Census population projections | Strong local relevance; feasible |
| 2 | **First empirical ID:** GBD now reaches back to 1950 | The paper says ID cannot be computed for LMICs | GBD 2021 (1950–2021) | Ties directly to the theory. Borders are harmonised by GBD |
| 3 | **MPI + GD and the double-counting problem:** the MPI already includes child mortality | MPI violates the exclusivity premise | OPHI/UNDP global MPI microdata indicators | Conceptual contribution. Needs indicator-level data |
| 4 | **COVID-era update:** GBD 2021 + PIP to 2021 | Data stop in 2015 | GBD 2021, PIP | **Overlaps with Decerf, Ferreira, Mahler & Sterck (2021), *World Development*, "Lives and livelihoods". Verify** |
| 5 | **GD by sex** (Axiom 10) | The paper does not decompose by group | GBD by sex; poverty by sex is scarce | Data for alive deprivation is the bottleneck |
| 6 | **Uncertainty in rankings:** GBD intervals into GD ranks | fn 28 drops the intervals | GBD lower and upper bounds | Probably best as a robustness section, not the main extension |
| 7 | **Drivers of GD–HC divergence:** panel regression on health spending, HIV, conflict | The paper is purely descriptive | GBD + PIP + GHED (already pulled for Applied Micro) | Endogeneity must be addressed |
| — | â × γ sensitivity surface | — | — | Too thin alone. Use as robustness |

## Layout

```
development_economics/
├── README.md            this file: brief, deadlines, decisions, log
├── assignment/          paper + guidelines PDFs
├── notes/paper_notes.md chunked reading notes; §3 = every discrepancy found
├── data/raw/            READ ONLY, git-ignored (see data/raw/README.md)
│   ├── 119941-V1/       authors' openICPSR package, unchanged
│   └── hmd/             HMD bulk zips (France = FRATNP) for Figure 5
├── data/clean/          everything our scripts build
├── benchmark/           authors' code, patched only to run on macOS (PATCHES.md)
├── scripts/             OUR replication, run in order by 00_master.do
├── output/replication/  tables/ (csv) and figures/ (pdf, png)
└── writeup/             replication/, final/, presentation/
```

## Running it

```bash
cd development_economics
stata -b do scripts/00_master.do          # raw data -> every table and figure (~1 min)

# only needed once, for the checks in 20_compare.do:
zsh benchmark/apply_patches.sh && (cd benchmark && stata -b do Code/Master.do)
```

`scripts/_run_one.do <step>` re-runs a single step (e.g. `stata -b do scripts/_run_one.do
10_tables`) with the same globals. It is a development helper.

| Script | Does | Paper output |
|---|---|---|
| `01_gbd_clean` | GBD deaths and rates → population by age bin; ISO3 crosswalk | — |
| `02_povcal_clean` | PovCalNet HC, interpolated annually | — |
| `03_panel` | Merge, 113-country sample, regional and World aggregates | — |
| `04_single_ages` | 5-year bins → single ages 0–95 | — |
| `05_gd` | Generated Deprivation for â ∈ {5, 40, 50, 80} | core of everything |
| `06_id_gbd` | Inherited Deprivation (â = 5) | Figure 3 |
| `07_counterfactuals` | 1990 births / mortality held fixed | Figure 7 |
| `08_hmd_france` | France 1816–2024 from HMD period tables, â = 40 | Figure 5 |
| `09_simulations` | Toy examples and the shock simulations, no data | Tables 1–2, Figures 2 and 4 |
| `10_tables` | Tables 3–4 and **51 published numbers checked** → `targets.csv` | Tables 3–4, Section IV text |
| `11_figures` | Figures 2–10 | Figures |
| `20_compare` | Our numbers vs the authors' code and Excel → `compare_benchmark.csv` | verification |

## Replication status (2026-10-11)

- **Against the authors' own code:** every GD variable for all 3,120 unit-years (113
  countries, 6 regions and the World, 1990–2015) agrees to within a relative 3×10⁻⁷. ID
  agrees to within 1×10⁻⁷. Figure 4 matches the authors' Excel sheet exactly. The
  counterfactual worlds differ by at most 0.02% (a documented method choice).
- **Against the printed paper:** 39 of 51 numbers reproduced. All 12 gaps are explained or
  flagged in `notes/paper_notes.md` §3. Main ones:
  - Gabon's Table 4 value is an arithmetic typo (18.7%, not 17.9%).
  - The 1990 and 2015 average re-ranks are swapped.
  - Median age at death is 58, not 64.
  - Three eligible countries are silently dropped from the authors' sample.
- **France (Figure 5):** matches the authors' code on the same HMD files (to within 1×10⁻⁷).
  The shape matches the paper. The Alsace-Lorraine drop falls in 1920, not 1919 (a
  difference in HMD data vintage). The package readme asks for cohort tables, but the
  figure needs period tables.
- **Every table and figure in the paper except Figure 1 (a schematic) is now reproduced.**

## Log

| Date | What | Who |
|---|---|---|
| 2026-10-11 | Folder created. Paper and guidelines copied into `assignment/` (two guideline copies in Downloads had identical text; kept the later one). README and `notes/paper_notes.md` written | Ashwath + Claude |
| 2026-10-11 | Read the paper end to end. Checked the arithmetic of Tables 1, 3 and 4: **Gabon GD₁ in Table 4 does not add up** (D1). Reproduced the **Figure 4 baseline** analytically (29.5% → 17.3% → 14.1%), which confirms eq. (3) as used in the simulations | Claude |
| 2026-10-11 | Brainstormed extension candidates (table above). Nothing decided | Ashwath + Claude |
| 2026-10-11 | Replication plan agreed: Stata; Claude drafts and the team adapts; folder layout adopted. Authors' package copied into `data/raw/119941-V1` | Ashwath + Claude |
| 2026-10-11 | **Benchmark:** authors' code run on macOS with 6 documented, non-computational patches. Reproduces the paper's headline numbers | Claude |
| 2026-10-11 | **Our pipeline** `scripts/00–11, 20` drafted and run end to end. Matches the benchmark (see status). Found: Table 4 typo, swapped re-rank years, 3 silently dropped countries, tie-sensitive ranks, hand-rounded Table 3 | Claude |
| 2026-10-11 | HMD France downloaded (period life tables + population, bulk files). `08_hmd_france.do` written; benchmark fed the same files. Figure 5 done. Found: readme's "cohort" should be "period"; Alsace-Lorraine break now in 1920 | Ashwath + Claude |

## AI-use log

For the self-declaration the guidelines require. Record what AI was used for, in the
course's permitted categories.

| Date | Tool | Category | What |
|---|---|---|---|
| 2026-10-11 | Claude Code | Ideation; literature (reading support) | Summarised and indexed the reference paper into notes, checked table arithmetic, brainstormed extension directions. No submission prose written |
| 2026-10-11 | Claude Code | Code | Patched the authors' do-files to run on macOS (`benchmark/`) |
| 2026-10-11 | Claude Code | Code (**first drafts**) | Drafted `scripts/00_master` and `01`–`11`, `20` (Stata, including `08_hmd_france`) and ran and debugged them. **To do by the team:** read, run and adapt each script; record here who reviewed which |
