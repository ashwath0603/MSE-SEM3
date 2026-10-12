# =============================================================================
# Title:    G3 — Fetch raw source extracts from the World Bank API
# Author:   Ashwath Balasubramanian
# Created:  2026-08-25
# Purpose:  Pull every indicator the analysis might use into data/raw/, so the
#           panel build is reproducible on a fresh clone instead of depending on
#           hand-exported portal downloads.
#
#           Deliberately fetches a SUPERSET — all countries, all years, and both
#           the current- and constant-price GDP series. The specification is not
#           settled yet (see README "Design decisions"), and this script must not
#           prejudge it. Windowing, variable choice and price basis are all
#           01_build_panel.R's job.
#
#           WHO GHED is the upstream source for the SH.XPD.* series, so the
#           expenditure data arrives on the SHA 2011 basis via the same API.
#
# Run:      Rscript scripts/00_fetch_raw.R              (from the unit root)
#           Rscript scripts/00_fetch_raw.R --force      (re-download everything)
# =============================================================================
suppressMessages({
  library(dplyr); library(readr); library(jsonlite); library(purrr)
})

source(file.path("..", "lib", "r_utils.R"))

FORCE <- "--force" %in% commandArgs(trailingOnly = TRUE)
API   <- "https://api.worldbank.org/v2"

# ---- what to pull -----------------------------------------------------------
# Superset. Nothing here commits the analysis to a specification.
INDICATORS <- tribble(
  ~code,                ~role,
  # --- candidate dependent variables (WHO GHED, SHA 2011) ---
  "SH.XPD.CHEX.PP.CD",  "dep: current health expenditure p.c., PPP",
  "SH.XPD.GHED.PP.CD",  "dep: government health expenditure p.c., PPP",
  "SH.XPD.OOPC.PP.CD",  "dep: out-of-pocket expenditure p.c., PPP",
  # --- income, both price bases so the choice stays open ---
  "NY.GDP.PCAP.PP.CD",  "reg: GDP p.c., PPP, CURRENT int$",
  "NY.GDP.PCAP.PP.KD",  "reg: GDP p.c., PPP, CONSTANT 2021 int$",
  # --- remaining regressors ---
  "SP.POP.65UP.TO.ZS",  "reg: population 65+ (% of total)",
  # Population is not a regressor. Xu et al. (2011) restricted their sample to
  # "countries with population greater than 300,000"; this series is fetched
  # only so 01_build_panel.R can apply the same sample rule.
  "SP.POP.TOTL",        "aux: total population (sample filter, > 300,000)",
  "SH.TBS.INCD",        "reg: TB incidence per 100,000",
  "NE.CON.GOVT.ZS",     "reg: govt final consumption (% of GDP)",
  # NCD mortality is the NEW variable relative to the reference paper. Xu et al.
  # (2011) state they wanted a non-communicable disease measure but that "the
  # time series data for other infectious diseases and non-communicable diseases
  # is not available". It is now, 2010-2021, for 228 countries.
  "SH.DYN.NCOM.ZS",     "reg: NCD mortality, ages 30-70 (%) [NEW vs paper]",
  # --- deflator, kept in case expenditure is rebased to constant prices ---
  "NY.GDP.DEFL.ZS",     "aux: GDP deflator (index)"
)

# ---- fetch helpers ----------------------------------------------------------
# The API paginates. Ask for a large page and walk until the reported page count
# is exhausted. Retries cover transient 5xx / timeouts, which the portal does
# throw under load.
wb_get <- function(url, tries = 3) {
  for (i in seq_len(tries)) {
    out <- tryCatch(jsonlite::fromJSON(url, flatten = TRUE), error = function(e) e)
    if (!inherits(out, "error")) return(out)
    if (i == tries) stop("API failed after ", tries, " tries: ", url,
                         "\n  ", conditionMessage(out), call. = FALSE)
    Sys.sleep(2 * i)
  }
}

