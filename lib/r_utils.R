# =============================================================================
# Title:    Shared R helpers for MSE-SEM3 coursework
# Author:   Ashwath Balasubramanian
# Created:  2026-08-25
# Purpose:  Path resolution + table/figure export used across every unit.
#           Nothing here has side effects on load.
# =============================================================================
suppressMessages({library(dplyr); library(readr); library(ggplot2)})

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a

# ---- paths ------------------------------------------------------------------
# Resolve the unit root (the folder holding data/ scripts/ output/) whether the
# script is run via Rscript from the unit dir, from the repo root, or in RStudio.
unit_root <- function() {
  wd <- getwd()
  for (p in c(wd, dirname(wd), dirname(dirname(wd)))) {
    if (dir.exists(file.path(p, "scripts")) && dir.exists(file.path(p, "data"))) return(p)
  }
  wd
}

path_raw    <- function(...) file.path(unit_root(), "data", "raw", ...)
path_clean  <- function(...) file.path(unit_root(), "data", "clean", ...)
path_out    <- function(...) file.path(unit_root(), "output", ...)

# ---- export -----------------------------------------------------------------
# Save a figure at consistent dimensions so every submission looks the same.
save_fig <- function(plot, name, width = 7, height = 4.5, dpi = 300) {
  dir.create(path_out(), showWarnings = FALSE, recursive = TRUE)
  f <- path_out(paste0(name, ".png"))
  ggsave(f, plot, width = width, height = height, dpi = dpi)
  message("wrote ", f)
  invisible(f)
}

save_table <- function(df, name) {
  dir.create(path_out(), showWarnings = FALSE, recursive = TRUE)
  f <- path_out(paste0(name, ".csv"))
  write_csv(df, f)
  message("wrote ", f)
  invisible(f)
}

# ---- stata bridge -----------------------------------------------------------
# Run a .do file in batch mode and return its log as a character vector.
# Errors in Stata surface as an R error rather than a silent bad exit code.
STATA_BIN <- "/Applications/Stata/StataSE.app/Contents/MacOS/stata-se"

run_stata <- function(do_file) {
  stopifnot(file.exists(do_file))
  if (!file.exists(STATA_BIN)) stop("Stata binary not found at ", STATA_BIN)
  system2(STATA_BIN, c("-b", "do", shQuote(do_file)), stdout = TRUE, stderr = TRUE)
  log_file <- sub("\\.do$", ".log", do_file)
  if (!file.exists(log_file)) stop("Stata produced no log for ", do_file)
  log <- readLines(log_file, warn = FALSE)
  # Batch mode writes r(###) on failure and stops.
  if (any(grepl("^r\\([0-9]+\\);", log))) {
    stop("Stata error in ", basename(do_file), ":\n",
         paste(tail(log, 20), collapse = "\n"))
  }
  invisible(log)
}
