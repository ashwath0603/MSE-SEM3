# MSE-SEM3 — Coursework, Madras School of Economics

Author: Ashwath Balasubramanian

Created: August 2026

Purpose: Analysis code for Semester 3 coursework. Each assignment is a **self-contained,
frozen unit** — its own data, scripts, output and writeup — so any problem set stays
re-runnable months after it was submitted.

Structure adapted from the `veeraa_trustlayer` cycle pattern: swap the month-cycle for a
course-cycle, add a `writeup/` for the submitted document.

## Layout

```
MSE-SEM3/
├── lib/                        shared helpers, used across ALL courses
│   ├── r_utils.R
│   └── stata_utils.do
├── _template_unit/             copy this to start a new problem set
│   ├── data/raw/               read-only. NEVER edit. Not tracked by git.
│   ├── data/clean/             built by scripts. Tracked.
│   ├── output/                 tables + figures. Disposable, regenerable.
│   ├── scripts/                numbered, run in order
│   └── writeup/                the .qmd that becomes the submission
└── <course>/<unit>/            e.g. econometrics_ii/ps01_ols/
```

## Rules

1. **`data/raw/` is read-only.** Course datasets are given to us. Never modify in place —
   every transformation is a script writing to `data/clean/`.
2. **Scripts are numbered and run in order.** `00_run_all` reproduces everything from raw
   to final tables. If it doesn't run top-to-bottom on a fresh clone, it's broken.
3. **A submitted unit is frozen.** Once a problem set is handed in, its code and output are
   not amended. Start the next unit by copying `_template_unit/`, not by editing the old one.
4. **Shared logic goes in `lib/`.** If the same function is being pasted into a second unit,
   it belongs in `lib/` instead.
5. **Outputs are never hand-edited.** If a number in the writeup is wrong, fix the script
   and re-run — don't patch the table.

## Running things

R:

```bash
Rscript scripts/01_clean.R
```

Stata (batch mode — writes `01_clean.log` beside the do-file):

```bash
stata -b do scripts/01_clean.do
```

The `stata` alias points at Stata SE 17's console binary and is defined in `~/.zshrc`.
Batch mode halts on the first error and writes the `r(###)` code to the log.

## Environment

| Tool | Version |
|---|---|
| R | 4.4.2 |
| Stata | SE 17 |
| Python | 3.14 |
