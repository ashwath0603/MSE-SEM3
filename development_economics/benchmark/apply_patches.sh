#!/bin/zsh
# =============================================================================
# Rebuild benchmark/ from the authors' untouched package in data/raw/119941-V1.
# Copies their do-files and applies the minimal macOS patches listed in
# PATCHES.md. Nothing here changes what the code computes.
#
# Usage (from the unit root):   zsh benchmark/apply_patches.sh
# =============================================================================
set -euo pipefail

UNIT="${0:A:h:h}"                      # development_economics/
PKG="$UNIT/data/raw/119941-V1"
B="$UNIT/benchmark"

rm -rf "$B/Code" "$B/Data" "$B/Figures"
mkdir -p "$B/Code" "$B/Data/Temp" "$B/Data/CleanedData" "$B/Figures"
cp "$PKG"/Code/*.do "$B/Code/"

# Raw inputs are linked, not copied: the benchmark reads exactly the package files.
for d in GBD PovCalNet region; do ln -s "$PKG/Data/$d" "$B/Data/$d"; done

# HMD: the authors' code expects single-country files France_lt.txt and
# France_pop.txt with the header row first. We have the HMD bulk files (all
# countries, extra PopName column). Rebuild France-only files in that format.
# The PERIOD table is used: see notes/paper_notes.md (cohort tables cannot give Figure 5).
mkdir -p "$B/Data/HMD"
HMD="$UNIT/data/raw/hmd"
if [[ -f "$HMD/lt_both.zip" && -f "$HMD/population.zip" ]]; then
  unzip -p "$HMD/lt_both.zip"    bltper_1x1/bltper_1x1.txt  | awk 'NR==3 || $1=="FRATNP"' | sed -E 's/^[A-Z]+ +//; s/^PopName +//' > "$B/Data/HMD/France_lt.txt"
  unzip -p "$HMD/population.zip" Population/Population.txt  | awk 'NR==3 || $1=="FRATNP"' | sed -E 's/^[A-Z]+ +//; s/^PopName +//' > "$B/Data/HMD/France_pop.txt"
fi

cd "$B/Code"

# P1. Base path -> this folder
sed -i '' "s|^global Base .*|global Base    \"$B\"|" Master.do

# P2. run -> do, so every result the authors display is written to the log
sed -i '' 's|^run "|do "|' Master.do

# P3. Windows shell call -> POSIX
sed -i '' 's|!rmdir "\$dump"  /s /q|!rm -rf "$dump"|' MergingGBDandPovcalNet.do VariableConstruction.do HMD_VariableConstruction.do

# P4. Windows backslash path in the HMD import
sed -i '' 's|\$Base\\Data\\HMD/|$Base/Data/HMD/|g' HMD_VariableConstruction.do

# P5. br (Data Editor) is unavailable in batch mode -> list
sed -i '' 's|^br |list |' DescriptiveStats.do

# P6. HMD files are only run if they have been downloaded (Figure 5)
if [[ ! -f "$B/Data/HMD/France_lt.txt" ]]; then
  sed -i '' 's|^do "\$Base/Code/HMD_VariableConstruction.do"|* [P6 skipped: no HMD data] &|' Master.do
  # Comment out the Figure 5 block (from its header to the next section banner)
  awk '/^\*Figure 5: France/{skip=1} /^\t\t\t\t\t\t\t\*Section 3.2/{skip=0} {print (skip ? "* [P6] " $0 : $0)}' \
      DescriptiveStats.do > tmp && mv tmp DescriptiveStats.do
fi

echo "benchmark rebuilt; patched lines:"; diff -r "$PKG/Code" "$B/Code" | grep -c "^>" || true
