#!/usr/bin/env bash
# Backburner delta: which Open / Parked tracker entries may have moved since the last housekeeping pass.
# A cheap pre-step before reviewing the backlog — it lists CANDIDATES to re-verify; it closes nothing.
# Two signals per entry, both read from this repository's git history since the stamp instant:
#   named   — a commit SUBJECT since the stamp cites the entry's id (#N or PREFIX-N, e.g. OPS-066);
#             "Tracker:" bookkeeping commits excluded
#   touched — a commit since the stamp changed a repository path the entry names in backticks
# Repository-wide files (the tracker, the changelog, the handover) say nothing about any one entry and are skipped;
# a lane adds its own in .backburner-skip at the repository root, one path per line (# comments allowed).
# Fixes made in another lane leave no trace here; they arrive as fix notices from the lane that made them.
#
# Usage: backburner-delta.sh [--since YYYY-MM-DDTHH:MMZ] [--tracker docs/ISSUES.md]
#   default since = the housekeeping stamp: $HK_STAMP when set; else HOUSEKEEPING_STAMP= in .claude/hooks/team.conf
#   (absolute, ~/…, or relative to the repository root); else docs/.housekeeping when it exists. Any other case is
#   INDETERMINATE: a delta against the wrong baseline reads exactly like a correct one.
# Self-test: backburner-delta.sh --selftest
set -u

