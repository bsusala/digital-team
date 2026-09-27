#!/usr/bin/env bash
# Self-test for due-check.sh (D2) and r9-unclosed-warn.sh (D3). Every verdict is made to fire both ways.
# Runs against throwaway state; never touches real state. Usage: bash d2d3-selftest.sh [hooks-dir]
set -uo pipefail
D="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export CLAUDE_PROJECT_DIR="$TMP/proj" DUE_STATE_DIR="$TMP/due" R9_STATE_DIR="$TMP/r9"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/hooks" "$R9_STATE_DIR"
pass=0; fail=0
ok()  { echo "  PASS  $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1 — $2"; fail=$((fail+1)); }
ev()  { jq -nc --arg e "$1" --arg s "$2" '{hook_event_name:$e,session_id:$s}'; }
due() { ev "$1" "$2" | DUE_NOW="$3" bash "$D/due-check.sh" 2>&1; }
warn(){ ev SessionStart "$1" | R9_NOW="${2:-2000000000}" bash "$D/r9-unclosed-warn.sh" 2>&1; }
for f in due-check.sh r9-unclosed-warn.sh; do [ -x "$D/$f" ] && ok "$f is executable" || bad "$f is executable" "mode"; done

echo "== D2 due-check =="
out="$(due SessionStart s0 0)"; printf '%s' "$out" | grep -q "no .claude/hooks/due-stamps.local" && ok "missing config is reported at SessionStart" || bad "missing config reported" "$out"
out="$(due Stop s0 0)"; [ -z "$out" ] && ok "missing config is silent at Stop" || bad "missing config silent at Stop" "$out"
S="$TMP/stamp"; echo '2026-09-24T12:00Z|daily' > "$S"
t=$(date -u -d 2026-09-24T12:00Z +%s)
printf 'R10\t%s\t24\n' "$S" > "$CLAUDE_PROJECT_DIR/.claude/hooks/due-stamps.local"
out="$(due SessionStart s1 $((t+23*3600+59*60)))"; [ -z "$out" ] && ok "23h59m is current (silent)" || bad "not due under period" "$out"
out="$(due SessionStart s1 $((t+24*3600)))"; printf '%s' "$out" | grep -q "R10: DUE — last 2026-09-24T12:00Z, age 24h0m" && ok "24h0m is DUE" || bad "due at period" "$out"
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext and .systemMessage' >/dev/null && ok "SessionStart reaches session and operator" || bad "SessionStart shape" "$out"
out="$(due UserPromptSubmit s1 $((t+25*3600)))"; printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName=="UserPromptSubmit" and .hookSpecificOutput.additionalContext' >/dev/null && ok "UserPromptSubmit reaches the session" || bad "UPS shape" "$out"
out="$(due UserPromptSubmit s1 $((t+26*3600)))"; [ -z "$out" ] && ok "UserPromptSubmit says it once per crossing" || bad "UPS repeat" "$out"
out="$(due Stop s1 $((t+26*3600)))"; printf '%s' "$out" | jq -e '.systemMessage' >/dev/null && ok "Stop tells the operator (its own door)" || bad "Stop shape" "$out"
out="$(due Stop s1 $((t+27*3600)))"; [ -z "$out" ] && ok "Stop says it once per crossing" || bad "Stop repeat" "$out"
out="$(due Stop s2 $((t+27*3600)))"; [ -n "$out" ] && ok "a new session is told again" || bad "new session" "empty"
out="$(due Stop s1 $((t+27*3600+86400)))"; [ -n "$out" ] && ok "a continued session (same id) is told again after 24 h" || bad "continued 24h" "empty"
out="$(due Stop s1 $((t+27*3600+86400+60)))"; [ -z "$out" ] && ok "…and then once again only" || bad "continued once" "$out"
echo '2026-09-25T13:00Z|daily' > "$S"; out="$(due Stop s1 $((t+49*3600)))"; printf '%s' "$out" | grep -q "last 2026-09-25T13:00Z" && ok "a new stamp that falls due is told again" || bad "stamp change" "$out"
printf 'old 2026-09-20T10:00Z\nnew 2026-09-25T13:00Z\nolder 2026-09-01T00:00Z\n' > "$S"; out="$(due SessionStart s3 $((t+30*3600)))"; [ -z "$out" ] && ok "MAX instant governs, not the last line" || bad "max instant" "$out"
echo '2026-09-24|daily' > "$S"; out="$(due SessionStart s3 $((t-12*3600+24*3600)))"; printf '%s' "$out" | grep -q "DUE — last 2026-09-24T00:00Z.*legacy date-only" && ok "date-only stamp is read as T00:00Z (errs toward due), marked legacy" || bad "date-only" "$out"
out="$(due SessionStart s3 $((t-12*3600+23*3600)))"; [ -z "$out" ] && ok "date-only stamp under the period is current" || bad "date-only current" "$out"
echo 'no stamp here' > "$S"; out="$(due SessionStart s3 $t)"; printf '%s' "$out" | grep -q "INDETERMINATE" && ok "no instant and no date is INDETERMINATE" || bad "indeterminate" "$out"
rm -f "$S"; out="$(due SessionStart s3 $t)"; printf '%s' "$out" | grep -q "NEVER" && ok "missing stamp is NEVER" || bad "missing stamp" "$out"
printf 'R10\t%s\tdaily\n' "$S" > "$CLAUDE_PROJECT_DIR/.claude/hooks/due-stamps.local"; out="$(due SessionStart s3 $t)"; printf '%s' "$out" | grep -q "not a whole number" && ok "bad period is reported" || bad "bad period" "$out"

