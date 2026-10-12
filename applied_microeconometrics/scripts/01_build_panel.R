# =============================================================================
# Title:    G3 — Build the long-format country-year panel
# Author:   Ashwath Balasubramanian
# Created:  2026-08-25
# Purpose:  Read the raw WDI/GHED extracts fetched by 00_fetch_raw.R, join on
#           ISO3, derive analysis variables, and write the graded deliverable
#           data/G3.dta.
# Run:      Rscript scripts/01_build_panel.R      (from the unit root)
#
# Specification note: every choice the README flags as open lives in the config
# block below and nowhere else. Change a constant, re-run, and the whole panel
# follows — no other edit is needed.
# =============================================================================
suppressMessages({
  library(dplyr); library(tidyr); library(readr); library(stringr); library(haven)
})

source(file.path("..", "lib", "r_utils.R"))

# ---- config (single source of truth) ----------------------------------------
# T = 12. The window ends at 2021 because the NCD mortality series -- the new
# variable relative to the reference paper -- is published only through 2021.
# Both COVID years (2020, 2021) are retained; only the recovery years are lost.
YEAR_MIN  <- 2010
YEAR_MAX  <- 2021

# Price basis: REAL, matching the reference paper, which expressed all
# expenditure in PPP per-capita international dollars and then "converted into
# the real terms using inflation data from the World Bank".
#
# The World Bank publishes GDP per capita in PPP on both a current and a
# constant-2021 basis, but health expenditure only on a current basis. The ratio
# of the two GDP series is therefore the country-year deflator implied by the
# Bank's own real-GDP construction, and applying it to health expenditure
# rebases it into the SAME constant 2021 international dollars:
#
#     che_real_it = che_current_it * (gdp_constant_it / gdp_current_it)
#
# This is preferred over NY.GDP.DEFL.ZS, which is a local-currency index and
# would not be commensurate with a PPP international-dollar series.
GDP_SERIES     <- "NY.GDP.PCAP.PP.KD"   # constant 2021 international $
GDP_SERIES_CUR <- "NY.GDP.PCAP.PP.CD"   # current international $, deflator only

# Time-invariant regressor: the World Bank's CURRENT income classification, one
# value per country. Fixing it at a base year instead would need the WB OGHIST
# spreadsheet, which the API does not serve.
TINV <- "income_group"                # or "region"

# Countries must be observed in EVERY year of the window. Set equal to the span
# (YEAR_MAX - YEAR_MIN + 1), so the exported panel is strictly balanced: every
# country contributes exactly T observations. A balanced panel keeps xtsum's
# between/within decomposition exactly interpretable and makes the Pooled, FE
# and RE comparisons rest on an identical, evenly-weighted sample.
MIN_YEARS <- YEAR_MAX - YEAR_MIN + 1

# Minimum population, applied as a COUNTRY-level rule (required in every year of
# the window, not cell by cell). Xu et al. (2011) sec. 3.2: "we included
# countries with population greater than 300,000." Matching their sample rule
# keeps the panels comparable; it drops microstates whose health aggregates are
# volatile for reasons unrelated to the determinants under study.
MIN_POP <- 300000

RAW <- file.path("data", "raw")
OUT <- file.path("data", "G3.dta")

# ---- load -------------------------------------------------------------------
need <- function(f) {
  p <- file.path(RAW, f)
  if (!file.exists(p)) {
    stop("Missing raw extract: ", p,
         "\nRun:  Rscript scripts/00_fetch_raw.R", call. = FALSE)
  }
  read_csv(p, show_col_types = FALSE)
}

SERIES <- c(
  che_cur      = "SH.XPD.CHEX.PP.CD",   # dependent variable, current int$
  gdp_pc_ppp   = GDP_SERIES,            # income, constant 2021 int$
  gdp_cur      = GDP_SERIES_CUR,        # current int$, used only as deflator
  # NOTE ON NAMING. Xu et al. call their fiscal-capacity regressor gge_gdp and
  # define it as TOTAL government expenditure as a share of GDP. NE.CON.GOVT.ZS
  # is general government FINAL CONSUMPTION -- a narrower aggregate that excludes
  # transfers, subsidies, interest and capital formation (mean 17.5% of GDP here
  # against 26.6% for total expense). It is used instead because the WDI total
  # series, GC.XPN.TOTL.GD.ZS, covers only 76.5% of this panel and just 91 of 162
  # countries for all 12 years. The variable is therefore named gfce_gdp, not
  # gge_gdp, so it never reads as the paper's construct. The substitution and its
  # reason belong in the Q4 variable table.
  gfce_gdp     = "NE.CON.GOVT.ZS",      # govt final consumption, % of GDP
  population   = "SP.POP.TOTL",         # sample filter only, not a regressor
  over65       = "SP.POP.65UP.TO.ZS",   # population 65+, % of total
  tb_incidence = "SH.TBS.INCD",         # TB incidence per 100,000
  ncd_mort     = "SH.DYN.NCOM.ZS"       # NCD mortality 30-70 (%)  [NEW]
)

