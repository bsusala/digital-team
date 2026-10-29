#!/usr/bin/env bash
# Duplicate-session guard — wire on SessionStart.
#
# Two Claude Code sessions in one project share the working tree, the git index, auto-memory and the peer-message
# name, and nothing warns. This hook looks for ANOTHER live interactive `claude` process whose working directory is
# this project (or below it). If one exists, it tells the operator (desktop notice + system message) and tells the
# new session to stay read-only until the operator says which session works here.
#
# Stateless by design: the process table is the record. A process's cwd is the directory it was started in (Claude
# Code does not chdir), so no lock file is written and no stale lock can outlive a dead session.
# Own process = the nearest ancestor whose comm is `claude`; if none is found the check cannot tell itself from a
# peer, and says so instead of staying silent.
# Interactive = has a controlling terminal; a tty-less `claude` (a browser native host, a background session) is not
# a working session and is not counted.
# A git worktree has its own path, so a deliberate second session in a worktree is not a duplicate.
# Linux only: the working directory is read from /proc. The desktop notice uses notify-send where it exists.
#
# DUP_FIXTURE (file of "pid<TAB>tty<TAB>cwd" lines), DUP_SELF_PID and DUP_NOTIFY_CMD are TEST-ONLY seams.

set -uo pipefail

proj="${CLAUDE_PROJECT_DIR:-$PWD}"
proj="${proj%/}"
payload="$(cat 2>/dev/null || true)"

self="${DUP_SELF_PID:-}"
if [ -z "$self" ]; then
  p=$$
  while [ "${p:-0}" -gt 1 ]; do
    if [ "$(ps -o comm= -p "$p" 2>/dev/null)" = "claude" ]; then self="$p"; break; fi
    p="$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')"
  done
fi

# Without jq the message is built by hand, so a missing jq never turns the warning into silence.
emit() {
  if command -v jq >/dev/null 2>&1; then
    jq -nc --arg m "$1" '{systemMessage: $m, hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $m}}'
  else
    local m; m="$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
    printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$m" "$m"
  fi
}

if ! [[ "$self" =~ ^[0-9]+$ ]]; then
  emit "Duplicate-session guard: could not identify this session's own claude process, so the check did NOT run. Run \`pgrep -a -x claude\` to see whether another session is live in $proj."
  exit 0
fi

# One line per claude process: pid, tty, cwd.
list_processes() {
  if [ -n "${DUP_FIXTURE:-}" ]; then cat "$DUP_FIXTURE"; return; fi
  local pid tty cwd
  for pid in $(pgrep -x claude 2>/dev/null); do
    tty="$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')"
    cwd="$(readlink "/proc/$pid/cwd" 2>/dev/null)" || continue
    printf '%s\t%s\t%s\n' "$pid" "$tty" "$cwd"
  done
}

peers=""
# Fields are split by hand: tab is IFS whitespace, so `read` would collapse an empty field and shift the line.
# An empty tty is an unknown, never a reading.
while IFS= read -r line; do
  pid="${line%%$'\t'*}"; rest="${line#*$'\t'}"; tty="${rest%%$'\t'*}"; cwd="${rest#*$'\t'}"
  [ "$rest" != "$line" ] && [ "$cwd" != "$rest" ] || continue
  [[ "$pid" =~ ^[0-9]+$ ]] || continue
  [ "$pid" = "$self" ] && continue
  cwd="${cwd%/}"
  [ "$cwd" = "$proj" ] || [[ "$cwd" == "$proj/"* ]] || continue
  if [ -z "$tty" ] || [ "$tty" = "?" ]; then continue; fi
  started=""
  age="$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')"
  [[ "$age" =~ ^[0-9]+$ ]] && started="$(date -u -d "@$(( $(date -u +%s) - age ))" +%FT%H:%MZ)"
  peers+="${peers:+; }pid $pid on $tty${started:+, started $started}"
done < <(list_processes)

[ -n "$peers" ] || exit 0

name="$(basename "$proj")"
msg="DUPLICATE SESSION in $name: another Claude Code session is already live here ($peers). Two sessions share the working tree, git index, auto-memory and the peer-message name. THIS session stays READ-ONLY — no edits, commits, pushes, memory writes or peer sends — until the operator says which session works here; say so in your first reply."

: "${DBUS_SESSION_BUS_ADDRESS:=unix:path=/run/user/$(id -u)/bus}"
export DBUS_SESSION_BUS_ADDRESS
if [ -n "${DUP_NOTIFY_CMD:-}" ]; then
  $DUP_NOTIFY_CMD "Claude Code: duplicate session" "$name: a second session started while one is live ($peers)." >/dev/null 2>&1 || true
else
  timeout 5 notify-send -u critical -a "Claude Code" "Claude Code: duplicate session" \
    "$name: a second session started while one is live ($peers)." >/dev/null 2>&1 || true
fi

emit "$msg"
exit 0