printf 'R10\t%s\t24\t^Swept:\n' "$S" > "$CLAUDE_PROJECT_DIR/.claude/hooks/due-stamps.local"
printf 'Swept: 2026-09-24T12:00Z\n- targeted check 2026-09-25T11:00Z, finding logged\n' > "$S"
out="$(due SessionStart s4 $((t+25*3600)))"; printf '%s' "$out" | grep -q "DUE — last 2026-09-24T12:00Z" && ok "anchor: a later non-anchor instant does not reset the clock" || bad "anchor" "$out"
printf 'R10\t%s\t24\n' "$S" > "$CLAUDE_PROJECT_DIR/.claude/hooks/due-stamps.local"
out="$(due SessionStart s4 $((t+25*3600)))"; [ -z "$out" ] && ok "control: without an anchor the later instant governs" || bad "anchor control" "$out"

echo "== D3 unclosed warning =="
L="$R9_STATE_DIR/r9-trigger-log.tsv"
out="$(warn cur)"; [ -z "$out" ] && ok "no log is silent" || bad "no log" "$out"
printf '2026-09-24T10:00:00Z\tA\tMATCH\tok wrap up\n2026-09-24T10:01:00Z\tA\tSESSION-END\treason=prompt_input_exit trigger_fired=yes\n' > "$L"
out="$(warn cur)"; [ -z "$out" ] && ok "closed previous session is silent" || bad "closed silent" "$out"
printf '2026-09-24T10:00:00Z\tA\tNO-MATCH\tlen=3 peer=0\n2026-09-24T10:01:00Z\tA\tSESSION-END\treason=other trigger_fired=no\n' > "$L"
out="$(warn cur)"; printf '%s' "$out" | grep -q "ended WITHOUT a close" && ok "trigger_fired=no warns" || bad "unclosed" "$out"
printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null && ok "warning reaches the session" || bad "D3 shape" "$out"
out="$(warn A)"; printf '%s' "$out" | grep -q "A (this session's previous run, continued) ended WITHOUT a close" && ok "--continue: a resumed session's own previous run is read (id reused)" || bad "continued run" "$out"
printf '2026-09-24T09:00:00Z\tA\tMATCH\twrap up\n2026-09-24T09:05:00Z\tA\tSESSION-END\treason=prompt_input_exit trigger_fired=yes\n2026-09-24T10:00:00Z\tA\tNO-MATCH\tlen=3 peer=0\n2026-09-24T10:01:00Z\tA\tSESSION-END\treason=prompt_input_exit trigger_fired=no\n' > "$L"
out="$(warn A)"; printf '%s' "$out" | grep -q "ended WITHOUT a close (2026-09-24T10:01:00Z" && ok "runs are split at SESSION-END: the latest run is judged, not an earlier closed one" || bad "run split latest" "$out"
printf '2026-09-24T09:00:00Z\tA\tNO-MATCH\tlen=3 peer=0\n2026-09-24T09:05:00Z\tA\tSESSION-END\treason=prompt_input_exit trigger_fired=no\n2026-09-24T10:00:00Z\tA\tMATCH\twrap up\n2026-09-24T10:01:00Z\tA\tSESSION-END\treason=prompt_input_exit trigger_fired=yes\n' > "$L"
out="$(warn A)"; [ -z "$out" ] && ok "a closed latest run is silent even after an earlier unclosed run" || bad "run split closed" "$out"
printf '2026-09-24T09:00:00Z\tA\tMATCH\twrap up\n2026-09-24T09:05:00Z\tA\tSESSION-END\treason=prompt_input_exit trigger_fired=yes\n2026-09-24T10:00:00Z\tA\tNO-MATCH\tlen=3 peer=0\n2026-09-24T10:01:00Z\tA\tSESSION-END\treason=prompt_input_exit trigger_fired=yes\n' > "$L"
out="$(warn A)"; printf '%s' "$out" | grep -q "ended WITHOUT a close (2026-09-24T10:01:00Z" && ok "a stale cumulative trigger_fired=yes is not trusted: no close phrase in the run → warns" || bad "stale trigger_fired" "$out"
printf '2026-09-24T10:00:00Z\tA\tNO-MATCH\tlen=3 peer=0\n2026-09-24T10:01:00Z\tA\tSESSION-END\treason=clear trigger_fired=no\n' > "$L"
out="$(warn cur)"; [ -z "$out" ] && ok "reason=clear is not an unclosed exit" || bad "clear" "$out"
printf '2026-09-24T10:00:00Z\tA\tNO-MATCH\tlen=3 peer=0\n' > "$L"
out="$(warn cur)"; printf '%s' "$out" | grep -q "NO SESSION-END record" && ok "missing SESSION-END warns" || bad "died" "$out"
printf '%s' "$out" | grep -q "may still be running" && bad "old session not live" "$out" || ok "an old session is not called live"
out="$(warn cur "$(( $(date -u -d 2026-09-24T10:00:00Z +%s) + 300 ))")"; printf '%s' "$out" | grep -q "may still be running" && ok "a session seen 5 min ago may be live" || bad "live note" "$out"

