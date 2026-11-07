# Changelog

What changed in each release, newest first. Upgrade steps between releases are in
[`MIGRATION.md`](MIGRATION.md). The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [3.3.1] — 2026-11-07

Instructions only: nothing to install, and `RULES.md` is unchanged.

### Changed
- Installing the commands and the hooks uses `cp -i`, which asks before it replaces a file, so a
  command or hook you already have is never overwritten without your answer.
- `MIGRATION.md` starts with what an upgrade changes on your computer, in plain words, and what it
  never touches. Every release section says what it changes. New sections: before any upgrade
  (update the download, commit, copy your commands), updating the commands and the hooks with a
  comparison first, refreshing a setup that got mixed up while keeping your work, and going back.
  A section for v3.2 to v3.3.
- README and the setup guide: for a business, the Team plan, the one made for companies.
- README, what it could cost: details about a Claude Team plan.

## [3.3.0] — 2026-11-07

`RULES.md` is unchanged; nothing is ratified again and no migration is needed. To get the new
command, copy `commands/capture.md` into `~/.claude/commands/`.

### Added
- **`/capture`:** turns a task the department just did by hand into a procedure it can run by
  name. The conversation is the specification: it lists what was done, sorts each step into
  fixed, varying or judgment, places approval gates only before what cannot be undone, tests the
  procedure on the case just done, and saves it only on your yes.
  Run after a session where you corrected a procedure, it updates that procedure instead,
  shown as before → after. It also renames a procedure, keeps descriptions distinct so one
  phrase fits one procedure, and keeps the department's list of procedures in `CLAUDE.md`.
- **`CHANGELOG.md`:** this file.

### Changed
- README and the setup guide list five commands; the README describes `scripts/department.py`.
- Repository history: commit messages cleaned for clarity and simplicity. File contents are
  unchanged; tags point to new commit ids.

## [3.2.3] — 2026-11-01

### Added
- `/bootstrap` checks that git can commit: if `user.name` or `user.email` is empty, it asks for
  them and sets them only on your yes. It uses the folder's real branch name, never an assumed `main`.
- `/bootstrap` says where one department leads (more departments, then the setup guide's Stage 2),
  and offers a dated reminder that `/housekeeping` shows when the date passes.

### Changed
- README and the setup guide: the table of what `/bootstrap` asks gains the reminder; backup
  pushes use `git push -u origin HEAD` and `git push usb HEAD`, which work on any branch name.

## [3.2.2] — 2026-10-31

### Changed
- `/bootstrap`: the team question carries its recommendation (starting out, answer no; run one
  session for a week first).
- README and the setup guide, Stage 1: a table of the three things `/bootstrap` asks, with the
  answer for someone starting out.

## [3.2.1] — 2026-10-31

Documentation only.

### Changed
- One command per block in the README quick start and the setup guide's Stages 0 and 1, each
  saying what it does and where it is typed.
- The first session is spelled out: make the folder, `git init`, start `claude`; `/` commands are
  typed inside Claude Code.

### Fixed
- The hook install in `hooks/README.md` now copies from the clone (`~/digital-team/hooks/…`)
  instead of a path that worked only when the repository sat inside the department's folder.

## [3.2] — 2026-10-29

`RULES.md` is byte-identical to 3.1. Upgrading: [`MIGRATION.md`](MIGRATION.md#from-v31-to-v32).

### Added
- `hooks/duplicate-session-guard.sh`: warns at session start when another interactive session is
  already live in the same project.
- `hooks/housekeeping-reask.sh`: surfaces passed re-ask dates and trigger-gated re-checks for
  `/housekeeping`.
- `scripts/backburner-delta.sh`: the open entries a commit cited, or whose files changed, since
  the last housekeeping pass.

### Changed
- `/housekeeping` starts by itself once due, after the request in hand, never inside a task.
- Team block: lane records live outside every `.claude/` folder; a hold stops lane work, never the
  daily sweep or housekeeping; everything awaiting the operator is one numbered list.
- Tracker template: verify an entry is still open before working it; close what else a fix resolved.
- `SETUP.md` 2.9 and 2.10: each lane carries its own work to the backup; installing an update to
  a shared team script.

## [3.1] — 2026-10-01

### Fixed
- The compaction self-test count: three documents said 20 assertions; it runs 24.

## [3.0] — 2026-10-01

The recipe around the charter.

### Added
- `SETUP.md`: setting up a digital team in stages, from a blank computer to a team with a guard.
- `MIGRATION.md`: moving a team from the v2 charter to v3.
- `commands/`: `/bootstrap`, `/handover`, `/resume`, `/housekeeping`.
- `hooks/`: the wrap-up trigger, the missed-close warning, due-checks, and the compaction nudge,
  each with a self-test.
- `templates/`, `diagrams/`, and a FAQ in the README.

## [2.1] — 2026-08-31

### Fixed
- R17's escalation clause: "undoable" (which also reads as "impossible to do") becomes
  "reversible". One word changed.

## [2.0] — 2026-08-31

### Added
- R17, Reversibility ("Don't do anything you can't undo"), marked not yet field-tested.
- How rules change: the roundup lifecycle.
- New standing riders and maintenance principles.

### Changed
- R14 (standing sweep and team digest) moves from candidate to ratified.
- R10 gains the discriminating-control form of clause (j).

## [1.0] — 2026-08-31

### Added
- The charter: R1–R13, the standing riders, R14 as a candidate, and `/handover` and `/resume`.

[Unreleased]: https://github.com/bsusala/digital-team/compare/v3.3.1...HEAD
[3.3.1]: https://github.com/bsusala/digital-team/compare/v3.3.0...v3.3.1
[3.3.0]: https://github.com/bsusala/digital-team/compare/v3.2.3...v3.3.0
[3.2.3]: https://github.com/bsusala/digital-team/compare/v3.2.2...v3.2.3
[3.2.2]: https://github.com/bsusala/digital-team/compare/v3.2.1...v3.2.2
[3.2.1]: https://github.com/bsusala/digital-team/compare/v3.2...v3.2.1
[3.2]: https://github.com/bsusala/digital-team/compare/v3.1...v3.2
[3.1]: https://github.com/bsusala/digital-team/compare/v3...v3.1
[3.0]: https://github.com/bsusala/digital-team/compare/v2.1...v3
[2.1]: https://github.com/bsusala/digital-team/compare/v2...v2.1
[2.0]: https://github.com/bsusala/digital-team/compare/v1...v2
[1.0]: https://github.com/bsusala/digital-team/releases/tag/v1
