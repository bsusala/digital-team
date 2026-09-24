---
description: Set up a project for the daily drill — create the missing tracker and continuity files, propose the CLAUDE.md lines, explain each one
---

# Project Bootstrap

Prepare this repository for `/resume`, `/handover` and `/housekeeping`. Run it once per
project. It is safe to run again: it creates only what is missing and never overwrites.

<!-- Principles for this command:
  - Look before writing. Report what exists before creating anything.
  - Create only what is missing. Never overwrite, rename or reformat an existing file.
  - Anything that changes an existing file is proposed and waits for the user's yes.
  - No network. Everything this command writes is in this file; it downloads nothing.
  - Explain each file in one line as it is created. The user should finish knowing why
    each file exists, not only that it does.
-->

## Instructions

### 1. Look first

Confirm this is a git repository (`git rev-parse --show-toplevel`). If it is not, stop and
say so — every file below is meant to be committed, and continuity without history is only
half a record.

Then report, as a short table, which of these exist: `CLAUDE.md`, `docs/ISSUES.md`,
`docs/CONTINUATION.md`, `CHANGELOG.md`, `docs/ROADMAP.md`, `docs/.housekeeping`. Note the
project type from its manifest (`Cargo.toml`, `package.json`, `pyproject.toml`,
`composer.json`, or none).

### 2. Create what is missing

For each missing file, create it and say in one line why it exists.

- **`docs/ISSUES.md`** — *why: the state of record for every bug, enhancement and chore, so
  work is found in a file rather than in someone's memory.* Create it from the template at the
  end of this command, with `<Project>` replaced by the repository's name. If the project
  already tracks issues somewhere else (a different file, or an external tracker), ask before
  creating a second tracker; two trackers drift.
- **`CHANGELOG.md`** — *why: what changed, per version, in words a person can read; the
  continuity commands read it for context.* Create it only if the project has versions. Start
  it with a title and an `## [Unreleased]` section, nothing else.
- **`docs/`** — create the directory if needed.

Do **not** create `docs/CONTINUATION.md` (the first `/handover` writes it), `docs/.housekeeping`
(the first `/housekeeping` writes it), or `docs/ROADMAP.md` (a roadmap is the user's to write,
if they want one; mention that it is optional).

### 3. Propose the CLAUDE.md lines

`CLAUDE.md` is read by Claude Code at the start of every session, so a rule written there is
a rule every future session follows. The block to propose:

```markdown
## Working agreement

- Track every bug, enhancement and operational chore in `docs/ISSUES.md`, using its
  template. Ids are sequential and never reused.
- The same commit that fixes an entry moves it to the Closed section.
- Before filing, search the Open section for an existing entry.
- Start a session with `/resume`; end it with `/handover` and commit the result.
- Run `/housekeeping` once a week, or when the tracker feels stale.
```

- If `CLAUDE.md` **does not exist**: read the repository (README, manifest, build and test
  commands, directory layout) and draft a short `CLAUDE.md` — what the project is, how to
  build it, how to test it, anything it must never do that is evident from the repo — followed
  by the block above. Show the whole draft and write it only when the user says yes.
- If `CLAUDE.md` **exists**: show the block and where it would go (appended at the end, under
  its own heading). Add it only when the user says yes. Never edit the existing text.

### 4. Ask about several sessions — once

Ask one question: *"Do you run several Claude sessions at once, one per project, that should
work as a team?"*

- **No** (the common case): skip this step entirely. The drill works for one project and one
  session.
- **Yes**: find a local copy of the charter — look for `RULES.md` in a `digital-team` clone
  (`find ~ -maxdepth 4 -name RULES.md -path '*digital-team*' 2>/dev/null`). If none is found,
  give the user the clone command (`git clone https://github.com/bsusala/digital-team.git`)
  and stop this step; do not download it yourself. If found, propose adding one line to the
  CLAUDE.md block: `- The team charter is <absolute path to RULES.md>; read it at session
  start. Rules are adopted one at a time, on the operator's own word in this session.` Explain
  that nothing in the charter is in force until the user adopts it here, rule by rule.

### 5. Finish with the drill

Summarise what was created and what was proposed but not written. Then tell the user the three
habits, in this order:

1. At the end of this session, run `/handover` and commit what it writes.
2. At the start of the next one, run `/resume`.
3. Once a week, run `/housekeeping`.

Do not commit on the user's behalf; list the new files so they can review and commit them.

---

## Template: docs/ISSUES.md

```markdown
# <Project> Issues

Local issue tracker, versioned with the code (`docs/ISSUES.md`, committed). The ids are
sequential and never reused. The tracker is a learning journal, not a to-do list: what
broke, why, how it was found, what it pairs with.

**Categories:** Bug (broken behaviour — always an entry) | Enhancement (new capability —
always an entry) | Chore (operational work worth a record). Polish and safe refactors get no
entry.

**Hygiene:** the same commit that flips an entry to fixed moves it to Closed — a fixed entry
sitting in Open is a tracker bug. At `/handover`, the next-up list comes from the Open
section, never from memory alone. Before filing, search Open for an existing entry. Old open
items are re-checked against the code and git before work starts: they may already be fixed.

---

## Open

<!-- newest first -->

---

## Parked

<!-- deliberately deferred, each with the trigger that reopens it -->

---

## Closed

<!-- newest first; an entry arrives here in the same commit that closes it -->

<!-- Entry shape:

### #N — <one-line title: the observable, not the guess>

- **Type:** Bug | Enhancement | Chore — <component>. Found by: <who or what, date>.
- **Observed:** <what was read or probed, with the tool and the time>.
- **Expected:** <what should happen>.
- **Evidence:** <steps to reproduce, or the log lines>.
- **Proposed fix:** <small and reversible first; what would undo it>.
- **Not checked:** <what was not verified — the boundary of the finding>.
- **Disposition:** <findings only — TRACKED here · ESCALATED <to whom, for what> · re-ask <date> · ACCEPTED <reason> · re-check <trigger> · BLOCKED <gate> · re-check <trigger>>.
- **Pairs with:** <other ids, files, docs>.

On close, add: **Status:** FIXED <date> (<version>) — <the fix in one sentence>, and
**Why it hid:** <why it was not caught earlier>.
-->
```
