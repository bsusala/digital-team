#!/usr/bin/env bash
# Compaction nudge — SessionStart, acting only on source=compact.
#
# A long-lived session is kept alive by compaction: the older conversation is replaced by a summary, and detail
# is lost each time. Elapsed time is the wrong measure (an idle session does not decay); the number of compactions
# is the right one. From the Nth compaction of one session on, every further compaction tells the operator AND the
# session: at the next natural break, /handover and start fresh. A nudge, never a block.
#
# Count = compaction boundaries in this session's transcript (transcript_path from the payload), or the hook's own
# record of compactions it has seen, whichever is larger: the transcript also covers compactions before the hook was
# installed; the record keeps counting if the transcript format changes. Age = first transcript timestamp, else the
# first recorded compaction.
#
# The CURRENT compaction's boundary is written to the transcript after this hook runs (measured 2026-09-29: boundary
# 00:47:16.301Z, the hook's attachments 00:47:16.224Z), so the transcript count is the PRIOR compactions and this one
# is added. If the newest boundary is already within the last minute, it is this one and is not added twice. A newest
# boundary whose instant does not parse is treated as prior (the nudge errs early, never silent).
#
# Configuration: .claude/hooks/team.conf, COMPACT_NUDGE_AT=<n> (default 2), read as data, never executed.
# COMPACT_STATE_DIR and COMPACT_NOW (epoch seconds) are TEST-ONLY seams.

set -uo pipefail

proj="${CLAUDE_PROJECT_DIR:-$PWD}"
proj_key="$(printf '%s' "$proj" | tr '/' '-')"
STATE_DIR="${COMPACT_STATE_DIR:-$HOME/.claude/projects/$proj_key/compact}"
now="${COMPACT_NOW:-$(date -u +%s)}"

payload="$(cat 2>/dev/null || true)"
field() { printf '%s' "$payload" | jq -r "$1 // \"\"" 2>/dev/null || true; }
[ "$(field .source)" = "compact" ] || exit 0
session="$(field .session_id | tr -cd 'A-Za-z0-9-')"
[ -n "$session" ] || exit 0
transcript="$(field .transcript_path)"

# The value counts only when it is digits and nothing else; anything else falls back to the default.
at="$(sed -n 's/^COMPACT_NUDGE_AT=//p' "$proj/.claude/hooks/team.conf" 2>/dev/null | head -1)"
[[ "$at" =~ ^[1-9][0-9]{0,2}$ ]] || at=2

mkdir -p "$STATE_DIR" 2>/dev/null
record="$STATE_DIR/$session.log"
date -u -d "@$now" +%FT%TZ >> "$record" 2>/dev/null
seen="$(grep -c . "$record" 2>/dev/null)"; seen="${seen:-0}"

found=0; first=""
if [ -n "$transcript" ] && [ -r "$transcript" ]; then
  found="$(grep -c '"subtype":"compact_boundary"' "$transcript" 2>/dev/null)"; found="${found:-0}"
  newest="$(grep '"subtype":"compact_boundary"' "$transcript" 2>/dev/null | tail -1 \
            | grep -o '"timestamp":"[0-9]\{4\}-[0-9][0-9]-[0-9][0-9]T[0-9:.]*Z"' | head -1 | cut -d'"' -f4)"
  fresh=0
  if [[ "$newest" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
    newest_ts="$(date -u -d "$newest" +%s 2>/dev/null)" && [ $(( now - newest_ts )) -ge -5 ] && [ $(( now - newest_ts )) -le 60 ] && fresh=1
  fi
  [ "$fresh" = 1 ] || found=$(( found + 1 ))
  first="$(grep -o -m1 '"timestamp":"[0-9]\{4\}-[0-9][0-9]-[0-9][0-9]T[0-9:.]*Z"' "$transcript" 2>/dev/null | cut -d'"' -f4)"
fi
count=$(( found > seen ? found : seen ))
[ "$count" -ge "$at" ] || exit 0

[ -n "$first" ] || first="$(head -1 "$record" 2>/dev/null)"
age=""
if [[ "$first" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2} ]]; then
  start_ts="$(date -u -d "$first" +%s 2>/dev/null)" && {
    h=$(( (now - start_ts) / 3600 ))
    if [ "$h" -ge 48 ]; then age=" over $(( h / 24 )) days"; else age=" over ${h}h"; fi
  }
fi

msg="Compaction: this conversation has now been compacted $count times$age, and each compaction replaces older detail with a summary. At the next natural break, /handover and start a fresh session; the handover carries the work across. (Tell the operator this once, in one line.)"
jq -nc --arg m "$msg" '{systemMessage: $m, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $m}}'
exit 0
