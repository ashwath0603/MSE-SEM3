# =============================================================================
# Title:    G3 — Audit the panel against the assignment's graded constraints
# Author:   Ashwath Balasubramanian
# Created:  2026-08-25
# Purpose:  Fail loudly if data/G3.dta violates anything the assignment grades:
#             - N >= 50 cross-section entities
#             - N >> T
#             - >= 2 regressors both entity-variant AND time-variant
#             - >= 1 time-invariant regressor
#           Also reports balance and missingness, which Q5 and Q7 need.
# Run:      Rscript scripts/02_checks.R          (from the unit root)
# =============================================================================
suppressMessages({library(dplyr); library(haven); library(tidyr)})

PANEL <- file.path("data", "G3.dta")
ID    <- "iso3"
TIME  <- "year"

if (!file.exists(PANEL)) {
  stop("No panel at ", PANEL, " — run scripts/01_build_panel.R first.", call. = FALSE)
}

panel <- read_dta(PANEL)
fails <- character(0)
note  <- function(ok, msg) {
  cat(if (ok) "  PASS  " else "  FAIL  ", msg, "\n", sep = "")
  if (!ok) fails <<- c(fails, msg)
}

cat("\n=== Panel dimensions ===\n")
N <- n_distinct(panel[[ID]])
T <- n_distinct(panel[[TIME]])
cat("  N (entities) :", N, "\n")
cat("  T (periods)  :", T, "\n")
cat("  rows         :", nrow(panel), "  (balanced would be ", N * T, ")\n", sep = "")

cat("\n=== Graded constraints ===\n")
note(N >= 50, paste0("N >= 50            (N = ", N, ")"))
note(N > T,   paste0("N >> T             (N = ", N, ", T = ", T, ")"))

# ---- variation classification -----------------------------------------------
# A regressor is time-variant if it changes within at least one entity, and
# entity-variant if it differs across entities within a period. FE can only
# identify variables that are time-variant.
classify <- function(df, id, time) {
  vars <- setdiff(names(df), c(id, time))
  vars <- vars[vapply(df[vars], is.numeric, logical(1)) |
               vapply(df[vars], is.character, logical(1))]
  purrr_map <- lapply(vars, function(v) {
    within_sd <- df |>
      group_by(.data[[id]]) |>
      summarise(k = n_distinct(.data[[v]][!is.na(.data[[v]])]), .groups = "drop")
    tibble(
      variable      = v,
      time_variant  = any(within_sd$k > 1),
      entity_variant= n_distinct(df[[v]]) > 1
    )
  })
  bind_rows(purrr_map)
}

cls <- classify(panel, ID, TIME)

both <- cls |> filter(time_variant, entity_variant)
tinv <- cls |> filter(!time_variant, entity_variant)

note(nrow(both) >= 2,
     paste0("2+ entity- AND time-variant  (found ", nrow(both), ": ",
            paste(head(both$variable, 6), collapse = ", "), ")"))
note(nrow(tinv) >= 1,
     paste0("1+ time-invariant            (found ", nrow(tinv), ": ",
            paste(head(tinv$variable, 6), collapse = ", "), ")"))

cat("\n=== Variation by variable ===\n")
print(as.data.frame(cls), row.names = FALSE)

# ---- balance + missingness --------------------------------------------------
cat("\n=== Balance ===\n")
per_entity <- panel |> count(.data[[ID]], name = "periods")
cat("  entities with full T :", sum(per_entity$periods == T), "/", N, "\n")
cat("  min / max periods    :", min(per_entity$periods), "/", max(per_entity$periods), "\n")

cat("\n=== Missingness (%) ===\n")
miss <- panel |>
  summarise(across(everything(), ~ round(100 * mean(is.na(.)), 1))) |>
  pivot_longer(everything(), names_to = "variable", values_to = "pct_missing") |>
  arrange(desc(pct_missing))
print(as.data.frame(miss), row.names = FALSE)

# ---- verdict ----------------------------------------------------------------
cat("\n")
if (length(fails)) {
  stop("\n", length(fails), " constraint(s) violated:\n  - ",
       paste(fails, collapse = "\n  - "), "\n", call. = FALSE)
}
cat("All graded constraints satisfied.\n\n")
