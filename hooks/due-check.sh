#!/usr/bin/env bash
# Due-check — tells the session and the operator when a periodic obligation is due. Charter: RULES.md R20.
# Runs at SessionStart, UserPromptSubmit and Stop. Wire all three (settings-hooks.json).
#
# Stamps are listed in .claude/hooks/due-stamps.local, one per line, tab-separated:
#     <label> <TAB> <stamp path, ~ allowed> <TAB> <period in hours> [<TAB> <anchor ERE>]
# The stamp is the latest UTC instant (YYYY-MM-DDTHH:MM[:SS]Z) in the file — with an anchor, only in lines matching
# it, so a stamp kept inside a log names the line that records the event (e.g. `^Swept:`). A date-only stamp is read
# as T00:00Z, the earliest the date allows, and flagged as legacy. Due = now - stamp >= period: elapsed time only.
#
# States: current (silent) · DUE · NEVER (no file) · INDETERMINATE (neither an instant nor a date). SessionStart
# reports every non-current stamp, and a missing config. The other doors report each crossing once, then at most
# once a day — a `claude --continue` session keeps its id for days, so "once per session" would mean "once".
# Never blocks a turn. Reaches the operator through systemMessage and the session through additionalContext.
# DUE_NOW (epoch seconds) and DUE_STATE_DIR are TEST-ONLY seams.
set -uo pipefail

proj="${CLAUDE_PROJECT_DIR:-$PWD}"
proj_key="$(printf '%s' "$proj" | tr '/' '-')"
STATE_DIR="${DUE_STATE_DIR:-$HOME/.claude/projects/$proj_key/due}"
CONF="$proj/.claude/hooks/due-stamps.local"
now="${DUE_NOW:-$(date -u +%s)}"

payload="$(cat 2>/dev/null || true)"
event="$(printf '%s' "$payload" | jq -r '.hook_event_name // "unknown"' 2>/dev/null || echo unknown)"
session="$(printf '%s' "$payload" | jq -r '.session_id // "unknown"' 2>/dev/null || echo unknown)"

emit() {  # $1 = message
  if [ "$event" = "SessionStart" ]; then
    jq -nc --arg m "$1" '{systemMessage: $m, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $m}}'
  elif [ "$event" = "UserPromptSubmit" ]; then
    jq -nc --arg m "$1" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $m}}'
  else
    jq -nc --arg m "$1" '{systemMessage: $m}'
  fi
}

if [ ! -r "$CONF" ]; then
  [ "$event" = "SessionStart" ] && emit "Due-check: no .claude/hooks/due-stamps.local in this lane — nothing is checked (not a pass)."
  exit 0
fi

mkdir -p "$STATE_DIR" 2>/dev/null || true
lines=()
while IFS=$'\t' read -r label path hours anchor || [ -n "${label:-}" ]; do
  [ -z "${label:-}" ] && continue
  case "$label" in \#*) continue ;; esac
  path="${path/#\~/$HOME}"
  if ! [[ "${hours:-}" =~ ^[0-9]+$ ]]; then lines+=("$label: INDETERMINATE — period '${hours:-}' is not a whole number of hours"); continue; fi
  if [ ! -e "$path" ]; then key="never"; msg="$label: NEVER — no stamp at $path"
  else
    inst="$(grep -E -- "${anchor:-.}" "$path" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z' | sort | tail -1)"
    legacy=""
    if [ -z "$inst" ]; then
      d="$(grep -E -- "${anchor:-.}" "$path" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort | tail -1)"
      [ -n "$d" ] && { inst="${d}T00:00Z"; legacy=" (legacy date-only stamp, read as T00:00Z)"; }
    fi
    if [ -z "$inst" ]; then key="indeterminate"; msg="$label: INDETERMINATE — no UTC instant or date in $path"
    else
      ts=""
      [[ "$inst" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z$ ]] && ts="$(date -u -d "$inst" +%s 2>/dev/null || echo)"
      if [ -z "$ts" ]; then key="indeterminate"; msg="$label: INDETERMINATE — cannot read instant $inst"
      else
        age=$(( now - ts ))
        [ "$age" -lt $(( hours * 3600 )) ] && continue
        key="$inst"; msg="$label: DUE — last $inst, age $(( age / 3600 ))h$(( age % 3600 / 60 ))m (period ${hours}h)$legacy"
      fi
    fi
  fi
  if [ "$event" != "SessionStart" ]; then
    marker="$STATE_DIR/.said-$event-$session-$(printf '%s|%s' "$label" "$key" | cksum | cut -d' ' -f1)"
    # Once per crossing per door; the marker expires after 24 h (see header).
    said="$(cat "$marker" 2>/dev/null)"
    [[ "$said" =~ ^[0-9]+$ ]] && [ $(( now - said )) -lt 86400 ] && continue
    printf '%s' "$now" > "$marker" 2>/dev/null || true
  fi
  lines+=("$msg")
done < "$CONF"

[ "${#lines[@]}" -eq 0 ] && exit 0
out="Due-check ($event):"
for l in "${lines[@]}"; do out="$out $l."; done
emit "$out"
exit 0
