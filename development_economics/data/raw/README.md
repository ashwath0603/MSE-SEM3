# data/raw: READ ONLY

The source files go here **exactly as obtained**. Never edit them. The contents are
git-ignored; only this file and `.gitkeep` are tracked. Every transformation happens in
`../../scripts/`.

## `119941-V1/`: the authors' replication package

Baland, J.-M., Cassan, G., & Decerf, B. (2021). *Replication data for: "Too Young to
Die"*. openICPSR, E119941V1. <https://doi.org/10.3886/E119941V1>

Downloaded by Ashwath on 2026-10-11 and copied here unchanged (verified with `diff -rq`
against `~/Downloads/119941-V1`). 49 MB.

| File | What it is | Authors' access date |
|---|---|---|
| `Data/GBD/IHME-GBD_2017_DATA-f89cefb0-1.csv` | GBD 2017 all-cause deaths, both sexes, every age group, every location, 1990–2017. Number **and** rate per 100k, with upper and lower bounds | 2019 |
| `Data/PovCalNet/PovCalNet{1_9,3_2,5_5}_2019.csv` | PovCalNet "economies table" at $1.90 / $3.20 / $5.50 (2011 PPP), 1981–2015 | 11 Dec 2019 |
| `Data/region/WB_class.xls` | World Bank country classification (regions) | — |
| `Data/HMD/Readme.txt` | Download instructions only. **No data** | 19–20 Oct 2019 |
| `Code/*.do` | Authors' Stata code. Used only via `../../benchmark/` | — |
| `Figure 4/Figure_4_MortalityShocks.xlsx` | Excel simulation behind Figure 4 | — |

These are vintage extracts: PovCalNet has since been retired, and later GBD rounds revise
1990–2017. Using these exact files is what makes a faithful replication possible.

## `hmd/`: Human Mortality Database, France (Figure 5 only)

University of California, Berkeley, and Max Planck Institute for Demographic Research.
*Human Mortality Database*. <https://www.mortality.org>. Downloaded by Ashwath on
**2026-10-11**; the files are stamped "Last modified: 27 Aug 2026; Methods Protocol v6".
The authors' package ships no HMD data, probably because HMD requires each user to register.

| File | What it is | SHA-1 |
|---|---|---|
| `lt_both.zip` | **Period** life tables, both sexes, every HMD country (`bltper_1x1/bltper_1x1.txt` is used) | `cbf25331…` |
| `population.zip` | Population on 1 January by single age, every HMD country (`Population/Population.txt` is used) | `af7c0224…` |

France = `PopName == "FRATNP"` (total population; `FRACNP` is the civilian population).
`scripts/08_hmd_france.do` unzips to a scratch folder, filters FRATNP and deletes the
scratch folder. The zips themselves are never edited.

**Period, not cohort.** The package readme asks for *cohort* life tables, but Figure 5
can only come from *period* tables (see `notes/paper_notes.md`, D15). A cohort download
(`c_lt_both.zip`) was tried first and rejected.