resolve_stamp() {  # $1 = repository root; prints the stamp path, or nothing when it cannot tell
  local root="$1" p
  if [ -n "${HK_STAMP:-}" ]; then printf '%s' "$HK_STAMP"; return; fi
  # team.conf is read as data, never sourced.
  p="$(sed -n 's/^HOUSEKEEPING_STAMP=//p' "$root/.claude/hooks/team.conf" 2>/dev/null | head -1)"
  if [ -n "$p" ]; then
    case "$p" in "~/"*) p="$HOME/${p#\~/}" ;; /*) ;; *) p="$root/$p" ;; esac
    printf '%s' "$p"; return
  fi
  [ -f "$root/docs/.housekeeping" ] && printf '%s' "$root/docs/.housekeeping"
}
TRACKER="docs/ISSUES.md"
SINCE=""
SKIP_PATHS=" docs/ISSUES.md CHANGELOG.md docs/CONTINUATION.md "

delta() {  # $1 = repository root, $2 = tracker path (relative), $3 = since instant
  local root="$1" tracker="$2" since="$3" gsince id title refs named touched seen n=0 hit=0 ids=0 resolved=0 p c files
  files="$(git -C "$root" ls-files)"
  # Shape first: GNU date also accepts "next monday" and an empty string, with rc 0.
  [[ "$since" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z$ ]] \
    || { echo "Backburner delta: INDETERMINATE (since does not parse: '$since')"; return; }
  gsince="$(date -u -d "$since" '+%Y-%m-%d %H:%M:%S +0000' 2>/dev/null)" || { echo "Backburner delta: INDETERMINATE (since does not parse: '$since')"; return; }
  [ -f "$root/$tracker" ] || { echo "Backburner delta: INDETERMINATE (no tracker at $root/$tracker)"; return; }
  local out="" skip="$SKIP_PATHS"
  [ -f "$root/.backburner-skip" ] && skip+="$(grep -v -e '^#' -e '^[[:space:]]*$' "$root/.backburner-skip" | tr '\n' ' ') "
  while IFS=$'\t' read -r id title refs; do
    n=$((n+1)); named=""; touched=""; seen=" "; [ "$id" != "-" ] && ids=$((ids+1))
    if [ "$id" != "-" ]; then
      named="$(git -C "$root" log --since="$gsince" --format='%h %s' | grep -E " .*${id}([^0-9]|$)" | grep -v '^[0-9a-f]* Tracker:' | head -3 | sed 's/^/      named   /')"
    fi
    for p in $(printf '%s\n' $refs | sort -u); do
      [[ "$skip" == *" $p "* ]] && continue
      [[ "$p" == /* || "$p" == ..* ]] && continue
      if [ ! -f "$root/$p" ]; then
        # A bare filename resolves only when exactly one tracked file carries that name.
        [[ "$p" == */* ]] && continue
        p="$(printf '%s\n' "$files" | awk -v b="$p" '$0==b || substr($0, length($0)-length(b)) == "/" b' )"
        [ -n "$p" ] && [ "$(printf '%s\n' "$p" | wc -l)" -eq 1 ] || continue
        [[ "$skip" == *" $p "* ]] && continue
      fi
      # A path and a bare name can resolve to the same file; count it once.
      [[ "$seen" == *" $p "* ]] && continue
      seen+="$p "
      resolved=$((resolved+1))
      c="$(git -C "$root" log --since="$gsince" --format='%h' -- "$p" | wc -l)"
      [ "$c" -gt 0 ] && touched+="      touched $p ($c commit$([ "$c" -gt 1 ] && echo s))"$'\n'
    done
    if [ -n "$named$touched" ]; then
      hit=$((hit+1))
      if [ "$id" = "-" ]; then out+="$hit. ${title:0:110}"$'\n'; else out+="$hit. $id — ${title:0:110}"$'\n'; fi
      [ -n "$named" ] && out+="$named"$'\n'
      out+="$touched"
    fi
  done < <(awk '
    # The section word starts the heading: "## LANE STATE: … Opened …" is not Open.
    /^## /{ sec = ($0 ~ /^## (Open|Parked|Post-launch|Deferred|Backlog)( |\/|$)/) ; next }
    sec && /^### /{ flush(); h=substr($0,5); id="-"; t=h
      if (match(h,/(#[0-9]+|[A-Z][A-Z0-9]*-[0-9]+)/)) { id=substr(h,RSTART,RLENGTH); if (RSTART==1) { t=substr(h,RLENGTH+1); sub(/^[^A-Za-z0-9`"(]+/,"",t) } }
      refs=""; inside=1 }
    sec && inside { s=$0; while (match(s,/`[^`]+`/)) { r=substr(s,RSTART+1,RLENGTH-2); sub(/:[0-9]+(-[0-9]+)?$/,"",r); if (r ~ /^[A-Za-z0-9_.\/-]+$/ && r ~ /[\/.]/) refs=refs" "r; s=substr(s,RSTART+RLENGTH) } }
    function flush(){ if (inside) { gsub(/\t/," ",t); print id "\t" t "\t" refs } inside=0 }
    END{ flush() }' "$root/$tracker")
  # A zero from an instrument that cannot see is not a zero.
  if [ "$n" -gt 0 ] && [ "$ids" -eq 0 ] && [ "$resolved" -eq 0 ]; then
    echo "Backburner delta: INDETERMINATE ($n entries, none carries an id (#N or PREFIX-N) and no named file resolves)"; return
  fi
  echo "Backburner delta: $hit of $n Open/Parked entries may have moved since $since ($ids with ids, $resolved file refs resolved)"
  [ -n "$out" ] && printf '%s' "$out"
  return 0
}

if [ "${1:-}" = "--selftest" ]; then
  T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT; pass=0; fail=0
  git -C "$T" init -q && git -C "$T" config user.email t@t && git -C "$T" config user.name t
  mkdir -p "$T/docs" "$T/src"
  printf 'a\n' > "$T/src/a.rs"; printf 'b\n' > "$T/src/b.rs"
  cat > "$T/docs/ISSUES.md" <<'EOF'
# Issues
## LANE STATE: hold OPENED then LIFTED — Opened 2030-09-11
### #4 — a note under a heading that only mentions the word, names `src/a.rs`
## Open
### #1 — named by a later commit
Body.
### #2 — names `src/a.rs:12` which changes later
### #3 — names `src/b.rs` which stays quiet
### #12 — must not match a commit citing #1
## Closed
### #9 — closed entries are not read `src/a.rs`
EOF
  GIT_COMMITTER_DATE="2030-01-01T00:00:00Z" GIT_AUTHOR_DATE="2030-01-01T00:00:00Z" git -C "$T" add -A
  GIT_COMMITTER_DATE="2030-01-01T00:00:00Z" GIT_AUTHOR_DATE="2030-01-01T00:00:00Z" git -C "$T" commit -qm "seed #3"
  printf 'a2\n' > "$T/src/a.rs"; git -C "$T" add -A
  GIT_COMMITTER_DATE="2030-02-01T00:00:00Z" GIT_AUTHOR_DATE="2030-02-01T00:00:00Z" git -C "$T" commit -qm "Fix the thing (#1)"
  got="$(delta "$T" docs/ISSUES.md 2030-01-15T00:00Z)"
  chk() { if [[ "$got" == *"$1"* ]]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL want '$1'"; fi; }
  nchk() { if [[ "$got" != *"$1"* ]]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL unwanted '$1'"; fi; }
  chk "2 of 4 Open/Parked entries"
  chk "1. #1 — named by a later commit"; chk "2. #2 — names"; chk "named   "; chk "touched src/a.rs (1 commit)"
  nchk "#3 —"; nchk "#12 —"; nchk "#9 —"; nchk "#4 —"
  got="$(delta "$T" docs/ISSUES.md 2030-03-01T00:00Z)"; chk "0 of 4"
  got="$(delta "$T" docs/ISSUES.md 'not a date')"; chk "INDETERMINATE (since does not parse"
  got="$(delta "$T" docs/ISSUES.md 'next monday')"; chk "INDETERMINATE (since does not parse"
  # Prefixed ids, bare filenames, the lane skip list, and an instrument that cannot see.
  mkdir -p "$T/scripts" "$T/logs"; printf 'x\n' > "$T/scripts/sweep.sh"; printf 'l\n' > "$T/logs/server.md"
  cat > "$T/docs/LANE.md" <<'EOF'
## Open
### OPS-066 — prefixed id cited by a later commit
### OPS-067 — names the bare `sweep.sh` which changes later, and again as `scripts/sweep.sh`
### OPS-068 — names `logs/server.md`, a lane-wide log on the skip list
### OPS-069 — quiet, and must not match OPS-066's commit
EOF
  printf '# per-server change log\nlogs/server.md\n' > "$T/.backburner-skip"
  printf '## Open\n### A note with no id and no files\n' > "$T/docs/BLIND.md"
  GIT_COMMITTER_DATE="2030-01-01T00:00:00Z" GIT_AUTHOR_DATE="2030-01-01T00:00:00Z" git -C "$T" add -A
  GIT_COMMITTER_DATE="2030-01-01T00:00:00Z" GIT_AUTHOR_DATE="2030-01-01T00:00:00Z" git -C "$T" commit -qm "seed lane"
  printf 'x2\n' > "$T/scripts/sweep.sh"; printf 'l2\n' > "$T/logs/server.md"; git -C "$T" add -A
  GIT_COMMITTER_DATE="2030-02-02T00:00:00Z" GIT_AUTHOR_DATE="2030-02-02T00:00:00Z" git -C "$T" commit -qm "Close OPS-066; log append"
  got="$(delta "$T" docs/LANE.md 2030-01-15T00:00Z)"
  chk "2 of 4 Open/Parked entries"; chk "1. OPS-066 — prefixed id cited"; chk "touched scripts/sweep.sh"
  nchk "OPS-068 —"; nchk "OPS-069 —"; nchk "OPS-066 — OPS-066"
  # One file named by path and by bare name prints one touched line.
  if [ "$(grep -c 'touched scripts/sweep.sh' <<<"$got")" -eq 1 ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL touched line repeated"; fi
  got="$(delta "$T" docs/BLIND.md 2030-01-15T00:00Z)"; chk "INDETERMINATE (1 entries, none carries an id"
  # The stamp: HK_STAMP, then team.conf, then docs/.housekeeping; with none of them, no stamp at all.
  L="$T/lane"; mkdir -p "$L/docs" "$L/.claude/hooks"
  got="$(HK_STAMP= resolve_stamp "$L")"; [ -z "$got" ] && got=NONE; chk "NONE"
  : > "$L/docs/.housekeeping"; got="$(HK_STAMP= resolve_stamp "$L")"; chk "$L/docs/.housekeeping"
  printf 'PILOT_NAME=p\nHOUSEKEEPING_STAMP=records/hk-stamp\n' > "$L/.claude/hooks/team.conf"
  got="$(HK_STAMP= resolve_stamp "$L")"; chk "$L/records/hk-stamp"
  printf 'HOUSEKEEPING_STAMP=~/team/hk\n' > "$L/.claude/hooks/team.conf"
  got="$(HK_STAMP= resolve_stamp "$L")"; chk "$HOME/team/hk"
  printf 'HOUSEKEEPING_STAMP=$(touch %s/pwned)\n' "$T" > "$L/.claude/hooks/team.conf"
  HK_STAMP= resolve_stamp "$L" >/dev/null; got="$( [ -e "$T/pwned" ] && echo EXECUTED || echo DATA)"; chk "DATA"
  got="$(HK_STAMP=/x/stamp resolve_stamp "$L")"; chk "/x/stamp"
  echo "backburner-delta selftest: $pass passed / $fail failed (expected 26 passed / 0 failed)"
  exit $([ "$fail" -eq 0 ] && [ "$pass" -eq 26 ] && echo 0 || echo 1)
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --since) SINCE="${2:-}"; shift 2 ;;
    --tracker) TRACKER="${2:-}"; shift 2 ;;
    *) echo "usage: backburner-delta.sh [--since YYYY-MM-DDTHH:MMZ] [--tracker docs/ISSUES.md] | --selftest"; exit 2 ;;
  esac
done
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Backburner delta: INDETERMINATE (not in a git repo)"; exit 0; }
if [ -z "$SINCE" ]; then
  STAMP="$(resolve_stamp "$ROOT")"
  [ -n "$STAMP" ] || { echo "Backburner delta: INDETERMINATE (no housekeeping stamp found: set HK_STAMP, HOUSEKEEPING_STAMP in .claude/hooks/team.conf, or pass --since)"; exit 0; }
  SINCE="$(tr -d '[:space:]' < "$STAMP" 2>/dev/null)"
  [[ "$SINCE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}Z$ ]] || { echo "Backburner delta: INDETERMINATE (no usable housekeeping stamp at $STAMP; pass --since)"; exit 0; }
fi
delta "$ROOT" "$TRACKER" "$SINCE"
exit 0
