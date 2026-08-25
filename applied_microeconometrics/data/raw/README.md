# data/raw — READ ONLY

Source extracts go here **exactly as downloaded**. Never edit them. Contents are
git-ignored (large, and regenerable from the portals below); only this file and
`.gitkeep` are tracked.

Every correction happens in `scripts/01_build_panel.R`, so it is visible and re-runnable.

## What to download

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

Record each file as you add it:

| File | Source | Extract settings | Downloaded |
|---|---|---|---|
| | | | |
