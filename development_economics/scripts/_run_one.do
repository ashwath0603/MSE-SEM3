* run a single step after 00_master's setup: stata -b do scripts/_run_one.do <step>
args step
capture confirm file "scripts/00_master.do"
if _rc cd ..
do "../lib/stata_utils.do"
global ROOT  "`c(pwd)'"
global RAW   "$ROOT/data/raw/119941-V1/Data"
global HMD   "$ROOT/data/raw/hmd"
global CLEAN "$ROOT/data/clean"
global TAB   "$ROOT/output/replication/tables"
global FIG   "$ROOT/output/replication/figures"
global AHAT  "5 40 50 80"
global GAMMA 1
global PLINE "1_9"
global SAMPLE "paper"
do scripts/`step'.do
