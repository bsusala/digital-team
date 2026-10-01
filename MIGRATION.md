# Migrating from v2 to v3

For a team already running the v2 charter (tags `v2` / `v2.1`). A fresh team starts from `SETUP.md` instead.

## What changed

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

## How to migrate, lane by lane

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

## After migrating

- **The charter is frozen at v3.** New rules wait for a newly declared review; between reviews the text
  changes only by correction. Keep corrections in a separate errata file beside `RULES.md`, so that every
  lane's pin stays current, and fold them in at the next review.
- **Keep the old pins.** A lane's history of pins is how a later reader tells which rules bound it when.
