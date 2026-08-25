# =============================================================================
# Title:    G3 — Build the long-format country-year panel
# Author:   Ashwath Balasubramanian
# Created:  2026-08-25
# Purpose:  Read raw GHED + WDI extracts, reshape wide->long, join on ISO3,
#           derive analysis variables, and write the graded deliverable
#           data/G3.dta.
# Run:      Rscript scripts/01_build_panel.R      (from the unit root)
# =============================================================================
suppressMessages({
  library(dplyr); library(tidyr); library(readr); library(stringr); library(haven)
})

source(file.path("..", "lib", "r_utils.R"))

# ---- config (single source of truth) ----------------------------------------
# CONFIRM BEFORE BUILDING: see README "Design decisions".
YEAR_MIN   <- 2010          # T = 13 with YEAR_MAX 2022
YEAR_MAX   <- 2022
BASE_YEAR  <- 2010          # year at which the time-invariant income group is fixed
DEP_VAR    <- "che_pc_ppp"  # total current health expenditure p.c., PPP int$

RAW  <- file.path("data", "raw")
OUT  <- file.path("data", "G3.dta")

# ---- load -------------------------------------------------------------------
# INSTRUCTIONS: place the source extracts in data/raw/ before running.
#   GHED : https://apps.who.int/nha/database  -> export all indicators, all years
#   WDI  : https://databank.worldbank.org/source/world-development-indicators
# Record what you downloaded and when in data/raw/README.md.

stop_if_missing <- function(f) {
  if (!file.exists(f)) {
    stop("Missing raw file: ", f,
         "\nDownload it into data/raw/ (see data/raw/README.md) and re-run.",
         call. = FALSE)
  }
}

# ghed_raw <- read_csv(file.path(RAW, "ghed.csv"), show_col_types = FALSE)
# wdi_raw  <- read_csv(file.path(RAW, "wdi.csv"),  show_col_types = FALSE)

# ---- reshape to long --------------------------------------------------------
# WDI arrives wide: one column per year, named e.g. "2010 [YR2010]".
# to_long() normalises that into iso3 / year / <indicator> triples.
to_long <- function(df, value_name) {
  df |>
    pivot_longer(
      cols      = matches("^\\d{4}"),
      names_to  = "year",
      values_to = value_name
    ) |>
    mutate(
      year = as.integer(str_extract(year, "\\d{4}")),
      !!value_name := suppressWarnings(as.numeric(.data[[value_name]]))
    )
}

# ---- assemble ---------------------------------------------------------------
# panel <- ghed_long |>
#   inner_join(wdi_long, by = c("iso3", "year")) |>
#   filter(year >= YEAR_MIN, year <= YEAR_MAX)

# ---- derive -----------------------------------------------------------------
# Logs for the expenditure and income variables (elasticity interpretation),
# and the time-invariant income group fixed at BASE_YEAR.
#
# panel <- panel |>
#   mutate(
#     l_che   = log(che_pc_ppp),
#     l_gdp   = log(gdp_pc_ppp),
#     l_tb    = log(tb_incidence)
#   ) |>
#   group_by(iso3) |>
#   mutate(inc_group = first(income_group[year == BASE_YEAR])) |>   # TIME-INVARIANT
#   ungroup()

# ---- label ------------------------------------------------------------------
# Stata carries variable labels through from haven; label here so xtsum and
# outreg2 tables read properly without relabelling in the do-file.
#
# labs <- c(
#   l_che     = "Log total health expenditure p.c. (PPP int$)",
#   l_gdp     = "Log GDP per capita (PPP int$)",
#   gge_gdp   = "General government expenditure (% of GDP)",
#   over60    = "Population aged 60+ (% of total)",
#   l_tb      = "Log TB incidence (per 100,000)",
#   inc_group = "World Bank income group (fixed at base year)"
# )
# for (v in names(labs)) attr(panel[[v]], "label") <- labs[[v]]

# ---- export -----------------------------------------------------------------
# dir.create("data", showWarnings = FALSE)
# write_dta(panel, OUT)
# message("wrote ", OUT, " — ", nrow(panel), " rows, ",
#         n_distinct(panel$iso3), " countries, ",
#         n_distinct(panel$year), " years")

message("01_build_panel.R is a scaffold — uncomment once raw extracts are in data/raw/.")
