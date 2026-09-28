#!/usr/bin/env bash
# Self-test for compact-nudge.sh. Every verdict is made to fire both ways. Usage: compact-selftest.sh [hooks dir]
set -uo pipefail
D="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export CLAUDE_PROJECT_DIR="$TMP/proj" COMPACT_STATE_DIR="$TMP/state"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/hooks"
NOW="$(date -u -d 2026-09-28T12:00:00Z +%s)"
pass=0; fail=0
ok()  { echo "  PASS  $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1 — $2"; fail=$((fail+1)); }
# transcript <file> <first instant> <boundaries>
transcript() { { printf '{"type":"user","timestamp":"%s"}\n' "$2"; for _ in $(seq 1 "$3"); do printf '{"type":"system","subtype":"compact_boundary","timestamp":"%s"}\n' "$2"; done; } > "$1"; }
nudge() { jq -nc --arg s "$1" --arg src "$2" --arg t "$3" '{hook_event_name:"SessionStart",session_id:$s,source:$src,transcript_path:$t}' \
          | COMPACT_NOW="$NOW" bash "$D/compact-nudge.sh" 2>&1; }
T="$TMP/t.jsonl"

echo "== install =="
[ -x "$D/compact-nudge.sh" ] && ok "compact-nudge.sh is executable" || bad "exec-bit" "mode"

echo "== only source=compact =="
transcript "$T" 2026-09-24T12:00:00Z 5
for src in startup resume clear; do out="$(nudge s0 $src "$T")"; [ -z "$out" ] && ok "source=$src is silent" || bad "source=$src" "$out"; done
out="$(nudge s0 compact "$T")"; [ -n "$out" ] && ok "source=compact with 5 compactions speaks" || bad "compact speaks" "silent"
out="$(nudge "" compact "$T")"; [ -z "$out" ] && ok "no session id is silent" || bad "no id" "$out"

echo "== threshold (default 2) =="
transcript "$T" 2026-09-28T02:00:00Z 1
out="$(nudge s1 compact "$T")"; [ -z "$out" ] && ok "1 compaction is below the default threshold" || bad "below" "$out"
transcript "$T" 2026-09-28T02:00:00Z 2
out="$(nudge s1 compact "$T")"; printf '%s' "$out" | grep -q "compacted 2 times" && ok "2 compactions reach it and are counted" || bad "at threshold" "$out"
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext and .systemMessage' >/dev/null && ok "the nudge reaches the operator and the session" || bad "shape" "$out"
printf '%s' "$out" | grep -q "/handover and start a fresh session" && ok "the remedy is a handover, then a fresh session" || bad "remedy" "$out"

echo "== age =="
printf '%s' "$out" | grep -q "over 10h" && ok "age under two days reads in hours (10h)" || bad "hours" "$out"
transcript "$T" 2026-09-24T12:00:00Z 2
out="$(nudge s2 compact "$T")"; printf '%s' "$out" | grep -q "over 4 days" && ok "age from the first transcript instant (4 days)" || bad "days" "$out"

echo "== team.conf =="
printf 'COMPACT_NUDGE_AT=3\n' > "$CLAUDE_PROJECT_DIR/.claude/hooks/team.conf"
transcript "$T" 2026-09-28T02:00:00Z 2
out="$(nudge s3 compact "$T")"; [ -z "$out" ] && ok "COMPACT_NUDGE_AT=3: 2 compactions stay silent" || bad "conf below" "$out"
transcript "$T" 2026-09-28T02:00:00Z 3
out="$(nudge s3 compact "$T")"; printf '%s' "$out" | grep -q "compacted 3 times" && ok "COMPACT_NUDGE_AT=3: 3 compactions speak" || bad "conf at" "$out"
printf 'COMPACT_NUDGE_AT=$(touch %s/pwned)\n' "$TMP" > "$CLAUDE_PROJECT_DIR/.claude/hooks/team.conf"
transcript "$T" 2026-09-28T02:00:00Z 2
out="$(nudge s4 compact "$T")"; printf '%s' "$out" | grep -q "compacted 2 times" && ok "an unshaped value falls back to 2" || bad "conf garbage" "$out"
[ -e "$TMP/pwned" ] && bad "conf executed" "team.conf ran" || ok "team.conf is read as data, never executed"
rm -f "$CLAUDE_PROJECT_DIR/.claude/hooks/team.conf"

echo "== the hook's own record (transcript unreadable) =="
out="$(nudge s5 compact "$TMP/missing.jsonl")"; [ -z "$out" ] && ok "first compaction seen, no transcript: silent" || bad "record 1" "$out"
out="$(nudge s5 compact "$TMP/missing.jsonl")"; printf '%s' "$out" | grep -q "compacted 2 times" && ok "second compaction seen, no transcript: counted from the record" || bad "record 2" "$out"
[ "$(grep -c . "$COMPACT_STATE_DIR/s5.log")" = 2 ] && ok "the record holds one line per compaction seen" || bad "record lines" "$(cat "$COMPACT_STATE_DIR/s5.log")"
out="$(nudge s6 startup "$TMP/missing.jsonl")"; [ ! -e "$COMPACT_STATE_DIR/s6.log" ] && ok "a non-compact start records nothing" || bad "record on startup" "written"

echo; echo "RESULT: $pass passed, $fail failed"; [ "$fail" -eq 0 ]
