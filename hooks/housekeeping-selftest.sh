#!/usr/bin/env bash
# Self-test for housekeeping-reask.sh (the /housekeeping step-2 surfacer) and for the stamp-parse guard in the
# lane's own hooks. Expected: 55 passed / 0 failed / 55 expected, exit 0.
#
# Runs the INSTALLED matcher (a test against a copy passes while the shipped bytes drift) against a fixture tracker,
# then a NEGATIVE CONTROL: a naive "ISO date on a line containing re-ask" matcher must score DIFFERENTLY on the same
# fixtures, or the fixtures never reached the logic under test. Each fixture heading states the shape it covers and
# the verdict it must produce.
#
# Usage: HOOKS_DIR=<lane hooks dir> housekeeping-selftest.sh [path-to-housekeeping-reask.sh]
# Exit 0 = all pass and the count is complete; 1 = failures listed.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
MATCHER="${1:-$HERE/housekeeping-reask.sh}"
[ -x "$MATCHER" ] || { echo "FAIL exec-bit: $MATCHER is not executable (a file written by git show > is 0644)"; exit 1; }
TODAY=2031-09-05
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
F="$T/ISSUES.md"
cat > "$F" <<'EOF'
# Fixture Issues

Re-checks use a TRIGGER where the gate is observable and a DATE where the gate is a person. re-ask 2031-09-01 in the header is boilerplate.

## Open

### ASKS PENDING — ask block, not an entry
- **IF SILENT:** stays ESCALATED, re-ask **2031-09-01**.

### #01 — wrapped live date on the disposition line
- **Type:** Chore
- **Disposition:** **ESCALATED** — the operator, for the key custody. · **re-ask
  2031-09-07 (a Sunday)** — re-dated by the operator on 04.09.

### #02 — plain, passed
- **Disposition:** **ESCALATED** — the operator. · re-ask 2031-09-04.

### #03 — one connective, passed
- **Disposition:** **ACCEPTED** — re-check by 2031-09-04.

### #04 — capital R, passed
- **Disposition:** ESCALATED to the operator. Re-ask 2031-09-05.

