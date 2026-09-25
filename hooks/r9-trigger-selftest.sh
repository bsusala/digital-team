#!/usr/bin/env bash
# Self-test for r9-wrap-trigger.sh. A check's green counts only after its failure path has been made to fire:
# this drives the real script through every branch and asserts on behaviour AND on the log record.
# Runs against a throwaway state dir; never touches real state. Usage: bash r9-trigger-selftest.sh [path/to/hook]
set -uo pipefail
HOOK="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/r9-wrap-trigger.sh}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export R9_STATE_DIR="$TMP/state" CLAUDE_PROJECT_DIR="$TMP/proj"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/hooks"
LOG="$R9_STATE_DIR/r9-trigger-log.tsv"
pass=0; fail=0
ok()   { echo "  PASS  $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL  $1 — $2"; fail=$((fail+1)); }
j()    { jq -nc --arg p "$1" --arg s "$2" --arg e "${3:-UserPromptSubmit}" '{hook_event_name:$e,session_id:$s,prompt:$p}'; }
run()  { printf '%s' "$1" | bash "$HOOK" 2>/dev/null; }
lastlog() { tail -1 "$LOG" 2>/dev/null | cut -f3-; }

# --- jq-absent harness: coreutils PRESENT, only jq removed (never PATH=/nonexistent) ---
NOJQ="$TMP/nojq"; mkdir -p "$NOJQ"
for b in bash cat grep tr sed head tail date mkdir basename wc cut; do p="$(command -v "$b")" && ln -s "$p" "$NOJQ/$b"; done
run_nojq() { printf '%s' "$1" | /usr/bin/env -i HOME="$HOME" PATH="$NOJQ" R9_STATE_DIR="$R9_STATE_DIR" CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR" "$(command -v bash)" "$HOOK" 2>/dev/null; }

echo "== conformance: every phrase R9 names fires =="
n=0
for p in "ok, let's wrap up" "time for the handover" "see you tomorrow"; do
  n=$((n+1)); out="$(run "$(j "$p" "conf$n")")"
  if printf '%s' "$out" | grep -q "R9 wrap trigger fired"; then ok "fires: '$p'"; else bad "fires: '$p'" "no reminder"; fi
done

echo "== behaviour =="
p1="please read the switch port map"; out="$(run "$(j "$p1" s1)")"
[ -z "$out" ] && ok "no-match is silent" || bad "no-match is silent" "got output"
[ "$(lastlog)" = "$(printf 'NO-MATCH\tlen=%s peer=0' "${#p1}")" ] && ok "no-match logs len= and peer=0" || bad "no-match log record" "$(lastlog)"

out="$(run "$(j "ok thanks, let's wrap up for now" s2)")"
printf '%s' "$out" | grep -q "1. /handover" && printf '%s' "$out" | grep -q "2. R9 closing report" && ok "reminder names BOTH obligations" || bad "both obligations" "text"
printf '%s' "$out" | grep -qi "otherwise" && bad "no either/or wording" "found 'otherwise'" || ok "no either/or wording"
[ "$(lastlog | cut -f1)" = "MATCH" ] && ok "match logs bare MATCH (no -DEGRADED with jq present)" || bad "MATCH label" "$(lastlog)"
lastlog | grep -q "wrap up for now" && ok "match logs the prompt excerpt" || bad "excerpt logged" "$(lastlog)"

out="$(run "$(j "and again, wrap up" s2)")"
printf '%s' "$out" | grep -q "already fired this session" && ! printf '%s' "$out" | grep -q "1. /handover" && ok "second fire in same session is one line" || bad "repeat fire" "text"

echo "== peer envelope =="
peer="Another Claude session sent a message:
<cross-session-message from=\"uds:/x\" from-name=\"peer-1\" from-mode=\"prompting\">
ok let's wrap up for now — quoting the operator
</cross-session-message>"
out="$(run "$(j "$peer" s3)")"
printf '%s' "$out" | grep -q "PEER message" && ! printf '%s' "$out" | grep -q "1. /handover" && ok "peer close phrase → one-line note, not the reminder" || bad "peer envelope" "$out"
[ "$(lastlog | cut -f1)" = "MATCH-PEER" ] && ok "peer match logged as MATCH-PEER" || bad "MATCH-PEER log" "$(lastlog)"
p2="<cross-session-message from-name=\"x\"> nothing to see here </cross-session-message>"; out="$(run "$(j "$p2" s3)")"
[ "$(lastlog)" = "$(printf 'NO-MATCH\tlen=%s peer=1' "${#p2}")" ] && ok "peer no-match logs peer=1" || bad "peer no-match" "$(lastlog)"

echo "== local phrase list =="
printf '%s\n' "# lane-local" "shutting the lid" > "$CLAUDE_PROJECT_DIR/.claude/hooks/r9-phrases.local"
out="$(run "$(j "shutting the lid now" s4)")"
printf '%s' "$out" | grep -q "R9 wrap trigger fired" && ok "local phrase fires" || bad "local phrase" "silent"
rm -f "$CLAUDE_PROJECT_DIR/.claude/hooks/r9-phrases.local"

echo "== SessionEnd logger =="
run "$(j "" s2 SessionEnd)" >/dev/null
[ "$(lastlog)" = "$(printf 'SESSION-END\treason=unknown trigger_fired=yes')" ] && ok "SessionEnd logs trigger_fired=yes for a fired session" || bad "SessionEnd fired" "$(lastlog)"
run "$(j "" s9 SessionEnd)" >/dev/null
lastlog | grep -q "trigger_fired=no" && ok "SessionEnd logs trigger_fired=no for a quiet session" || bad "SessionEnd quiet" "$(lastlog)"

echo "== jq-absent (coreutils present, jq removed) =="
[ -x "$NOJQ/bash" ] && ! [ -e "$NOJQ/jq" ] || bad "harness" "nojq dir wrong"
out="$(run_nojq "$(j "let's wrap up" s5)")"
printf '%s' "$out" | grep -q "running DEGRADED" && printf '%s' "$out" | grep -q "R9 wrap trigger fired" && ok "jq-absent + close phrase → fires WITH degraded banner" || bad "degraded fire" "$out"
[ "$(lastlog | cut -f1)" = "MATCH-DEGRADED" ] && ok "degraded match logged MATCH-DEGRADED" || bad "MATCH-DEGRADED label" "$(lastlog)"
out="$(run_nojq "$(j "please read the port map" s6)")"
[ -z "$out" ] && ok "jq-absent + NO close phrase → SILENT" || bad "degraded silent" "$out"
lastlog | grep -q "^NO-MATCH-DEGRADED" && ok "degraded no-match logged NO-MATCH-DEGRADED" || bad "NO-MATCH-DEGRADED label" "$(lastlog)"

echo "== SessionEnd vs degraded and peer fires =="
run "$(j "" s5 SessionEnd)" >/dev/null
lastlog | grep -q "trigger_fired=yes" && ok "SessionEnd counts a DEGRADED operator fire as fired" || bad "SessionEnd degraded" "$(lastlog)"
run "$(j "" s3 SessionEnd)" >/dev/null
lastlog | grep -q "trigger_fired=no" && ok "SessionEnd does NOT count a MATCH-PEER as fired (deliberate)" || bad "SessionEnd peer" "$(lastlog)"

echo "== state dir resolves under Claude Code's project dir =="
FH="$TMP/fakehome"; mkdir -p "$FH"
printf '%s' "$(j "ok lets wrap up" s8)" | /usr/bin/env -i HOME="$FH" PATH="$PATH" CLAUDE_PROJECT_DIR="/x/lane-y" "$(command -v bash)" "$HOOK" >/dev/null 2>&1
[ -f "$FH/.claude/projects/-x-lane-y/r9/r9-trigger-log.tsv" ] && ok "log lands in ~/.claude/projects/<key>/r9/" || bad "state dir" "$(find "$FH" -name '*.tsv' 2>/dev/null)"

echo "== bare 'wrap' does not fire; completed forms do =="
for p in "please look at r9-wrap-trigger.sh" "the wrap is a container type" "gift wrap for the box"; do
  out="$(run "$(j "$p" s10)")"; [ -z "$out" ] && ok "silent: '$p'" || bad "silent: '$p'" "fired"
done
for p in "wrap-up time" "let's wrap it up" "wrap things up now" "we'll wrap here"; do
  out="$(run "$(j "$p" s11)")"; printf '%s' "$out" | grep -q "R9 wrap trigger" && ok "fires: '$p'" || bad "fires: '$p'" "silent"
done

echo "== pilot name from team.conf =="
out="$(run "$(j "ok, let's wrap up" p1)")"; printf '%s' "$out" | grep -q "pilot (the pilot) LISTED" && ok "no team.conf → 'the pilot'" || bad "default pilot" "$out"
printf 'PILOT_NAME=coordinator\n' > "$CLAUDE_PROJECT_DIR/.claude/hooks/team.conf"
out="$(run "$(j "ok, let's wrap up" p2)")"; printf '%s' "$out" | grep -q "pilot (coordinator) LISTED" && ok "team.conf names the pilot" || bad "named pilot" "$out"
printf 'PILOT_NAME=$(touch %s/pwned)\n' "$TMP" > "$CLAUDE_PROJECT_DIR/.claude/hooks/team.conf"
run "$(j "ok, let's wrap up" p3)" >/dev/null; [ ! -e "$TMP/pwned" ] && ok "team.conf is read as data, never executed" || bad "team.conf executed" "file created"
rm -f "$CLAUDE_PROJECT_DIR/.claude/hooks/team.conf"

echo "== exit codes =="
printf '%s' "$(j "x" s7)" | bash "$HOOK" >/dev/null 2>&1; [ $? -eq 0 ] && ok "exit 0 on no-match" || bad "exit" "nonzero"
printf 'not json at all' | bash "$HOOK" >/dev/null 2>&1; [ $? -eq 0 ] && ok "exit 0 on garbage payload" || bad "exit garbage" "nonzero"

# A hook installed with a bare `>` on a fresh path is 0644 and never runs — assert the bit, do not assume it.
[ -x "$HOOK" ] && ok "hook is executable ($HOOK)" || bad "exec-bit" "$HOOK is not executable — chmod +x after install"

echo; echo "RESULT: $pass passed, $fail failed"; [ "$fail" -eq 0 ]
