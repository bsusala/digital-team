# Migrating

- [From v3.1 to v3.2](#from-v31-to-v32) — tools and templates only; the charter is unchanged.
- [From v2 to v3](#from-v2-to-v3) — the charter itself.

## From v3.1 to v3.2

`RULES.md` is byte-identical to v3.1, so no pin moves and nothing is ratified again. What changed is the
tooling around it.

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
   in `SETUP.md` 2.10 does not apply): install from the named commit, merge the new SessionStart entry into
   `.claude/settings.json` with the guard first, and run all five hook self-tests plus
   `bash scripts/backburner-delta.sh --selftest`. Check the counts, not the colour.
3. **Each lane: move its records out of any `.claude/` folder**, if any are there — tracker, security log,
   stamps — repoint `due-stamps.local` and `team.conf`, commit, carry and read back. Fill in the
   "Lane records at:" line of the team block.
4. **Each lane: add a Housekeeping line to `due-stamps.local`** if it has none; without one, `/housekeeping`
   never starts by itself.
5. **Each lane: update the team block and the working agreement** from the templates, and record the change in
   the pilot's log with the self-test counts.

---

## From v2 to v3

For a team already running the v2 charter (tags `v2` / `v2.1`). A fresh team starts from `SETUP.md` instead.

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
