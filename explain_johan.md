# explain_johan: what changed in Development Economics on 2026-10-15

Hi Johan. This note covers what changed in `development_economics/` while you were working on the
`johan` branch. **Your branch has not been merged yet**; we will do that together later.
Everything below is on `main`.

## 1. What was done today, in order

1. **Poverty data rebuilt from source.** Instead of only using the authors' PovCalNet extract,
   we rebuilt the $1.90/day poverty series ourselves from the World Bank's WDI archive (Dec 2019
   release, the same vintage the authors used).
   - Why: PovCalNet is retired, and its successor PIP blocks the 2011-PPP series.
   - How close: correlation 0.989 with the authors' series.
2. **Mortality data rebuilt from source.** GBD 2023 was downloaded from the IHME Results tool
   (deaths and population, every country, 1990-2017) to replace the authors' GBD 2017 extract.
   - GBD 2023 has no "1-4 years" group; we build it from "12-23 months" + "2-4 years".
   - Checked: the pieces add up to GBD's "<5", and deaths / rate equals GBD's population in
     every cell.
3. **Comparison runs**, so every difference can be traced to its source: poverty only, mortality
   only, and both.
4. **The folder was restructured** into two self-contained folders (section 2). The step scripts
   are now one do-file per folder.

The replication itself did not change: every table is still identical to the committed version,
the one your Windows re-run matched.

## 2. The new structure

```
development_economics/
├── replication_package/      the paper's analysis on the AUTHORS' data (the replication)
│   ├── data/                 119941-V1/ (openICPSR package, unchanged) + hmd/ ; README.md
│   ├── scripts/replication.do
│   └── output/               tables/, figures/
├── constructed/              the same analysis on data WE downloaded from the sources
│   ├── data/                 gbd2023/, wdi_archive_201912/, hmd/ ; README.md (sources + caveats)
│   ├── scripts/constructed.do, fetch_wdi_archive.py
│   └── output/               tables/, figures/, sensitivity_*/
├── benchmark/                authors' code patched for macOS (unchanged role: verification only)
├── notes/, assignment/       unchanged
└── README.md                 updated: layout, how to run, log
```

**Where the old files went:**

| Before | Now |
|---|---|
| `scripts/00_master.do` + `01`-`11`, `20` | `replication_package/scripts/replication.do`, steps 1-12 in the same order (step 12 = old `20_compare`) |
| `data/raw/119941-V1/` | `replication_package/data/119941-V1/` |
| `data/raw/hmd/` | `replication_package/data/hmd/` and `constructed/data/hmd/` (same files) |
| `data/clean/*.dta` | **gone from the repo.** Intermediate datasets now go to Stata's temp folder and are deleted at the end of each run |
| `output/replication/tables`, `figures` | `replication_package/output/tables`, `figures` |
| `data/raw/README.md` | `replication_package/data/README.md` and `constructed/data/README.md` |

## 3. How to run

```
cd development_economics/replication_package
stata -b do scripts/replication.do        (~1 min)
cd ../constructed
stata -b do scripts/constructed.do        (~1 min; run AFTER the replication)
```

- Each do-file also runs from the Do-file Editor, from its own folder or from `scripts/`.
- Run them as files, not pasted into the Command window: they use `///` line breaks.
- **Step 12 of `replication.do`** (the check against the authors' own code) runs only if
  `benchmark/` has been built. Otherwise it prints "skipped".
- **Switches:** `constructed.do` has two at the top, `POVERTY` and `MORTALITY`. The default uses
  our data for both. Setting one to `"package"` reruns with the authors' data for that input and
  writes to `constructed/output/sensitivity_*/`.

**Data are not in git** (only the READMEs are). After pulling, the `data/` folders will be empty
on your machine. Ask Ashwath for the files, or download them as each `data/README.md` describes.
Note that HMD and GBD both need a free login.

## 4. Headline results of the constructed data

- **Sample:** 108 countries instead of 113.
  - 7 lose poverty years: Bosnia, Moldova, Serbia, Montenegro, Liberia, Djibouti, Syria. The WDI
    archive has no national-accounts series to fill those years.
  - Venezuela enters (the authors' file stops in 2013).
  - Tuvalu enters (GBD 2017 did not have it).
- **World GD (â = 50):** 52.90% in 1990 and 17.22% in 2015, against the paper's 52.8% and 17.2%.
- **GBD 2023 revises deaths at ages 5-19 up by 22-29%,** mostly in poor Sub-Saharan countries.
  That raises the life-span share of GD by about a point.
- **Table 4's Gabon vs Morocco example breaks:** with our poverty data, Gabon's headcount is above
  Morocco's. The mortality-only run shows the cause is poverty, not GBD.
- **All caveats,** with a decomposition showing the 7 lost countries do not drive the World
  numbers, are in `development_economics/constructed/data/README.md`.

## 5. What this means for your branch

- **`main.tex` will lose its figures** when merged: its `\graphicspath` points to
  `development_economics/output/replication/figures/`. The new path is
  `development_economics/replication_package/output/figures/`. One line to change.
- **Your audit note** refers to `scripts/`, `data/clean/` and `data/raw/hmd/`. That is fine as a
  dated record, but those paths no longer exist.
- **Your README edit** (team members, group leader) touches only the top lines. The README
  changes on `main` are further down, so the merge should be clean.
- **Your findings still stand,** and the numbers they cite are unchanged: re-rank 4.92 / 4.34 vs
  our 4.39, median age at death, Botswana's end year, K6, the rounding note.
