#!/usr/bin/env bash
# R9 wrap trigger — fires a reminder when the operator's words look like a session close, and logs how each
# session ended. Charter: RULES.md R9 (wrap-up) and R9(d) (a close owes two things).
#
# Events: UserPromptSubmit (the trigger — fires AT the transition, while a turn can still act) and SessionEnd
# (a logger only — it records how the session closed, so a silent close is visible to the next session).
# Wire BOTH. See settings-hooks.json.
#
# This is a TRIGGER, not an implementation. A fired hook discharges nothing: on a close-shaped phrase it injects
# a reminder, and the session judges whether the moment really is a close and does the work.
#
# Configuration (all optional, in the project's .claude/hooks/):
#   team.conf         PILOT_NAME=<name>   — who receives closing reports; read as data, never executed
#   r9-phrases.local  one extended regex per line — the close phrasing your operator actually uses
#
# Failure modes, stated: a close worded outside the phrase list is MISSED — grow r9-phrases.local from the
# operator's real words. Prose that quotes the phrases fires it; the session judges (over-triggering is the
# chosen direction). Without jq it degrades to over-triggering on the raw payload, announced, never silent.
#
# Install: copy from a tagged release, chmod +x, run r9-trigger-selftest.sh before trusting it.
set -uo pipefail

# State (log + per-session markers) lives under Claude Code's own project directory,
# ~/.claude/projects/<project-key>/r9/, derived as Claude Code derives it (the path with "/" replaced by "-").
# R9_STATE_DIR is a TEST-ONLY override so the selftest never touches real state.
proj="${CLAUDE_PROJECT_DIR:-$PWD}"
proj_key="$(printf '%s' "$proj" | tr '/' '-')"
STATE_DIR="${R9_STATE_DIR:-$HOME/.claude/projects/$proj_key/r9}"
LOG="$STATE_DIR/r9-trigger-log.tsv"
LOCAL_PHRASES="$proj/.claude/hooks/r9-phrases.local"
mkdir -p "$STATE_DIR" 2>/dev/null || true

# The pilot's name, read from team.conf as a value (never sourced).
PILOT="$(sed -n 's/^PILOT_NAME=//p' "$proj/.claude/hooks/team.conf" 2>/dev/null | head -1 | tr -cd 'A-Za-z0-9._ -')"
PILOT="${PILOT:-the pilot}"


payload="$(cat)"

if command -v jq >/dev/null 2>&1; then
  HAVE_JQ=1
  jqf() { printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null; }
else
  HAVE_JQ=0
  jqf() {  # best-effort scalar extraction; caller falls back to the raw payload
    local key="${1#.}"
    printf '%s' "$payload" | sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
  }
fi

event="$(jqf '.hook_event_name')"; event="${event:-unknown}"
session="$(jqf '.session_id')";    session="${session:-unknown}"
now="$(date -u +%FT%TZ)"
log_line() { printf '%s\t%s\t%s\t%s\n' "$now" "$session" "$1" "${2-}" >> "$LOG" 2>/dev/null || true; }

if [ "$event" = "SessionEnd" ]; then
  reason="$(jqf '.reason')"; reason="${reason:-unknown}"
  # trigger_fired counts an OPERATOR fire (MATCH or MATCH-DEGRADED); a close phrase inside a peer message
  # (MATCH-PEER) is not the operator closing, so it is excluded on purpose.
  # Counted over the current run only (the lines after the log's last SESSION-END): `claude --continue` reuses the
  # session id, so a whole-log search would let an earlier closed run mark a later unclosed one "yes".
  fired=no
  awk -F'\t' -v s="$session" '$1 !~ /^#/ { if ($3 == "SESSION-END") hit = 0; else if ($2 == s && ($3 == "MATCH" || $3 == "MATCH-DEGRADED")) hit = 1 }
    END { exit hit ? 0 : 1 }' "$LOG" 2>/dev/null && fired=yes
  log_line "SESSION-END" "reason=$reason trigger_fired=$fired"
  exit 0
fi

prompt="$(jqf '.prompt')"
# DEGRADED means "this record was produced WITHOUT jq" — the fallback parser is best-effort, and when it
# yields nothing the RAW payload is matched (over-trigger, never silence). Announced on every fire.
DEGRADED=0
if [ "$HAVE_JQ" = 0 ]; then DEGRADED=1; [ -z "$prompt" ] && prompt="$payload"; fi
suffix=""; [ "$DEGRADED" = 1 ] && suffix="-DEGRADED"

