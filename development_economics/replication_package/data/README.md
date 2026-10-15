# Replication data: what is here and where it came from

These are the source files `scripts/replication.do` reads, **exactly as obtained**. Nothing
here is ever edited; every transformation happens in the do-file, and its intermediate
datasets go to a temporary folder that is deleted at the end of the run.

## `119941-V1/`: the authors' replication package

Baland, J.-M., Cassan, G., & Decerf, B. (2021). *Replication data for: "Too Young to
Die"*. openICPSR, E119941V1. <https://doi.org/10.3886/E119941V1>

- **How obtained:** downloaded from openICPSR (free account) on **2026-10-11**, unzipped, and
  copied here unchanged (checked with `diff -rq` against the download). 49 MB.
- **What the do-file uses:**

| File | What it is | Authors' access date |
|---|---|---|
| `Data/GBD/IHME-GBD_2017_DATA-f89cefb0-1.csv` | GBD 2017 all-cause deaths, both sexes, every age group, every location, 1990-2017. Number and rate per 100,000, with upper and lower bounds | 2019 |
| `Data/PovCalNet/PovCalNet1_9_2019.csv` | PovCalNet "economies table" at $1.90/day (2011 PPP), request years 1981-2015 | 11 Dec 2019 |
| `Data/region/WB_class.xls` | World Bank country classification (regions) | not stated |
| `Figure 4/Figure_4_MortalityShocks.xlsx` | The authors' Excel simulation behind Figure 4. Used only in step 12, to check our simulation | not stated |

- **Also in the package, not used by the do-file:** the $3.20 and $5.50 PovCalNet files, the
  authors' Stata code (`Code/`), their figures, and `Data/HMD/Readme.txt` (instructions only).

These are vintage extracts. PovCalNet has since been retired, and later GBD rounds revise
1990-2017. Using these exact files is what makes a faithful replication possible. The
`../../constructed/` folder repeats the analysis on data downloaded fresh from the sources.

## `hmd/`: Human Mortality Database, France (Figure 5 only)

University of California, Berkeley, and Max Planck Institute for Demographic Research.
*Human Mortality Database*. <https://www.mortality.org>.

- **Why it is here although it is not in the package:** the package ships no HMD data, only
  a readme telling users to download it (HMD requires each user to register). We followed
  that instruction.
- **How obtained:** registered on mortality.org, then *Data > Download HMD data > All HMD
  countries*, the two bulk zips below. Downloaded on **2026-10-11**; the files are stamped
  "Last modified: 27 Aug 2026; Methods Protocol v6". The same two files are in
  `../../constructed/data/hmd/`.

| File | What it is | SHA-1 |
|---|---|---|
| `lt_both.zip` | **Period** life tables, both sexes, every HMD country (`bltper_1x1/bltper_1x1.txt` is used) | `cbf25331…` |
| `population.zip` | Population on 1 January by single age, every HMD country (`Population/Population.txt` is used) | `af7c0224…` |

- France is `PopName == "FRATNP"` (total population; `FRACNP` is the civilian population).
  Step 8 unzips to the temporary folder and keeps France only.
- **Period, not cohort.** The package readme asks for *cohort* life tables, but Figure 5 can
  only come from *period* tables: cohort tables stop at the 1933 cohort and date the WWI
  deaths of 20-year-olds to their birth year, not to 1914-18. A cohort download was tried
  first and rejected.