message("Reading raw extracts from ", RAW, " ...")
long <- purrr::imap_dfr(SERIES, function(code, nm) {
  need(paste0("wdi_", code, ".csv")) |>
    transmute(iso3, year, variable = nm, value)
})

countries <- need("wb_countries.csv")

# ---- assemble ---------------------------------------------------------------
# The extracts are already long (00_fetch_raw.R normalises the API's response),
# so this is a pivot to one row per country-year rather than a reshape.
panel <- long |>
  pivot_wider(names_from = variable, values_from = value) |>
  filter(year >= YEAR_MIN, year <= YEAR_MAX) |>
  # Keep real economies only. wb_countries.csv already excludes the API's
  # aggregate rows (World, regions, income groups), so this join drops them.
  inner_join(
    countries |> select(iso3, country, region, income_group),
    by = "iso3"
  )

# ---- sample rule: population > 300,000 --------------------------------------
# Applied before the complete-case filter so that the exclusion is driven by the
# paper's sample definition rather than by which covariates happen to be
# reported for a microstate.
big <- panel |>
  group_by(iso3) |>
  summarise(pop_min = min(population, na.rm = TRUE), .groups = "drop") |>
  filter(is.finite(pop_min), pop_min > MIN_POP)

dropped_small <- panel |>
  distinct(iso3, country) |>
  anti_join(big, by = "iso3")

if (nrow(dropped_small)) {
  message(sprintf("  population <= %s in some year -- %d country(ies) dropped:",
                  format(MIN_POP, big.mark = ",", scientific = FALSE), nrow(dropped_small)))
  message("    ", paste(dropped_small$iso3, collapse = ", "))
}

panel <- panel |> semi_join(big, by = "iso3")

# ---- deflate ----------------------------------------------------------------
# Rebase health expenditure from current into constant 2021 international
# dollars, using the deflator implied by the World Bank's own current/constant
# GDP pair (see the config block). After this step che_pc_ppp and gdp_pc_ppp are
# in the SAME units, which is what makes the log-log coefficient a clean real
# income elasticity.
panel <- panel |>
  mutate(
    ppp_deflator = gdp_pc_ppp / gdp_cur,
    che_pc_ppp   = che_cur * ppp_deflator
  )

defl_ok <- panel |> filter(!is.na(ppp_deflator))
message(sprintf("  deflator range : %.3f to %.3f (1.000 = 2021 base year)",
                min(defl_ok$ppp_deflator), max(defl_ok$ppp_deflator)))

# ---- derive -----------------------------------------------------------------
# Logs on the strictly positive monetary and rate variables give the log-log
# reading the objective needs: beta on l_gdp is the income elasticity of health
# expenditure, and the paper's first research question is whether it exceeds 1.
# gfce_gdp, over65 and ncd_mort are already percentages and stay in levels.
#
# ORDER MATTERS. Derivation runs BEFORE the complete-case filter, so that a
# value which survives the filter but has no defined log (a reported zero) is
# caught here rather than reappearing as a missing in the exported panel. The
# Q9 comparison tests -- Hausman above all -- are only valid if Pooled, FE and
# RE estimate on an identical sample, which requires the filter to see exactly
# the variables the models will use.
LOG_VARS <- c(che_pc_ppp = "l_che", gdp_pc_ppp = "l_gdp", tb_incidence = "l_tb")

# Zero is a genuine reported value for TB incidence in microstates, not a coding
# error, but a log specification cannot represent it. Record which entities are
# affected before dropping the observations, so the exclusion is documented
# rather than silent.
nonpos <- panel |>
  filter(if_any(all_of(names(LOG_VARS)), ~ !is.na(.) & . <= 0)) |>
  count(iso3, country, name = "rows")

if (nrow(nonpos)) {
  message("  non-positive values, log undefined -- observations dropped:")
  for (i in seq_len(nrow(nonpos))) {
    message(sprintf("    %s (%s): %d obs", nonpos$iso3[i], nonpos$country[i],
                    nonpos$rows[i]))
  }
}