# Peer envelope: a message from another session reaches this hook as an ordinary prompt. In Claude Code
# .prompt begins "<cross-session-message "; the framing line is added outside the prompt field. The substring
# pattern is the load-bearing one — trimming it would turn a peer's close phrase into the operator's close.
PEER=0
case "$prompt" in
  "Another Claude session sent a message"*|*"<cross-session-message "*) PEER=1 ;;
esac

# Phrase floor: the phrases R9 names, then common close phrasings (English, plus one example second language).
# Deliberately absent: bare "closing", bare "for now" and bare "wrap" — they fire on ordinary prose.
CLOSE_RE="\b(wrap(-| )up|wrap (it|this|things) up|wrap (now|here)|wrap for (today|now|tonight)|wrapping up|let'?s wrap|we'?ll wrap|handover|hand over|/handover|see you (tomorrow|later|monday|next)|close (the )?session|close for (today|now|tonight)|call it (here|a day|a night|quits)|that'?s (it|all|enough) for (today|now|tonight)|that is (it|all) for (today|now)|done for (today|now|the day)|finished for (today|now)|talk (tomorrow|later)|signing off|sign off|end of session|end the session|good ?night|logging off|log off|continue (tomorrow|from home|in the morning)|pack (it )?up)\b"
CLOSE_RE_RO="\b(gata (pe|pentru) (azi|ziua)|ne vedem (maine|mâine)|pe (maine|mâine)|(inchidem|închidem)( pe azi| aici)?|am terminat( pe azi)?|asta e tot( pe azi)?|noapte (buna|bună)|la revedere|opresc(um)?( aici)?|(oprim|oprește)( aici)?)\b"

norm="$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')"
matched=0
printf '%s' "$norm" | grep -qE "$CLOSE_RE"    && matched=1
printf '%s' "$norm" | grep -qE "$CLOSE_RE_RO" && matched=1
if [ "$matched" = 0 ] && [ -r "$LOCAL_PHRASES" ]; then
  while IFS= read -r re; do
    [ -z "$re" ] && continue; case "$re" in \#*) continue;; esac
    printf '%s' "$norm" | grep -qiE "$re" && { matched=1; break; }
  done < "$LOCAL_PHRASES"
fi

if [ "$matched" = 0 ]; then
  log_line "NO-MATCH$suffix" "len=${#prompt} peer=$PEER"
  exit 0
fi

excerpt="$(printf '%s' "$prompt" | head -c 120 | tr '\n\t' '  ')"

if [ "$PEER" = 1 ]; then
  log_line "MATCH-PEER$suffix" "$excerpt"
  echo "[R9 trigger: close phrasing inside a PEER message — not the operator's turn; no wrap owed unless the operator closes. Logged as MATCH-PEER.]"
  exit 0
fi

log_line "MATCH$suffix" "$excerpt"
[ "$DEGRADED" = 1 ] && echo "[R9 trigger running DEGRADED: jq unavailable — best-effort parser, raw payload when it fails]"

marker="$STATE_DIR/.r9-fired-$session"
if [ -f "$marker" ]; then
  echo "[R9 wrap trigger — already fired this session] Close phrasing again. If not yet discharged, BOTH are still owed: /handover (the skill) AND the closing report to the pilot after a ListAgents probe."
  exit 0
fi
: > "$marker" 2>/dev/null || true

cat <<REMINDER
[R9 wrap trigger fired — session-close phrasing detected]

This is a TRIGGER, not a discharge. First judge: is this really the close? If the words matched something
else (a quote, a topic, a plan for later), say so in one line and carry on — the hook over-fires on purpose.

If it IS the close, TWO obligations are owed, in this order, and neither substitutes for the other:

  1. /handover — run the SKILL (never a hand-written block; the shape is the baseline a cold resume
     depends on). The doc carries its own trigger line, verbatim:
         Close trigger: <the operator's words> | unprompted | hook-fired-and-judged
  2. R9 closing report — run ListAgents NOW (not from memory). The report: (1) shipped/changed,
     (2) shared surfaces touched, (3) claims made this session that peers might build on, (4) open items
     handed forward, (5) trigger stated honestly (prompted / unprompted). Then:
       pilot ($PILOT) LISTED → SEND it to the pilot. Sending is not delivery: it is discharged when
                                        the pilot acknowledges; if no ack by close, note the unconfirmed
                                        send in CONTINUATION.md.
       pilot NOT listed              → RECORD the report's content as a section in CONTINUATION.md and flag
                                        it at next contact.
     CONTINUATION.md is written EVERY close by the skill — it is the handover, not a fallback. Only the
     REPORT's destination changes with the probe (sent vs recorded).

Also STATE (never backfill): the daily security sweep (R10) — last Swept instant and its age, and whether one ran this session, with the reason.
REMINDER
exit 0
