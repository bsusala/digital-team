# Team hooks

Four Claude Code hooks that turn the charter's session rules from memory into mechanism. Prose reminders
fail at exactly the moment they exist for, so the moment is wired instead.

| Hook | Rule | What it does |
|---|---|---|
| `r9-wrap-trigger.sh` | R9 | When the operator's words look like a close, reminds the session of the two things a close owes (the handover and the closing report). Logs how every session ended. |
| `due-check.sh` | R20 | Tells the session and the operator when a periodic obligation (a security sweep, housekeeping) is due — at session start, at every prompt, and at the end of every turn. |
| `r9-unclosed-warn.sh` | R9(d) | At session start, warns when the previous run ended without a close, so decisions that exist only in memory are looked for before building on the handover. |
| `compact-nudge.sh` | R9 | When a long-lived conversation has been compacted (its older part replaced by a summary) for the second time or more, tells the operator and the session: at the next natural break, `/handover` and start fresh. The count, not the clock: an idle session does not decay, a compacted one loses detail each time. |

None of them blocks anything. A hook is a trigger, not an implementation: the session still does the work.

## Install, per department

```bash
mkdir -p .claude/hooks
cp hooks/r9-wrap-trigger.sh hooks/due-check.sh hooks/r9-unclosed-warn.sh hooks/compact-nudge.sh .claude/hooks/
cp hooks/r9-trigger-selftest.sh hooks/d2d3-selftest.sh hooks/compact-selftest.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
```

Then merge `settings-hooks.json` into the department folder's `.claude/settings.json` (all four events; the scripts
are wired more than once on purpose). Optionally:

- `.claude/hooks/team.conf` — copy `team.conf.example` and set `PILOT_NAME` if you run a team, and
  `COMPACT_NUDGE_AT` if the second compaction is too early or too late for you.
- `.claude/hooks/due-stamps.local` — copy `due-stamps.local.example` and list your own periodic
  obligations. Each routine writes its own stamp when it completes a full run.
- `.claude/hooks/r9-phrases.local` — the close phrasing your operator actually uses, one extended regex
  per line. Grow it from real words, not imagined ones.

## Before trusting them

Run the three self-tests from the installed directory and check the counts, not the colour:

```bash
bash .claude/hooks/r9-trigger-selftest.sh .claude/hooks/r9-wrap-trigger.sh   # expect 39 passed, 0 failed
bash .claude/hooks/d2d3-selftest.sh .claude/hooks                             # expect 47 passed, 0 failed
bash .claude/hooks/compact-selftest.sh .claude/hooks                          # expect 20 passed, 0 failed
```

A test's green counts only after its failure path has been made to fire: every suite includes cases that
must fail when the hook is wrong. A suite that reports fewer assertions than expected is incomplete, not
passing.

## Requirements

`bash`, `jq`, `git`, GNU `date`. Without `jq` the R9 trigger degrades to over-triggering and says so.

## What they write

State lives under Claude Code's own project directory, `~/.claude/projects/<project-key>/`: the R9 log in
`r9/`, the due-check's once-per-crossing markers in `due/`, the compactions each session has seen in `compact/`. Nothing is written into the repository.
