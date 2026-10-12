# data/raw — READ ONLY

Source extracts go here **exactly as downloaded**. Never edit them. Contents are
git-ignored (large, and regenerable from the portals below); only this file and
`.gitkeep` are tracked.

Every correction happens in `scripts/01_build_panel.R`, so it is visible and re-runnable.

## How the extracts get here

```bash
Rscript scripts/00_fetch_raw.R          # writes every file below
Rscript scripts/00_fetch_raw.R --force  # re-download, ignoring what is cached
```

The fetch is scripted against the **World Bank API**, not the download portals, so a
fresh clone can restore `data/raw/` in one command. WHO GHED is the upstream source for
the `SH.XPD.*` expenditure series, which therefore arrive on the SHA 2011 basis through
the same endpoint — no separate GHED export is needed.

It pulls a deliberate **superset**: all countries, all years, and *both* the current- and
constant-price GDP series. The specification is still open (see the unit README), and the
fetch must not prejudge it. Windowing and variable selection belong to
`scripts/01_build_panel.R`.

## What gets downloaded

**WHO Global Health Expenditure Database (GHED)** — <https://apps.who.int/nha/database>
Export the full indicator set, all countries, all years. Variables of interest:

| Variable | Definition |
|---|---|
| `che_pc_ppp` | Current health expenditure per capita, PPP int$ |
| `gghed_pc_ppp` | Domestic general government health expenditure p.c., PPP int$ |
| `oops_pc_ppp` | Out-of-pocket expenditure p.c., PPP int$ |
| `ext_che` | External health expenditure as % of CHE |

Note GHED now reports on the **SHA 2011** basis. The reference paper predates this and
uses `the` / `gghe0`, which are **not** directly comparable to today's aggregates. This
redefinition is part of the intended departure from the paper.

**World Bank WDI** — <https://databank.worldbank.org/source/world-development-indicators>

| Series | Code |
|---|---|
| GDP per capita, PPP (constant int$) | `NY.GDP.PCAP.PP.KD` |
| Population aged 65+ (% of total) | `SP.POP.65UP.TO.ZS` |
| Incidence of tuberculosis (per 100,000) | `SH.TBS.INCD` |
| General government final consumption (% of GDP) | `NE.CON.GOVT.ZS` |

Income-group classification comes from the World Bank country metadata sheet included in
a WDI export. Fixed at the base year, it is the **time-invariant** regressor.

## Provenance log

Maintained automatically at [`_manifest.csv`](_manifest.csv) — written by
`00_fetch_raw.R` on every run, recording each indicator's row count, the API's
`lastupdated` stamp and the fetch timestamp. It is regenerated from what is actually on
disk, so it cannot drift out of step with the extracts the way a hand-kept table does.

Add a row here only for anything acquired **outside** the fetch script:

| File | Source | Extract settings | Downloaded |
|---|---|---|---|
| | | | |