echo "== D3 handover-commit evidence =="
G="$CLAUDE_PROJECT_DIR"; git -C "$G" init -q; mkdir -p "$G/docs"
gc() { echo "$2" > "$G/docs/CONTINUATION.md"; git -C "$G" add docs/CONTINUATION.md; GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git -C "$G" -c user.name=t -c user.email=t@t commit -qm "$2"; git -C "$G" rev-parse --short HEAD; }
printf '2026-09-24T10:00:00Z\tP\tNO-MATCH\tlen=3 peer=0\n2026-09-24T11:00:00Z\tP\tSESSION-END\treason=prompt_input_exit trigger_fired=no\n' > "$L"
gc 2026-09-23T09:00:00Z before >/dev/null
out="$(warn cur)"; printf '%s' "$out" | grep -q "No handover commit in its window" && ok "a commit before the window is not evidence" || bad "before window" "$out"
h="$(gc 2026-09-24T10:30:00Z inside)"
out="$(warn cur)"; printf '%s' "$out" | grep -q "Handover committed at 2026-09-24T10:30:00Z ($h)" && ok "a commit inside the window is printed with its time and hash" || bad "inside window" "$out"
printf '%s' "$out" | grep -q "ended WITHOUT a close" && ok "the verdict is unchanged by the evidence" || bad "verdict" "$out"
h2="$(gc 2026-09-24T11:10:00Z grace)"
out="$(warn cur)"; printf '%s' "$out" | grep -q "committed at 2026-09-24T11:10:00Z ($h2)" && ok "the 15-minute grace after the end counts" || bad "grace" "$out"
gc 2026-09-24T11:20:00Z after >/dev/null
out="$(warn cur)"; printf '%s' "$out" | grep -q "committed at 2026-09-24T11:10:00Z" && ok "a commit after the grace is not evidence" || bad "after grace" "$out"
printf '2026-09-24T10:00:00Z\tP\tMATCH\twrap up\n2026-09-24T11:00:00Z\tP\tSESSION-END\treason=prompt_input_exit trigger_fired=yes\n' > "$L"
out="$(warn cur)"; [ -z "$out" ] && ok "a closed session stays silent whatever git holds" || bad "closed + commit" "$out"
printf '2026-09-24T08:00:00Z\tQ\tNO-MATCH\tlen=3 peer=0\n2026-09-24T10:20:00Z\tQ\tSESSION-END\treason=other trigger_fired=no\n2026-09-24T10:35:00Z\tP\tNO-MATCH\tlen=3 peer=0\n2026-09-24T10:50:00Z\tP\tSESSION-END\treason=other trigger_fired=no\n' > "$L"
out="$(warn cur)"; printf '%s' "$out" | grep -q "No handover commit in its window" && ok "the window starts after the previous SESSION-END: an earlier run's handover is not this run's" || bad "window start" "$out"
printf '2026-09-24T10:00:00Z\tP\tNO-MATCH\tlen=3 peer=0\n2026-09-24T10:40:00Z\tP\tNO-MATCH\tlen=5 peer=0\n' > "$L"
out="$(warn cur)"; printf '%s' "$out" | grep -q "NO SESSION-END record.*committed at 2026-09-24T10:30:00Z" && ok "the died case carries the evidence, window ending at last-seen + grace" || bad "died + evidence" "$out"

echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
