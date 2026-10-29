#!/usr/bin/env bash
# Self-test for duplicate-session-guard.sh — fixture cases through the test seams. Expected: 13 passed, 0 failed.
# Run: bash .claude/hooks/duplicate-session-guard-selftest.sh   (HOOKS_DIR overrides the script's directory)
set -uo pipefail
HOOKS_DIR="$(cd "${HOOKS_DIR:-$(dirname "$0")}" && pwd)" || exit 1   # absolute: the suite runs from its own empty directory
H="$HOOKS_DIR/duplicate-session-guard.sh"
T="$(mktemp -d)"; W="$T/cwd"; trap 'rm -rf "$T"' EXIT
mkdir -p "$W"; cd "$W" || exit 1
printf '#!/bin/sh\nprintf "%%s\\n" "$@" > "%s/notified"\n' "$T" > "$T/notify"; chmod +x "$T/notify"
pass=0; fail=0
P=/work/proj

run() { # run <fixture-lines> [self]
  printf '%b' "$1" > "$T/fx"
  echo '{}' | CLAUDE_PROJECT_DIR="$P" DUP_FIXTURE="$T/fx" DUP_SELF_PID="${2-100}" \
    DUP_NOTIFY_CMD="$T/notify" bash "$H" 2>&1
}
check() { # check <name> <output> <expect: warn|silent|noself>
  local got=silent
  case "$2" in *"DUPLICATE SESSION"*) got=warn ;; *"did NOT run"*) got=noself ;; esac
  if [ "$got" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $1: expected $3, got $got: $2"; fi
}

check "self only"                   "$(run "100\tpts/0\t$P\n")" silent
check "peer same dir"               "$(run "100\tpts/0\t$P\n200\tpts/1\t$P\n")" warn
check "peer in subdir"              "$(run "100\tpts/0\t$P\n200\tpts/1\t$P/src\n")" warn
check "prefix sibling"              "$(run "100\tpts/0\t$P\n200\tpts/1\t${P}2\n")" silent
check "peer without tty"            "$(run "100\tpts/0\t$P\n200\t?\t$P\n")" silent
check "other project"               "$(run "100\tpts/0\t$P\n200\tpts/1\t/work/other\n")" silent
check "own pid unknown"             "$(run "200\tpts/1\t$P\n" none)" noself
check "peer tty empty: not counted" "$(run "100\tpts/0\t$P\n200\t\t$P\n")" silent
check "headless self, live peer"    "$(run "100\t?\t$P\n200\tpts/1\t$P\n")" warn
# Without jq the warning is still printed, and as valid JSON.
mkdir -p "$T/bin"; for c in cat ps tr date basename id sed timeout dirname; do p="$(command -v "$c")" && ln -sf "$p" "$T/bin/$c"; done
nojq="$(printf '%b' "100\tpts/0\t$P\n200\tpts/1\t$P\n" > "$T/fx"; echo '{}' | PATH="$T/bin" CLAUDE_PROJECT_DIR="$P" DUP_FIXTURE="$T/fx" DUP_SELF_PID=100 DUP_NOTIFY_CMD="$T/notify" "$BASH" "$H" 2>&1)"
check "jq absent: still warns"      "$nojq" warn
if printf '%s' "$nojq" | jq -e '.hookSpecificOutput.additionalContext | test("DUPLICATE SESSION")' >/dev/null 2>&1; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL jq-absent output is not valid hook JSON: $nojq"; fi
rm -f "$T/notified"; run "100\tpts/0\t$P\n200\tpts/1\t$P\n" >/dev/null
if grep -q '^Claude Code: duplicate session$' "$T/notified" 2>/dev/null; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL notice: notify command not called with its title"; fi
# The suite runs in an empty working directory and must leave it empty: a notify stand-in that writes a file named
# after its arguments would litter wherever the suite ran.
if [ -z "$(ls -A "$W")" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL stray files in the working directory: $(ls -A "$W")"; fi

echo "duplicate-session-guard selftest: $pass passed, $fail failed (expected 13 passed, 0 failed)"
[ "$fail" -eq 0 ] && [ "$pass" -eq 13 ]
