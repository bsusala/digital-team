#!/usr/bin/env bash
# Unclosed-session warning — at SessionStart, warns when the previous run ended without a close. Charter: RULES.md
# R9(d). Reads the log that r9-wrap-trigger.sh writes; wire it on SessionStart.
#
# The previous RUN is judged, not the previous session id: `claude --continue` keeps the id, so a check keyed on
# "the last id other than mine" would skip the run that just ended. At SessionStart this run has logged nothing yet,
# so the log's last SESSION-END (any id) ends the previous run; a last line that is not a SESSION-END is a run that
# died. The run counts as closed only if a close phrase was matched inside it. A SESSION-END with reason=clear is a
# deliberate act and stays silent.
#
# When it warns, it adds one piece of evidence: the latest commit touching docs/CONTINUATION.md inside that run's
# window (+15 min), or "no handover commit in its window". The verdict does not depend on it — a session can commit
# its handover, keep working and die.
# Known over-warn, stated in the line: a restart without a close phrase warns too; the reader judges.
# R9_STATE_DIR and R9_NOW (epoch seconds) are TEST-ONLY seams.
set -uo pipefail

proj="${CLAUDE_PROJECT_DIR:-$PWD}"
proj_key="$(printf '%s' "$proj" | tr '/' '-')"
LOG="${R9_STATE_DIR:-$HOME/.claude/projects/$proj_key/r9}/r9-trigger-log.tsv"
now="${R9_NOW:-$(date -u +%s)}"

payload="$(cat 2>/dev/null || true)"
current="$(printf '%s' "$payload" | jq -r '.session_id // ""' 2>/dev/null || true)"
# A compaction restarts the context inside a run that has not ended: there is no previous run to judge.
[ "$(printf '%s' "$payload" | jq -r '.source // ""' 2>/dev/null || true)" = "compact" ] && exit 0

[ -f "$LOG" ] || exit 0

# The previous run = the most recent run that took at least one prompt. A run is one session id's lines up to that
# id's own SESSION-END; another id's SESSION-END interleaved in the log does not end it. A run with no prompt line is
# skipped: the background service's pre-started sessions log a bare SESSION-END when they shut down, and judging one
# of those names a session nobody used. Fields out: id <TAB> first instant <TAB> last instant <TAB> closed <TAB>
# "END" + detail, or "OPEN" when the run never logged a SESSION-END (it died, or is still running elsewhere).
run="$(awk -F'\t' '$1 !~ /^#/ && $2 != "" {
    i++; id = $2
    if ($3 != "SESSION-END") {
      if (!(id in open)) { open[id] = 1; first[id] = $1; shut[id] = "no" }
      last[id] = $1; pos[id] = i
      if ($3 == "MATCH" || $3 == "MATCH-DEGRADED") shut[id] = "yes"
    } else if (id in open) {
      best = sprintf("%s\t%s\t%s\t%s\tEND\t%s", id, first[id], $1, shut[id], $4); bestpos = i
      delete open[id]
    }
  }
  END {
    for (id in open) if (pos[id] > bestpos) {
      best = sprintf("%s\t%s\t%s\t%s\tOPEN", id, first[id], last[id], shut[id]); bestpos = pos[id]
    }
    if (best != "") printf "%s", best
  }' "$LOG")"
[ -n "$run" ] || exit 0
IFS=$'\t' read -r prev first_seen last_seen closed state detail <<< "$run"
end=""; [ "$state" = "END" ] && end="$last_seen	$detail"
[ "$prev" = "$current" ] && prev="$prev (this session's previous run, continued)"

ISO='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z$'
# evidence <window-end instant>: one sentence about CONTINUATION.md commits in [first_seen, end + 15 min], or nothing.
evidence() {
  local stop="$1" stop_ts line
  [[ "$first_seen" =~ $ISO ]] && [[ "$stop" =~ $ISO ]] || return 0
  git -C "$proj" rev-parse --git-dir >/dev/null 2>&1 || return 0
  [ -n "$(git -C "$proj" log -1 --format=%h -- docs/CONTINUATION.md 2>/dev/null)" ] || return 0
  stop_ts="$(date -u -d "$stop" +%s 2>/dev/null)" || return 0
  line="$(TZ=UTC git -C "$proj" log -1 --since="$first_seen" --until="@$(( stop_ts + 900 ))" \
            --date=format-local:%FT%TZ --format='%cd %h' -- docs/CONTINUATION.md 2>/dev/null)"
  if [ -n "$line" ]; then printf ' Handover committed at %s (%s).' "${line%% *}" "${line##* }"
  else printf ' No handover commit in its window.'; fi
}

[ "$state" = "END" ] && [ "$closed" = "yes" ] && exit 0

case "$end" in
  *reason=clear*) exit 0 ;;
  "")
    live=""
    seen_ts=0
    [[ "$last_seen" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z$ ]] && seen_ts="$(date -u -d "$last_seen" +%s 2>/dev/null || echo 0)"
    [ $(( now - seen_ts )) -lt 900 ] && live=" It was active under 15 minutes ago — it may still be running in another terminal."
    msg="R9: previous session $prev has NO SESSION-END record (last logged $last_seen) — it died or was killed without a close.$live$(evidence "$last_seen") Its decisions may exist only in auto-memory; check memory against docs/ISSUES.md and git before building on CONTINUATION.md." ;;
  *) msg="R9: previous session $prev ended WITHOUT a close (${end//	/ }).$(evidence "${end%%	*}") No close phrase is on record for it (a restart without a close phrase also reads this way); check memory against docs/ISSUES.md and git before building on CONTINUATION.md." ;;
esac

jq -nc --arg m "$msg" '{systemMessage: $m, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $m}}'
exit 0