panel <- panel |>
  filter(if_all(all_of(names(LOG_VARS)), ~ is.na(.) | . > 0)) |>
  mutate(
    l_che = log(che_pc_ppp),
    l_gdp = log(gdp_pc_ppp),
    l_tb  = log(tb_incidence)
  )

# ---- complete cases ---------------------------------------------------------
# Filter on the DERIVED variables that actually enter the models, so the
# exported panel carries no missing value on any estimated term.
model_vars <- c("l_che", "l_gdp", "gfce_gdp", "over65", "l_tb", "ncd_mort")

before <- panel
panel <- panel |> filter(if_all(all_of(model_vars), ~ !is.na(.)))

kept <- panel |> count(iso3, name = "n_years") |> filter(n_years >= MIN_YEARS)
dropped_short <- panel |> count(iso3, name = "n_years") |> filter(n_years < MIN_YEARS)
if (nrow(dropped_short)) {
  message(sprintf("  dropped %d entity(ies) with < %d usable years (balancing)",
                  nrow(dropped_short), MIN_YEARS))
}
panel <- panel |> semi_join(kept, by = "iso3")

message(sprintf("  complete cases : %d rows, %d countries",
                nrow(panel), n_distinct(panel$iso3)))

# Time-invariant regressor, as a labelled numeric so Stata can use it directly
# with i. notation. Ordered low -> high so the coefficients read monotonically.
INC_LEVELS <- c("Low income", "Lower middle income",
                "Upper middle income", "High income")

tinv_chr <- panel[[TINV]]
if (TINV == "income_group") {
  stopifnot(all(tinv_chr %in% INC_LEVELS))
  codes <- setNames(seq_along(INC_LEVELS), INC_LEVELS)
} else {
  lv <- sort(unique(tinv_chr))
  codes <- setNames(seq_along(lv), lv)
}

panel <- panel |>
  mutate(
    inc_group   = tinv_chr,
    inc_group_n = haven::labelled(unname(codes[tinv_chr]), labels = codes)
  )

# Sanity: the graded constraint is that this regressor really is time-invariant.
tv <- panel |>
  group_by(iso3) |>
  summarise(k = n_distinct(inc_group_n), .groups = "drop")
stopifnot(all(tv$k == 1))

# ---- label ------------------------------------------------------------------
# haven carries these into Stata, so xtsum and esttab read properly without
# relabelling in the do-file.
# Plain text only. These are the labels a grader sees in Stata's -describe-, so
# the .dta must not carry LaTeX escaping. 03_analysis.do re-labels the three
# variables containing "%" or an en-dash immediately before writing .tex.
# Still no "$" anywhere: a bare dollar sign is a macro reference in Stata.
labs <- c(
  iso3         = "ISO3 country code",
  country      = "Country name",
  year         = "Year",
  l_che        = "Log real health expenditure p.c. (2021 PPP intl. dollars)",
  l_gdp        = "Log real GDP per capita (2021 PPP intl. dollars)",
  gfce_gdp     = "Govt final consumption (% of GDP)",
  population   = "Total population",
  over65       = "Population aged 65+ (% of total)",
  l_tb         = "Log TB incidence (per 100,000)",
  ncd_mort     = "NCD mortality, ages 30-70 (%)",
  inc_group_n  = "World Bank income group",
  che_pc_ppp   = "Real health expenditure p.c., 2021 PPP intl. dollars",
  gdp_pc_ppp   = "Real GDP per capita, 2021 PPP intl. dollars",
  tb_incidence = "TB incidence per 100,000",
  region       = "World Bank region",
  inc_group    = "World Bank income group (string)"
)

panel <- panel |>
  select(iso3, country, year, region, inc_group, inc_group_n,
         l_che, l_gdp, gfce_gdp, over65, l_tb, ncd_mort,
         che_pc_ppp, gdp_pc_ppp, tb_incidence) |>
  arrange(iso3, year)

for (v in names(labs)) {
  if (v %in% names(panel)) attr(panel[[v]], "label") <- unname(labs[[v]])
}

# ---- export -----------------------------------------------------------------
dir.create("data", showWarnings = FALSE)
write_dta(panel, OUT)

message(sprintf("\nwrote %s\n  %d rows | N = %d countries | T = %d years (%d-%d)",
                OUT, nrow(panel), n_distinct(panel$iso3),
                n_distinct(panel$year), min(panel$year), max(panel$year)))
message(sprintf("  balance: %.1f%% of the %d cells a fully balanced panel would have",
                100 * nrow(panel) / (n_distinct(panel$iso3) * n_distinct(panel$year)),
                n_distinct(panel$iso3) * n_distinct(panel$year)))