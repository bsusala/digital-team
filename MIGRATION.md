# Migrating

How to move to a newer release, what each step changes on your computer, and how to go back.

- [What an upgrade changes](#what-an-upgrade-changes) — in plain words, before any command.
- [Before any upgrade](#before-any-upgrade) — three steps that make every later one undoable.
- [Updating the commands](#updating-the-commands) · [Updating a department's hooks](#updating-a-departments-hooks)
- [From v3.2 to v3.3](#from-v32-to-v33) — one new command.
- [From v3.1 to v3.2](#from-v31-to-v32) — tools and templates only; the charter is unchanged.
- [From v2 to v3](#from-v2-to-v3) — the charter itself.
- [Refreshing a setup that got mixed up](#refreshing-a-setup-that-got-mixed-up) — the latest release again, your work kept.
- [Going back](#going-back)

You do not have to type any of this yourself. In a department's session, ask Claude to take you through the
section you need: it does one step at a time, says what the step changes, and does it on your yes.

## What an upgrade changes

Nothing here runs by itself and there is no installer: every step is a command you type, or one Claude types in
a session on your yes. An upgrade touches only these five things:

| What | Where it lives | What an upgrade does to it | How you get the old one back |
|---|---|---|---|
| The commands (`/bootstrap`, `/resume`, `/handover`, `/housekeeping`, `/capture`) | `~/.claude/commands/`, shared by every folder on the computer, and not in git | Replaces each file with the new release's | The copy you make before upgrading |
| A department's hooks | `.claude/hooks/` in the department's folder | Replaces the files the release names, after you compare them | git |
| A department's settings | `.claude/settings.json` | Adds the new release's entries beside yours; yours stay | git |
| The team block and working agreement | the department's `CLAUDE.md` | Adds the lines the new template has; yours stay | git |
| The charter (`RULES.md`) | the team-state repository, only if you run a team | Adds the new version beside the old; a department follows it only on your word in that department | git, and the old pin stays on record |

**Never touched:** the department's own files and work, its tracker and logs (v3.2 moves them to another folder,
unchanged), the procedures `/capture` saved, its git history, what Claude Code remembers about the folder, and
your sign-in and Claude Code settings.

**One department, no team?** Only the commands apply to you. The hooks, the team block and the charter are
Stage 2 of [`SETUP.md`](SETUP.md).

## Before any upgrade

1. **Get the new release.** Update the download:

   ```bash
   git -C ~/digital-team pull
   ```

   If it says you are not on a branch (after [Going back](#going-back), say), first return to the latest:

   ```bash
   git -C ~/digital-team checkout main
   ```

   See which release you now have:

   ```bash
   git -C ~/digital-team describe --tags
   ```

2. **Commit every department.** In each department's folder, this should say `nothing to commit`:

   ```bash
   git status
   ```

   If it lists files, commit them first, or ask the session to. Everything git holds can be put back.

3. **Copy your commands.** They are not in git, so this copy is the only way back for them:

   ```bash
   cp -r ~/.claude/commands ~/.claude/commands-backup-$(date +%F)
   ```

Then read the section of every release between yours and the new one, oldest first.

## Updating the commands

See which commands differ from the new release:

```bash
diff -rq ~/digital-team/commands ~/.claude/commands
```

How to read the answer:

- `Files … differ` — that command changed in the release, or you edited your copy.
- `Only in …/digital-team/commands` — a command new in this release.
- `Only in …/.claude/commands` — one of your own. The upgrade leaves it alone.

To see what changed in one command, here `/resume`:

```bash
diff ~/.claude/commands/resume.md ~/digital-team/commands/resume.md
```

**If one of your own commands has the same name as one of ours** (your own `/resume`, say), rename yours first,
or the copy below replaces it. Here it becomes `/my-resume`:

```bash
mv ~/.claude/commands/resume.md ~/.claude/commands/my-resume.md
```

Copy the new release's commands:

```bash
cp ~/digital-team/commands/*.md ~/.claude/commands/
```

If you had edited one of ours, your version is in the backup folder from [Before any upgrade](#before-any-upgrade).
Carry your change over by hand, or ask Claude to compare the two and carry it over.

## Updating a department's hooks

In the department's folder, after [Before any upgrade](#before-any-upgrade). Compare each hook the release
section names before copying it, here the due-check:

```bash
diff .claude/hooks/due-check.sh ~/digital-team/hooks/due-check.sh
```

No output means it is already the same. If the department runs its own version of a hook, keep the difference
you need: two versions of the same hook reading the same log can disagree. Copy the hooks the release names,
make them runnable, and run the self-tests the release names: check the pass and fail counts, not the colour.
Then commit.

---

## From v3.2 to v3.3

`RULES.md` is unchanged. **What this changes on your computer:** one new file, `~/.claude/commands/capture.md`.
Nothing in any department changes.

```bash
cp -i ~/digital-team/commands/capture.md ~/.claude/commands/
```

v3.3.1 changes only the instructions (this file, the README, `SETUP.md`, `hooks/README.md`): nothing to install.

## From v3.1 to v3.2

`RULES.md` is byte-identical to v3.1, so no pin moves and nothing is ratified again. What changed is the
tooling around it.

**What this changes on your computer:**

- **Commands:** `/bootstrap` and `/housekeeping` are replaced ([Updating the commands](#updating-the-commands)).
  With one department and no team, that is all.
- **Each department in a team:** two hooks and one script are added, and none replaced; `.claude/settings.json`
  gains one SessionStart entry; the team block in `CLAUDE.md` gains three bullets and a line; the tracker, the
  security log and the stamps move out of any `.claude/` folder, contents unchanged; `due-stamps.local` gains a
  Housekeeping line.
- **The charter:** nothing.

### What changed

**New hooks and scripts**

| File | What it does | Self-test |
|---|---|---|
| `hooks/duplicate-session-guard.sh` | At session start, warns when another interactive session is already live in the same project, and tells the new one to stay read-only until the operator names the working session. Wired first on SessionStart. | `duplicate-session-guard-selftest.sh` — 13 passed, 0 failed |
| `hooks/housekeeping-reask.sh` | The `/housekeeping` step-2 surfacer: passed re-ask dates (`DUE`), undated trigger-gated re-checks (`TRIGGER`), dates outside the current disposition line (`STRAY`). Not wired to an event. | `HOOKS_DIR=.claude/hooks housekeeping-selftest.sh` — 55 passed / 0 failed / 55 expected |
| `scripts/backburner-delta.sh` | Lists the Open and Parked entries a commit cited, or whose named files changed, since the last housekeeping pass. | `--selftest` — 26 passed / 0 failed |

**Changed**

- **`/housekeeping`** starts by itself once the lane's due-check reports it DUE or NEVER — after the request in
  hand, never inside a task, sweep first, never on a broken stamp or in a session told to stay read-only — and
  starting unasked changes nothing inside the run. A disposition's token is the first whole upper-case word
  from the closed set in the line's body. Its report numbers everything awaiting the operator.
- **Team block** (`templates/CLAUDE-team-block.md`) gains three bullets and a line: lane records live
  outside every `.claude/` folder (with a "Lane records at:" line to fill in); a hold stops lane work, never the daily sweep or
  housekeeping; everything awaiting the operator is one numbered list per message.
- **Tracker template** (`templates/ISSUES.md`, and the copy `/bootstrap` writes): verify an entry is still open
  before working it; close what else a fix resolved in the same commit; notify a lane whose entry a shared fix
  may resolve; start a backlog review from `backburner-delta.sh`.
- **`SETUP.md`** gains 2.9, carrying each lane's work to the backup and reading it back, and 2.10, how a lane
  installs an update to a shared team script.
- `hooks/settings-hooks.json` and `hooks/team.conf.example` (`HOUSEKEEPING_STAMP`) follow.

### How to install, lane by lane

1. **Pilot:** copy the new and changed files into the team-state repository's `hooks/` and `scripts/`, commit,
   and record the commit.
2. **Each lane, on the operator's word in that lane** (these are hooks and settings, so the script-update route
   in `SETUP.md` 2.10 does not apply): if the lane already has a file of the same name, compare it first
   ([Updating a department's hooks](#updating-a-departments-hooks)); install from the named commit, merge the
   new SessionStart entry into `.claude/settings.json` with the guard first, and run all five hook self-tests plus
   `bash scripts/backburner-delta.sh --selftest`. Check the counts, not the colour.
3. **Each lane: move its records out of any `.claude/` folder**, if any are there — tracker, security log,
   stamps — repoint `due-stamps.local` and `team.conf`, commit, carry and read back. Fill in the
   "Lane records at:" line of the team block.
4. **Each lane: add a Housekeeping line to `due-stamps.local`** if it has none; without one, `/housekeeping`
   never starts by itself.
5. **Each lane: update the team block and the working agreement** from the templates: compare the template with
   the lane's current block, add the lines the template adds, and keep the lane's own. Record the change in the
   pilot's log with the self-test counts.

---

## From v2 to v3

For a team already running the v2 charter (tags `v2` / `v2.1`). A fresh team starts from `SETUP.md` instead.

**What this changes on your computer:** the team-state repository gains the v3 charter beside v2; each lane's
`CLAUDE.md` gets a new pin line, with the old one kept beside it; each lane gains hooks in `.claude/hooks/` and
their entries in `.claude/settings.json`; the commands gain `/bootstrap` and `/housekeeping`. Nothing is
removed.

### What changed

**New rules**

| Rule | In one line |
|---|---|
| R18 — An ask is a page, not a trail | A decision request is four lines: ASK · FOR/AGAINST · RECOMMEND · IF SILENT. |
| R19 — Pin movement | A lane's pin on the charter moves only on the operator's word in that lane, after the change is read and found additive, keeping the old pin. |
| R20 — Due is elapsed time | Every periodic obligation is due by elapsed time since the last completed run, never by the calendar; stamps are UTC instants generated in the command; inputs are validated by shape; the check runs at every turn. |
| R21 — Who pays for the default | Default off when the cost of being wrong falls on the system, on when it falls on the operator. |
| R22 — Read the channel | An answer is only as good as the channel it was read through; only the verdict crosses the output channel, never the evidence. |
| R23 — Slug and section | Citing a clause and locating it are different operations; where a claim and an instrument disagree about an artefact, the artefact decides. |

**New sections**

- **The verification clauses** — fire both directions, state the meaning, read the artefact, report the
  coverage, label the instant, name the decay — and the test that separates them (two remedies are one only if
  performing one necessarily discharges the other).
- **The channel** — addressing, receiving and recording between sessions.
- **When the charter is done being written** — the settling test, and the freeze.

**Changed rules**

- **R9(d)** — a close owes two things, the handover and the closing report, and neither substitutes for the
  other. The next session is warned when the previous one ended without a close.
- **R10(n)** — every finding carries a disposition from a closed list (FIXED · TRACKED · ESCALATED · ACCEPTED ·
  BLOCKED), with an owner, an evidence class, and what it silences until when. Relays are receipted on both
  ends; age is wall-clock.

**New tools**

- `/bootstrap` and `/housekeeping` beside `/handover` and `/resume`.
- `hooks/` — the R9 wrap trigger, the due-check, the unclosed-session warning and the compaction nudge, with self-tests.
- `templates/` — the issue tracker, the CLAUDE.md team block, the team log.

### How to migrate, lane by lane

The charter is ratified per lane, so migration is too. The pilot can prepare everything; only the operator's
word in each lane moves that lane.

1. **Pilot: add v3 to the team-state repository.** Copy `RULES.md` from this repository's `v3` tag, commit,
   and record the new commit and its sha256.
2. **Each lane: read the difference, not a summary.** `git -C <team-state dir> diff <old pin> <new pin> --
   RULES.md`. From `v2.1`, v3 is additive: the only lines removed are the status paragraph (now "settled and
   frozen") and "No candidate rules are pending". R9 and R10 gain limbs; nothing in them is taken away. Check
   that by reading the removed lines, not by counting them.
3. **Each lane: move the pin, on the operator's word in that session.** Update the lane's team block in
   `CLAUDE.md` with the new commit and digest, and keep the old pin on record beside it.
4. **Each lane: install the hooks** from `hooks/` and run the three self-tests (39/0, 47/0 and 24/0). If the lane
   already runs its own versions, compare them against these first — two readers of the same log can
   disagree.
5. **Each lane: ratify what is new, in the operator's words.** One act can cover the whole v3 text; a lane may
   also adopt rule by rule, or narrow a rule, and says so outward.
6. **Pilot: record each lane's move in the log** — lane, old and new pin, self-test counts, the operator's
   words.

### After migrating

- **The charter is frozen at v3.** New rules wait for a newly declared review; between reviews the text
  changes only by correction. Keep corrections in a separate errata file beside `RULES.md`, so that every
  lane's pin stays current, and fold them in at the next review.
- **Keep the old pins.** A lane's history of pins is how a later reader tells which rules bound it when.

---

## Refreshing a setup that got mixed up

For when the commands or the hooks no longer behave as they should — edited by hand, half-updated, copied from
two releases — and you want the latest release again, without losing any work. It changes only the five things
in [What an upgrade changes](#what-an-upgrade-changes), and never the list under **Never touched**.

1. [Before any upgrade](#before-any-upgrade), all three steps.
2. **The commands:** do [Updating the commands](#updating-the-commands), and copy every command, even those that
   do not differ.
3. **Each department in a team:** compare and copy every hook in [`hooks/README.md`](hooks/README.md), run all
   the self-tests, compare `.claude/settings.json` with `hooks/settings-hooks.json` and add what is missing,
   compare the team block with `templates/CLAUDE-team-block.md`. Commit.
4. **The charter:** check each department's pin against the team-state repository. A refresh never moves a pin;
   that stays your word, in that department.

To remove everything and start from nothing instead, see [Starting over](SETUP.md#starting-over).

## Going back

- **The commands:** copy the backup back, here one made on 2026-11-07:

  ```bash
  cp ~/.claude/commands-backup-2026-11-07/*.md ~/.claude/commands/
  ```

  A command new in the release is not in the backup: delete it by hand, here `/capture`:

  ```bash
  rm ~/.claude/commands/capture.md
  ```

- **A department:** its hooks, settings and `CLAUDE.md` come back from git. Ask the session to undo the upgrade
  commit, or do it yourself with `git revert <commit>`.
- **The charter:** move the pin back to the old one, which stays on record, on your word in that department.
- **The download:** go back to the release you had, here v3.3.0:

  ```bash
  git -C ~/digital-team checkout v3.3.0
  ```

  And forward to the latest again:

  ```bash
  git -C ~/digital-team checkout main
  ```
