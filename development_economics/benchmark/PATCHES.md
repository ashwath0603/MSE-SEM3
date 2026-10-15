# Benchmark: the authors' own code, run once

This folder holds a **patched copy** of the authors' Stata code from the openICPSR package
(Baland, Cassan & Decerf 2021, E119941V1). We run it once on the original raw data. Its
output, `Data/CleanedData/PovertyMortalityWorld.dta`, is the **reference answer** that our
own pipeline (`../replication_package/scripts/replication.do`) is checked against (its step 12).

**Nothing in our results is produced by this code.** It only verifies them.

## Rebuild and run

```bash
zsh benchmark/apply_patches.sh                       # from the unit root: copy and patch
cd benchmark && stata -b do Code/Master.do           # writes benchmark/Master.log
```

`apply_patches.sh` deletes and rebuilds `Code/`, `Data/` and `Figures/` every time, so this
folder never drifts from the package. Raw inputs are **symlinked** into
`../replication_package/data/119941-V1`, not copied.

## Patches

All of these are needed only to run on macOS in batch mode. **None changes a computation.**

| # | File | Original | Patched | Why |
|---|---|---|---|---|
| P1 | `Master.do` | `global Base "C:/Users/gcassan/…"` | this folder | Authors' Windows path |
| P2 | `Master.do` | `run "…do"` | `do "…do"` | `run` hides output; we need every displayed number in the log |
| P3 | `MergingGBDandPovcalNet.do`, `VariableConstruction.do`, `HMD_VariableConstruction.do` | `!rmdir "$dump" /s /q` | `!rm -rf "$dump"` | Windows shell syntax |
| P4 | `HMD_VariableConstruction.do` | `"$Base\Data\HMD/…"` | `"$Base/Data/HMD/…"` | Backslash path separator |
| P5 | `DescriptiveStats.do` | `br …` | `list …` | The Data Editor is unavailable in batch mode |
| P6 | `Master.do`, `DescriptiveStats.do` | — | HMD step and Figure 5 block commented out | **Only while** the HMD zips in `replication_package/data/hmd/` are missing. Applied automatically and lifted on rebuild once the files exist |

## What the authors' code tells us

These findings are carried into `../notes/paper_notes.md` §3.

- **Table 4 typo (D1).** `DescriptiveStats.do` contains `di 1043+174 // 1271`, then
  `di 228/1271 // 17.9%`. The correct sum is 1217, which gives GD₁ = **18.7%** for Gabon.
- **Timing (D3).** The empirical GD uses `gd_ndeath * (age_line - age)`, i.e. â − a
  (deaths at the start of the year). Equation (3)'s â − (a+1) is used only in the theory
  and the Figure 4 Excel sheet.
- Table 3 and Table 4 are **hand-computed** from listed variables (`di` lines). They are
  not produced by the code.