wb_indicator <- function(code) {
  first <- wb_get(sprintf("%s/country/all/indicator/%s?format=json&per_page=20000&page=1",
                          API, code))
  meta  <- first[[1]]
  if (is.null(meta$pages)) stop("Unexpected API response for ", code, call. = FALSE)

  pages <- purrr::map(seq_len(meta$pages), function(p) {
    if (p == 1) return(first[[2]])
    wb_get(sprintf("%s/country/all/indicator/%s?format=json&per_page=20000&page=%d",
                   API, code, p))[[2]]
  })

  df <- bind_rows(pages) |>
    transmute(
      iso3       = .data$countryiso3code,
      country    = .data$country.value,
      year       = as.integer(.data$date),
      value      = as.numeric(.data$value),
      indicator  = code
    ) |>
    # Blank iso3 marks the API's aggregate rows (world, regions, income groups).
    # Dropping them here is a source-fidelity fix, not an analytical choice.
    filter(!is.na(.data$iso3), .data$iso3 != "") |>
    arrange(.data$iso3, .data$year)

  list(data = df, last_updated = meta$lastupdated %||% NA_character_)
}

# Country metadata: region + income group, one row per economy. This is the
# CURRENT classification. Fixing income group at a base year instead needs the
# WB OGHIST spreadsheet, which the API does not expose — noted in the manifest.
wb_countries <- function() {
  res <- wb_get(sprintf("%s/country?format=json&per_page=400", API))
  res[[2]] |>
    transmute(
      iso3         = .data$id,
      country      = .data$name,
      region       = .data$region.value,
      region_id    = .data$region.id,
      income_group = .data$incomeLevel.value,
      lending_type = .data$lendingType.value,
      capital      = .data$capitalCity
    ) |>
    # region_id "NA" flags aggregates rather than real economies.
    filter(.data$region_id != "NA") |>
    arrange(.data$iso3)
}

# ---- run --------------------------------------------------------------------
raw_dir <- path_raw()
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)

message("Fetching into ", raw_dir, if (FORCE) "  [--force]" else "")

manifest <- purrr::pmap(INDICATORS, function(code, role) {
  f <- file.path(raw_dir, paste0("wdi_", code, ".csv"))

  if (file.exists(f) && !FORCE) {
    n <- nrow(read_csv(f, show_col_types = FALSE))
    message(sprintf("  skip     %-20s %6d rows  (exists; --force to refresh)", code, n))
    return(tibble(indicator = code, role = role, rows = n,
                  last_updated = NA_character_, fetched = NA_character_,
                  file = basename(f)))
  }

  got <- wb_indicator(code)
  write_csv(got$data, f)
  message(sprintf("  fetched  %-20s %6d rows  %d countries  %s",
                  code, nrow(got$data), n_distinct(got$data$iso3),
                  paste0(range(got$data$year), collapse = "-")))

  tibble(indicator = code, role = role, rows = nrow(got$data),
         last_updated = got$last_updated,
         fetched = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
         file = basename(f))
}) |> bind_rows()

# ---- country metadata -------------------------------------------------------
cf <- file.path(raw_dir, "wb_countries.csv")
if (!file.exists(cf) || FORCE) {
  ctry <- wb_countries()
  write_csv(ctry, cf)
  message(sprintf("  fetched  %-20s %6d economies", "wb_countries", nrow(ctry)))
  manifest <- bind_rows(manifest, tibble(
    indicator = "wb_countries", role = "meta: region + CURRENT income group",
    rows = nrow(ctry), last_updated = NA_character_,
    fetched = format(Sys.time(), "%Y-%m-%d %H:%M:%S"), file = basename(cf)
  ))
} else {
  message("  skip     wb_countries          (exists; --force to refresh)")
}

# ---- provenance -------------------------------------------------------------
# data/raw/README.md asks for a provenance log. Write it as a machine-readable
# manifest so it cannot drift out of step with what is actually on disk.
mf <- file.path(raw_dir, "_manifest.csv")
write_csv(manifest, mf)

message("\nSource: World Bank API (", API, ")")
message("        SH.XPD.* originate from WHO GHED on the SHA 2011 basis.")
message("wrote   ", mf)
message("\nRaw extracts are git-ignored by design. Re-run this script to restore them.")
