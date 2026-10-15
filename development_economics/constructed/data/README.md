# Constructed data: what is here and where it came from

These are the source files `scripts/constructed.do` reads, **exactly as downloaded**. We did not
use the authors' extracts for poverty or mortality. We went back to the original public sources
and downloaded them ourselves. Nothing here is ever edited; every transformation happens in the
do-file, and its intermediate datasets go to a temporary folder deleted at the end of the run.

| Folder | Replaces (authors' package) | Used for |
|---|---|---|
| `gbd2023/` | GBD 2017 extract | deaths and population by age, every country |
| `wdi_archive_201912/` | PovCalNet extract | $1.90/day poverty headcount |
| `hmd/` | nothing (the package has no HMD data) | France, Figure 5 |

## `gbd2023/`: Global Burden of Disease 2023, all-cause deaths

Global Burden of Disease Collaborative Network. *Global Burden of Disease Study 2023 (GBD 2023)
Results*. Seattle: IHME, 2024. <https://vizhub.healthdata.org/gbd-results/>

- **How obtained:** the GBD Results tool (free IHME account), on **2026-10-15**. The tool caps
  each download, so the request was split by age into six files. Settings for every file:
  - GBD estimate: *Cause of death or injury*; Measure: *Deaths*; Metric: *Number* and *Rate*
  - Population files: the same settings with Measure *Population* (Metric *Number*)
  - Cause: *All causes*; Sex: *Both*; Location: *all countries and territories* (204)
  - Year: *1990 to 2017* (the population files cover 1990-2023)
  - Then *Download*, not *Search* (the tool will not display this many rows)
- Each zip holds one csv and IHME's `citation.txt`. One file arrived already unzipped
  (`IHME-GBD_2023_DATA-75c4dc7e-1/`).

| File | Measure | Age groups | SHA-1 |
|---|---|---|---|
| `IHME-GBD_2023_DATA-75c4dc7e-1/` | Deaths | <5, 5-9 ... 35-39 | `74b8470f…` (csv) |
| `IHME-GBD_2023_DATA-24182c5b-1.zip` | Deaths | 40-44 ... 75-79 | `887dc2ab…` |
| `IHME-GBD_2023_DATA-5c757971-1.zip` | Deaths | 80-84 ... 95+ | `9c34a5a1…` |
| `IHME-GBD_2023_DATA-51274382-1.zip` | Deaths | <1 year, 12-23 months, 2-4 years | `cb0e4fac…` |
| `IHME-GBD_2023_DATA-b9533d8b-1.zip` | Population | <5, 5-9 ... 65-69 | `e1f9cd81…` |
| `IHME-GBD_2023_DATA-ae868de3-1.zip` | Population | 40-44 ... 95+ | `efed5662…` |

- **Why GBD 2023, not the authors' GBD 2017:** the Results tool only serves the latest round.
  GBD 2017 is archived on GHDx behind an IHME login. So this is a revised vintage, not a
  re-download of the same numbers.
- **No "1-4 years" group in GBD 2023.** It is split into 12-23 months and 2-4 years, which
  step 1 adds back. The split matters: about 80% of under-5 deaths are infants, and merging
  <1 with 1-4 would cut the years lost below age 5 by a third.
- **Population is a check only.** As the authors do, the do-file recovers population as
  deaths / rate. Step 1 asserts that this equals the downloaded population in all 114,240 cells,
  and that <1 + 12-23 months + 2-4 years equals the <5 file.

## `wdi_archive_201912/`: World Bank WDI Database Archives, release Dec 2019

World Bank. *WDI Database Archives* (API source 57), version 201912.
<https://api.worldbank.org/v2/sources/57>

- **How obtained:** by `../scripts/fetch_wdi_archive.py` on **2026-10-15** (World Bank API, no
  login). Rerunning it downloads the same release again.

| File | What it is |
|---|---|
| `SI.POV.DDAY.json` | $1.90/day headcount (2011 PPP), %, **survey years only** |
| `SI.POV.GINI.json` | Gini index, survey years only |
| `NY.GDP.PCAP.KD.json` | GDP per capita, constant 2010 US$ |
| `NE.CON.PRVT.PC.KD.json` | Household final consumption per capita, constant 2010 US$ |
| `countries.json` | Country metadata from the live API. Used only to drop aggregates and flag Sub-Saharan Africa |
| `wdi_201912_long.csv`, `countries.csv` | The same values flattened by the fetch script, because Stata cannot read JSON. No values changed |

- **Why this source:** PovCalNet is retired, and its successor PIP refuses requests for the
  2011-PPP $1.90 series ("authorization required by server", 2026-10-15). The Dec 2019 archive
  is the same vintage as the authors' PovCalNet download (11 Dec 2019).
- **What step 2 does with it:** the archive has the headcount only in survey years.
  PovCalNet's published series also fills the years between surveys (its "line-up"). Step 2
  rebuilds that:
  - Each survey becomes a log-normal income distribution with the survey's Gini.
  - It is moved to other years with national-accounts growth: household consumption per
    capita, or GDP per capita in Sub-Saharan Africa (PovCalNet's rule).
  - Between two surveys, PovCalNet's interpolation rule is applied.

## `hmd/`: Human Mortality Database, France (Figure 5 only)

University of California, Berkeley, and Max Planck Institute for Demographic Research.
*Human Mortality Database*. <https://www.mortality.org>

- **How obtained:** registered on mortality.org, then *Data > Download HMD data > All HMD
  countries*, on **2026-10-11** (files stamped "Last modified: 27 Aug 2026; Methods Protocol
  v6"). Identical to `../../replication_package/data/hmd/`.
- `lt_both.zip`: **period** life tables, both sexes (SHA-1 `cbf25331…`). `population.zip`:
  population on 1 January by single age (SHA-1 `af7c0224…`). France = `FRATNP`.

## `wb_class/`: not used

`CLASS_2026_10_08.xlsx` and `OGHIST_2026_10_08.xlsx` are the World Bank's current and historical
income classifications, downloaded on 2026-10-15. The do-file does **not** read them: it keeps the
authors' 2019 high-income list and regions, so that the sample rule matches the paper's.

## What the default run still takes from the authors' package

No poverty or mortality **values** from the package enter the default run. It does read these
files from `../../replication_package/data/119941-V1/Data/`:

- `PovCalNet/PovCalNet1_9_2019.csv`: the **list of countries** and their **names**, so the
  constructed series covers the same countries and GBD names can be matched to ISO3 codes.
  Its values are used only in the comparison table `compare_lineup.csv`.
- `region/WB_class.xls`: World Bank **regions**, for the regional aggregates.
- The authors' **high-income list** (40 countries, written into step 4), which removes
  high-income countries from the sample.
- `GBD/IHME-GBD_2017_DATA-f89cefb0-1.csv`: only for the comparison table `compare_gbd.csv`,
  and when the `MORTALITY` switch is set to `"package"`.

## Caveats

### Poverty

- **Survey years agree.** At the 620 survey years both sources cover, 95% of headcounts agree
  within 0.05 percentage points.
- **The filled years are an approximation.** Over request years 1990-2015, the constructed series
  has a correlation of 0.989 with the authors' series. The median gap is 0.12 pp; 81% of cells
  are within 1 pp and 96% within 5 pp. The gaps come from:
  - the log-normal (PovCalNet used the full survey distribution, no longer public for this
    vintage);
  - Ginis borrowed from the nearest survey when one is missing;
  - extrapolating back before a country's first survey in the archive.
- **Seven countries leave the sample** (the paper's rule needs a headcount in every year
  1990-2015). In each case the archive has no national-accounts series to move a survey to the
  missing years:

  | Country | Surveys in archive | National accounts start | Years missing |
  |---|---|---|---|
  | Bosnia and Herzegovina | 2001+ | 1994 | 1990, 1993 |
  | Moldova | 1997+ | 1995 | 1990, 1993 |
  | Serbia | 2012+ | 1995 | 1990, 1993 |
  | Montenegro | 2005+ | 1997 | 1990-1996 |
  | Liberia | 2007+ | 2000 | 1990-1999 |
  | Djibouti | 2002, 2012, 2013, 2017 | none | all but 2002, 2012, 2013 |
  | Syria | 2004 only | none | all 12 request years |

  The authors' file has values for these years because PovCalNet's national-accounts series
  reached further back than the archive's. Those values are one survey stretched back across wars. Examples:
  - Bosnia: 5.0% (1990), 39.7% (1993), 1.6% (1996), all from a 2001 survey.
  - Liberia: 92% (1993), from a 2007 survey.
  - Syria: every year from a single 2004 survey.

  We chose not to fill the gaps with a third source (e.g. the Maddison Project), so as not to
  rebuild extrapolations that are not observations.
- **Venezuela enters.** The authors' file stops in 2013, on a 2006 survey, so it fails the
  every-year rule. The constructed series reaches 2015.
- **Haiti: very different headcounts before 2012.** The archive lacks Haiti's 2001 survey, so the
  series is extrapolated back from its 2012 survey: 16% (1995) and 19% (2005), against the
  authors' 55% and 57%. By 2015 the two agree (25% vs 23%). This shifts the level of Haiti's
  ID in Figure 3; its life-span component comes from mortality and is not affected.

### Mortality (GBD 2023 vs the authors' GBD 2017; table `compare_gbd.csv`)

- Total deaths 1990-2017 differ by +0.5%. Ages 25-89 are within 2%.
- Infant deaths are 6% lower.
- **Ages 5-19 are 22-29% higher.** This is concentrated in poor Sub-Saharan countries and Haiti,
  where deaths at these ages are often 2-3 times the 2017 round. GBD revisions, not our code.
- Ages 90+ are noisy (for 95+, half the cells differ by more than 50%). This barely matters,
  because everyone in the 95+ group is treated as dying at 95.
- Births are revised up: births grow by 11% over 1990-2015, against the paper's 2.8%.
- Haiti's 2010 earthquake is larger in GBD 2023 (88,000 under-5 deaths against 52,000), so the
  2010 spike in Figure 3 is bigger.
- **Tuvalu enters the sample:** GBD 2017 did not cover it. Its 95+ age group holds under one
  person, so step 6 treats it as empty.
- GBD 2023 renamed 13 countries (Viet Nam, Türkiye, ...). Step 3 maps them to ISO3 by hand.

### Sample, by run

| Run | Countries | Change from the paper's 113 |
|---|---|---|
| Replication | 113 | none |
| Constructed poverty only | 107 | 7 countries out, Venezuela in |
| Constructed mortality only | 114 | Tuvalu in |
| **Constructed (both, the default)** | **108** | 7 out, Venezuela and Tuvalu in |

### Effect on the results

- **World GD** (â = 50): 52.90% in 1990 and 17.22% in 2015, against the paper's 52.8% and 17.2%.
- **The lost countries do not drive the poverty difference.** We split the change in World GD
  from the poverty-only run into its parts:

  | | 1990 | 2015 |
  |---|---|---|
  | Replication, 113 countries | 52.76 | 17.28 |
  | Drop the 7 countries (authors' values) | +0.29 | -0.02 |
  | Our headcounts instead of theirs, same 106 countries | -0.21 | -0.23 |
  | Add Venezuela | -0.16 | -0.02 |
  | Constructed poverty only, 107 countries | 52.68 | 17.01 |

  The 7 countries are about 0.8% of the sample population. A smaller sample does change
  **rankings**, because a country's rank moves when others leave.
- **With GBD 2023:**
  - Years of life lost in 1990 rise from 701m to about 725m.
  - The life-span share of GD rises from 27% to 28% (1990) and from 36% to 37% (2015).
  - The under-5 share of years lost falls from about 79% / 68% to 75% / 65%.
- **Country GD ranks** (Spearman, by year) correlate 0.976-0.994 with the replication;
  0.996-0.999 with GBD 2023 alone, so most of the reranking comes from poverty.
- **One published example breaks: Table 4, Gabon vs Morocco.** The paper's point is that Gabon
  has a lower headcount but a higher GD. With constructed poverty, Gabon's 1993 headcount
  (5.84%) is above Morocco's (5.53%), so the contrast is lost.
  - The cause is poverty, not mortality: the example holds in the mortality-only run.
  - Azerbaijan still loses ranks (Section IV), but fewer: 10-14 instead of 26.

The `POVERTY` and `MORTALITY` switches at the top of `constructed.do` regenerate the
single-input runs (written to `../output/sensitivity_*/`), so each attribution above can be
checked.