### #05 — prose beside a historical date: quiet
- **Disposition:** **TRACKED #05** · re-check trigger: the next release.
  which is a discharged re-ask and a new date, **not a rolled-forward one**. (Superseded — the prior
  date was 2031-09-04, deliberately written here without the trigger word.

### #06 — the live re-ask mentioned in prose with a backticked date: quiet
- **Disposition:** **ESCALATED** — the operator. · re-ask 2031-09-09.
- The **live** re-ask on the same issue, `2031-09-04`, is correctly not due.

### #07 — governed, future: quiet
- **Disposition:** **ESCALATED** — the operator. · re-ask 2031-09-09.

### #08 — THE DISCRIMINATOR: same historical date, trigger adjacent: fires
- **Disposition:** ESCALATED — which is a discharged item and a new date. · re-ask 2031-09-04.

### #09 — current disposition future, superseded one retained with a past date: quiet
- **Disposition:** **ESCALATED the operator** · re-ask 2031-09-12.
- **Superseded disposition, retained as history:** **ESCALATED the operator** · re-ask 2031-09-03.

### #10 — governed date OUTSIDE the disposition line: STRAY, not DUE
- **Disposition:** **TRACKED #10** · re-check trigger: the next sweep.
- The sibling entry's re-ask stays 2031-09-02 — the date moves on the operator's word only.

### #11 — trigger-gated, no date: TRIGGER
- **Disposition:** **ACCEPTED** — vendor behaviour · re-check trigger: when the fleet-audit expiry check alarms.

### #12 — prose bullet mentioning the word disposition is not a disposition line
- **Disposition:** **ESCALATED** — the operator · re-ask 2031-09-09.
- **Second ask — ANSWERED 04.09: the operator chose the SILENT disposition** (in their own words); prior re-ask 2031-09-03.

### #15 — live disposition whose PROSE says "replaced" (not its label): must still be the current one → TRIGGER
- **Disposition:** ACCEPTED — non-urgent · re-check: **that sweep**. The re-ask date of 2031-08-30 is retired, replaced by the sweep as the gate.

### #16 — disposition hard-wrapped over five lines, governed past date on the last: DUE once, never STRAY
- **Disposition:** ESCALATED — the operator, for the
  decision on the export allowlist, which this lane
  cannot read without credentials it does not hold
  and will not request on its own authority;
  re-ask 2031-09-03.

### #17 — undated PERSON-gated re-ask: must surface as TRIGGER, never nothing
- **Disposition:** ESCALATED — the operator; decide when they next open a root window. Re-ask at that window.

### #18 — gate worded "trigger:" with no date: TRIGGER
- **Disposition:** QUEUED — trigger: the next fleet backup sweep.

### #19 — date BEFORE the trigger word on a prose line: not STRAY (cannot become a DUE)
- **Disposition:** BLOCKED — the amendment pass has not run · re-check trigger: the PRD amendment pass.
- **One candidate is already resolved:** settled by the operator on 2031-08-22 — the sweep does not need to re-check them.

### #20 — current disposition with a PAST date AND a superseded line with a DIFFERENT past date: DUE reports the CURRENT date only
- **Disposition:** ESCALATED the operator · re-ask 2031-09-04.
- **Superseded disposition, retained as history:** ESCALATED the operator · re-ask 2031-09-01.

### #21 — a CONTINUATION line naming "the Disposition line above" with a colon later: must NOT become current → DUE on the real line
- **Disposition:** **ESCALATED** — the operator, because the perimeter is not ours. · re-ask 2031-08-31.
- **Second ask — ANSWERED 04.09:** the operator chose the silent disposition, so it rides with `#23`
  on the date carried by the Disposition line above; not restated here. Ownership settled: another lane's.

### #22 — control for #21: the word "Disposition" on the continuation replaced by "bullet"
- **Disposition:** **ESCALATED** — the operator, because the perimeter is not ours. · re-ask 2031-08-31.
- **Second ask — ANSWERED 04.09:** the operator chose the silent disposition, so it rides with `#23`
  on the date carried by the bullet line above; not restated here. Ownership settled: another lane's.

### #23 — late-colon prose bullet BELOW the disposition must not take over → DUE, not STRAY
- **Type:** Bug
- **Disposition:** **ESCALATED** the operator · re-ask 2031-09-02.
- **Why it aged.** What it lacked was a disposition: nobody set one, and the finding was correct.

### #25 — labels at column 0, NO bullet; passed re-ask on the disposition → DUE; the next bold line is not joined
**Type:** Chore
**Disposition:** ESCALATED — the operator · re-ask **2031-09-03**.
**Not claimed:** the perimeter was not probed; re-check 2031-08-29 was a different item and must not be joined.

### #26 — trigger-gated, unbulleted → TRIGGER
**Type:** Chore
**Disposition:** BLOCKED — no deploy pipeline exists yet · re-check **trigger: first deploy-pipeline work (phase 1)**.

### #27 — a bold-led paragraph whose label CONTAINS the word below the current disposition must not take over → TRIGGER
- **Disposition:** BLOCKED — the patch floor follows the vendor's release · re-check **trigger: the next PHP 8.5 release**.
- **Superseded disposition, retained as history (answered 2031-09-05):** ESCALATED the operator · re-ask 2031-09-09.

**Housekeeping reading, 2031-10-01 (not a disposition change):** the newest release is 8.5.11.

## Closed

### #24 — CLOSED entry, live passed re-ask on its real disposition, late-colon prose bullet below: still DUE
- **Type:** Bug
- **Disposition:** **ESCALATED** the operator + the pilot (shared host) · **re-ask 2031-09-02**.
- **Why it hid — and it did not hide; it aged.** The finding was correct. What it lacked was a disposition: it sat.

### #13 — closed, current disposition FIXED, superseded retained with a past date: quiet
- **Disposition:** FIXED in v1.2 · read back 2031-09-04.
- **Superseded disposition, retained as history:** ESCALATED the operator · re-ask 2031-09-03.

### #14 — closed entry with a LIVE passed re-ask on its current disposition: still reported (a finding)
- **Disposition:** ESCALATED the operator · re-ask 2031-09-04.

## Open

### #28 — a trigger + date inside the LABEL is not governed: STRAY, never DUE
- **Disposition (re-check 2031-09-04, quiet-week read):** ACCEPTED headers unchanged · re-check trigger: the first renewal.

### #29 — a status-led label naming Disposition, and no current disposition: STRAY, never silent
- **PARKED 2031-09-03 — Disposition: ACCEPTED** low exposure · re-check trigger: the vendor ships a fix.
EOF

pass=0; fail=0
out="$("$MATCHER" "$F" "$TODAY")"
expect() { # expect <KIND> <id> <present:1|0>
  local kind="$1" id="$2" want="$3" got=0
  printf '%s\n' "$out" | grep -q "^${kind}	${id}	" && got=1
  if [ "$got" = "$want" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL ${kind} ${id}: expected present=${want}, got=${got}"; fi
}
expect DUE '#01' 0         # wrapped live date is 09-07 > today: quiet today...
out7="$("$MATCHER" "$F" 2031-09-07)"; printf '%s\n' "$out7" | grep -q '^DUE	#01	2031-09-07' && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL #01 wrapped date must FIRE when today=2031-09-07"; }
expect DUE '#02' 1
expect DUE '#03' 1
expect DUE '#04' 1
expect DUE '#05' 0
expect DUE '#06' 0
expect STRAY '#06' 1       # trigger word + date on one prose line outside the disposition: hygiene flag
expect DUE '#07' 0
expect DUE '#08' 1
expect DUE '#09' 0
expect STRAY '#09' 0       # a superseded line is history, never stray
expect DUE '#10' 0
expect STRAY '#10' 1
expect TRIGGER '#11' 1
expect DUE '#12' 0
expect STRAY '#12' 1       # "prior re-ask 2031-09-03" outside the current disposition line: STRAY
expect TRIGGER '#15' 1
expect DUE '#16' 1
expect STRAY '#16' 0
expect TRIGGER '#17' 1
expect TRIGGER '#18' 1
expect STRAY '#19' 0
printf '%s\n' "$out" | grep -q '^DUE	#20	2031-09-04' && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL #20 must report the CURRENT date 2031-09-04"; }
printf '%s\n' "$out" | grep -q '^DUE	#20	2031-09-01' && { fail=$((fail+1)); echo "FAIL #20 reported the SUPERSEDED date"; } || pass=$((pass+1))
expect DUE '#21' 1
expect STRAY '#21' 0
expect DUE '#22' 1
expect DUE '#23' 1
expect STRAY '#23' 0
expect DUE '#24' 1
expect DUE '#25' 1
printf '%s\n' "$out" | grep -q '^DUE	#25	2031-08-29' && { fail=$((fail+1)); echo "FAIL #25 joined the next bold-led line into the disposition"; } || pass=$((pass+1))
expect STRAY '#25' 1       # the Not-claimed line carries re-check + date: hygiene flag, correct
expect TRIGGER '#26' 1
expect TRIGGER '#27' 1     # the 'not a disposition change' paragraph must not become the current disposition
expect DUE '#13' 0
expect DUE '#14' 1
expect DUE '#28' 0         # the label's date is description, not a governed re-check
expect STRAY '#28' 1       # ...and it is reported, so a re-ask written into a label never goes silent
expect STRAY '#29' 1       # a status-led disposition label is reported, the entry never vanishes
expect TRIGGER '#29' 0     # ...and is not read as a current disposition
printf '%s\n' "$out" | grep -q 'ASKS' && { fail=$((fail+1)); echo "FAIL ask block with no id was treated as an entry"; } || pass=$((pass+1))
printf '%s\n' "$out" | grep -q '2031-09-01' && { fail=$((fail+1)); echo "FAIL header boilerplate date surfaced"; } || pass=$((pass+1))

# NEGATIVE CONTROL: the naive matcher must disagree with the shipped one on these fixtures.
naive="$(grep -Ei 're-ask|re-check' "$F" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | awk -v t="$TODAY" '$1<=t' | wc -l)"
shipped="$(printf '%s\n' "$out" | grep -c '^DUE')"
if [ "$naive" -ne "$shipped" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL control: naive matcher ($naive) equals shipped ($shipped) — fixtures did not reach the logic under test"; fi

# STRUCTURAL: no script in the lane's hooks parses a stamp with an unguarded date -d.
# A GUARD is a SHAPE CHECK on the variable before the parse — `2>/dev/null` and an rc test guard nothing: GNU date
# returns rc 0 and a plausible epoch for "next monday" AND for an empty string. A parse is accepted only when (a) the
# line carries the marker `shape-guarded` (an auditable author declaration), or (b) the same file shape-checks that
# variable before use: `[[ "$V" =~ …`, `case "$V"`, or `V=$(… grep -[…]E …)` extraction. Flags before -d are
# tolerated; comment lines and this file are never code. Calibrated on planted cases first: A/B/F/G must hit,
# E/H/I/J/K must not.
unguarded_hits() {  # $1 = dir → lines with an unguarded stamp parse
  local f ln rest v ok
  grep -rnE 'date( +-[A-Za-z]+)* +-d +"?\$[A-Za-z_]+"?' "$1" 2>/dev/null \
    | grep -v 'housekeeping-selftest.sh:' | grep -vE '^[^:]*:[0-9]+:[[:space:]]*#' | grep -v 'shape-guarded' \
    | while IFS=: read -r f ln rest; do
        v="$(printf '%s' "$rest" | grep -oE -- '-d +"?\$[A-Za-z_]+' | head -1 | sed 's/.*\$//')"
        ok=0
        [ -n "$v" ] && grep -qE "\[\[ *\"?\\\$$v\"? *=~|case +\"?\\\$$v\"? +in|^[[:space:]]*$v=\"?\\\$\(.*grep +-[A-Za-z]*E" "$f" && ok=1
        [ "$ok" = 1 ] || printf '%s:%s:%s\n' "$f" "$ln" "$rest"
      done
}
CAL="$T/cal"; for c in A B E F G H I J; do mkdir -p "$CAL/$c"; done
printf 'E=$(date -u -d "$LAST" +%%s)\n' > "$CAL/A/n.sh"                                        # unguarded, -u: HIT
printf 'E=$(date -d "$LAST" +%%s)\n' > "$CAL/B/n.sh"                                           # unguarded: HIT
printf '# a comment mentioning date -d "$x" is not code\n' > "$CAL/E/n.sh"                      # comment: no hit
printf 'E=$(date -d "$LAST" +%%s 2>/dev/null)\n' > "$CAL/F/n.sh"                               # stderr only: HIT
printf 'E=$(date -u -d "$LAST" +%%s 2>/dev/null) || exit 2\n' > "$CAL/G/n.sh"                  # rc test only: HIT
printf '[[ "$LAST" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]] || exit 2\nE=$(date -u -d "$LAST" +%%s)\n' > "$CAL/H/n.sh"   # =~ shape check: no hit
printf 'LAST=$(grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z" "$f" | tail -1)\nE=$(date -d "$LAST" +%%s)\n' > "$CAL/I/n.sh"  # extraction: no hit
printf 'E=$(date -d "$LAST" +%%s)   # shape-guarded: LAST validated by the caller\n' > "$CAL/J/n.sh"   # declared: no hit
for c in A B F G; do [ -n "$(unguarded_hits "$CAL/$c")" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL structural-calibration $c: unguarded parse not detected"; }; done
mkdir -p "$CAL/K"; printf 'LAST="$(grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]+Z" "$f" | tail -1)"\nE=$(date -d "$LAST" +%%s)\n' > "$CAL/K/n.sh"  # quoted extraction: no hit
for c in E H I J K; do [ -z "$(unguarded_hits "$CAL/$c")" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL structural-calibration $c: guarded/comment line flagged"; }; done
# The only assertion in this suite that reads the LANE'S OWN files; the other 54 are planted fixtures. Unset or
# misspelled, HOOKS_DIR FAILS rather than skipping: "cannot look" is not "nothing to see", and a silent skip would
# print a count one short that reads exactly like a clean run.
if [ -z "${HOOKS_DIR:-}" ]; then
  fail=$((fail+1)); echo "FAIL structural: HOOKS_DIR is unset — this suite cannot read the lane's own hooks, which is the only thing it is for. Re-run as: HOOKS_DIR=<lane hooks dir> $0"
elif [ ! -d "$HOOKS_DIR" ]; then
  fail=$((fail+1)); echo "FAIL structural: HOOKS_DIR=$HOOKS_DIR is not a directory — a misspelled path is not an absence of hooks."
elif [ -z "$(find "$HOOKS_DIR" -maxdepth 1 -name '*.sh' -print -quit 2>/dev/null)" ]; then
  pass=$((pass+1)); echo "SKIPPED structural: $HOOKS_DIR holds no .sh files — stated, not silently dropped."
else
  hits="$(unguarded_hits "$HOOKS_DIR")"
  if [ -n "$hits" ]; then fail=$((fail+1)); echo "FAIL structural: an unguarded date -d on a variable in $HOOKS_DIR (guard = a shape check on the variable, never 2>/dev/null or an rc test):"; echo "$hits"; else pass=$((pass+1)); fi
fi

# EXPECTED is carried by the file so the count is readable at all; it does NOT self-certify — a stale copy prints its
# own stale expectation. Compare against the published copy to close the denominator; the printed hashes are the
# handle for that comparison: `tested` is the matcher, `by` is this suite.
EXPECTED=55
total=$((pass+fail))
[ "$total" -eq "$EXPECTED" ] || echo "FAIL suite-integrity: ran $total assertions, expected $EXPECTED — the suite is incomplete, not passing."
echo "housekeeping-selftest: $pass passed / $fail failed / $EXPECTED expected (tested $(sha256sum "$MATCHER" | cut -c1-16), by $(sha256sum "$0" | cut -c1-16), fixture-date=$TODAY)"
exit $(( fail == 0 && total == EXPECTED ? 0 : 1 ))
