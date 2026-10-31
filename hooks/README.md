# Team hooks

Five Claude Code hooks that turn the charter's session rules from memory into mechanism. Prose reminders
fail at exactly the moment they exist for, so the moment is wired instead.

| Hook | Rule | What it does |
|---|---|---|
| `r9-wrap-trigger.sh` | R9 | When the operator's words look like a close, reminds the session of the two things a close owes (the handover and the closing report). Logs how every session ended. |
| `due-check.sh` | R20 | Tells the session and the operator when a periodic obligation (a security sweep, housekeeping) is due — at session start, at every prompt, and at the end of every turn. |
| `r9-unclosed-warn.sh` | R9(d) | At session start, warns when the previous run ended without a close, so decisions that exist only in memory are looked for before building on the handover. |
| `compact-nudge.sh` | R9 | When a long-lived conversation has been compacted (its older part replaced by a summary) for the second time or more, tells the operator and the session: at the next natural break, `/handover` and start fresh. The count, not the clock: an idle session does not decay, a compacted one loses detail each time. |
| `duplicate-session-guard.sh` | — | At session start, when another interactive Claude Code session is already live in the same project, tells the operator (desktop notice and system message) and tells the new session to stay read-only until the operator says which one works here. Two sessions in one folder share the working tree, the git index and the memory, and nothing else warns. |

None of them blocks anything. A hook is a trigger, not an implementation: the session still does the work.

One tool ships beside the hooks. It is installed in the same folder but wired to no event; `/housekeeping` runs it:

| Tool | Used by | What it does |
|---|---|---|
| `housekeeping-reask.sh` | `/housekeeping`, step 2 | Lists passed re-ask dates (`DUE`), trigger-gated re-checks with no date (`TRIGGER`) and dates beside a trigger word outside the current disposition line (`STRAY`), reading each entry's current disposition only. |

## Install, per department

In a terminal, in the department's folder (here marketing), with this repository cloned in your home folder as
in the README. Go into the department's folder:

```bash
cd ~/Company/marketing
```

Make the folder for its hooks:

```bash
mkdir -p .claude/hooks
```

Copy the five hooks:

```bash
cp ~/digital-team/hooks/r9-wrap-trigger.sh ~/digital-team/hooks/due-check.sh ~/digital-team/hooks/r9-unclosed-warn.sh ~/digital-team/hooks/compact-nudge.sh ~/digital-team/hooks/duplicate-session-guard.sh .claude/hooks/
```

Copy the housekeeping surfacer:

```bash
cp ~/digital-team/hooks/housekeeping-reask.sh .claude/hooks/
```

Copy the five self-tests:

```bash
cp ~/digital-team/hooks/r9-trigger-selftest.sh ~/digital-team/hooks/d2d3-selftest.sh ~/digital-team/hooks/compact-selftest.sh ~/digital-team/hooks/duplicate-session-guard-selftest.sh ~/digital-team/hooks/housekeeping-selftest.sh .claude/hooks/
```

Make them runnable:

```bash
chmod +x .claude/hooks/*.sh
```

Then merge `settings-hooks.json` into the department folder's `.claude/settings.json` (all four events; the scripts
are wired more than once on purpose; the surfacer is not wired at all). Keep `duplicate-session-guard.sh` first in
SessionStart, so its warning arrives before anything that writes. If your SessionStart already has an entry with a `matcher` such as
`startup|resume|clear`, put `compact-nudge.sh` in an entry without one: a compaction arrives as `source=compact`, and
a matcher that leaves it out means the nudge never runs. Optionally:

- `.claude/hooks/team.conf` — copy `team.conf.example` and set `PILOT_NAME` if you run a team,
  `COMPACT_NUDGE_AT` if the second compaction is too early or too late for you, and `HOUSEKEEPING_STAMP` if the
  housekeeping stamp is not `docs/.housekeeping` (read by `scripts/backburner-delta.sh`).
- `.claude/hooks/due-stamps.local` — copy `due-stamps.local.example` and list your own periodic
  obligations. Each routine writes its own stamp when it completes a full run. A Housekeeping line here is what
  lets `/housekeeping` start by itself when it is due. The stamps themselves live in the lane's own files, never
  inside a `.claude/` folder: Claude Code re-reviews every write there, and can refuse one even after a yes.
- `.claude/hooks/r9-phrases.local` — the close phrasing your operator actually uses, one extended regex
  per line. Grow it from real words, not imagined ones.

## Before trusting them

Run the five self-tests from the installed directory and check the counts, not the colour:

```bash
# expect 39 passed, 0 failed
bash .claude/hooks/r9-trigger-selftest.sh .claude/hooks/r9-wrap-trigger.sh

# expect 47 passed, 0 failed
bash .claude/hooks/d2d3-selftest.sh .claude/hooks

# expect 24 passed, 0 failed
bash .claude/hooks/compact-selftest.sh .claude/hooks

# expect 13 passed, 0 failed
bash .claude/hooks/duplicate-session-guard-selftest.sh

# expect 55 passed / 0 failed / 55 expected
HOOKS_DIR=.claude/hooks bash .claude/hooks/housekeeping-selftest.sh
```

The housekeeping self-test also reads every script in `HOOKS_DIR` for a stamp parsed with `date -d` and no shape
check first; it fails, rather than skipping, when `HOOKS_DIR` is unset or wrong.

A test's green counts only after its failure path has been made to fire: every suite includes cases that
must fail when the hook is wrong. A suite that reports fewer assertions than expected is incomplete, not
passing.

## Requirements

`bash`, `jq`, `git`, GNU `date`, `awk`. Without `jq` the R9 trigger degrades to over-triggering and says so. The
duplicate-session guard reads process working directories from `/proc` (Linux) and sends its desktop notice with
`notify-send` where it exists; without `jq` its warning is still printed. It recognises a session by a process
named `claude`, which is what the native installer runs; an installation that runs Claude Code under `node` (an npm
install, for example) leaves it unable to find its own session, and it says so at every start instead of checking.

## What they write

State lives under Claude Code's own project directory, `~/.claude/projects/<project-key>/`: the R9 log in
`r9/`, the due-check's once-per-crossing markers in `due/`, the compactions each session has seen in `compact/`. Nothing is written into the repository. The duplicate-session guard writes nothing: the process table is its record. The surfacer only reads.
