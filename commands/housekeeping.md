---
description: Reconcile the issue tracker (docs/ISSUES.md) against reality — structure checks, done-but-open entries, untracked work, passed re-asks and aged items — and report
---

# Issue-tracker Housekeeping

Reconcile `docs/ISSUES.md` with what is actually true.

<!-- Pattern: the weekly read
  /handover and /resume carry a session's context across days. This command keeps the
  tracker honest across weeks: work lands without its status flipping, fixes ship without
  an entry, re-ask dates pass unnoticed, and the file itself develops structural errors
  that no scoped read ever sees.

  Expected project files:
  - docs/ISSUES.md        — the tracker (required)
  - docs/ROADMAP.md       — optional; checked for drift if present
  - CHANGELOG.md          — optional; read as evidence
  - docs/.housekeeping    — the stamp this command writes (one UTC instant)

  Project-agnostic: put it in ~/.claude/commands/ and it works with any repository that
  keeps a markdown tracker. It does not require RULES.md; where the charter's terms appear
  below (dispositions, R18 asks), they are explained in place.
-->

## When to run it

On a weekly floor, or whenever the tracker feels stale. Due is **elapsed time**: due when
the time since the stamp in `docs/.housekeeping` reaches seven days. A missing stamp means
never run, and due. A stamp that is empty, unparseable, a bare date, or in the future is
**indeterminate** — report it as such and treat it as due; never read it as current.
Only a full pass (steps 1–6) writes the stamp.

## Instructions

### 1. Read the tracker in full, and check its structure first

Read `docs/ISSUES.md` end to end. Then check the file as a file — most defects in a
long-lived tracker are structural, and every heading-based read is blind to them:

- **Verify your marker before trusting it.** Pick the line that begins every entry body in
  this tracker's template (for example `- **Type:**`) and count it against the entry
  headings. A mismatch is first a claim that the marker is wrong; only after the marker is
  confirmed is it a claim about the file.
- **Every entry has a heading.** A headless entry is invisible to every read that walks
  headings, including this one.
- **Every status comes from a closed set** — the words the template uses (Open, Closed,
  Parked…). A free-text status is a finding, not a synonym.
- **Status agrees with the section.** A closed entry in the Open section, or never-built work
  in Closed, both happen.
- **Every finding carries a disposition from a closed set**, exactly one:
  `FIXED <commit + how it was confirmed>` · `TRACKED <id>` · `ESCALATED <to whom, for what> ·
  re-ask <date>` · `ACCEPTED <reason> · re-check <trigger>` · `BLOCKED <the gate> · re-check
  <trigger>`. Planned work (a feature, a migration) carries none and is not flagged. A
  disposition also names its owner, its evidence class (ruling, confirmation, read-back), and
  what it silences until when: accepted silences; blocked and escalated only defer, so a
  deferring disposition with no date or trigger is a finding.
- **Next free id** = highest id ever issued + 1. Ids are never reused and gaps are never
  filled. If ids were ever removed from the file, take the ceiling from `git log -p` on the
  tracker rather than from the file. Report the id derived and the highest seen.
- **Record the set of entry ids** before changing anything; step 5 compares sets, not counts.

### 2. Check every non-closed entry against reality

Never take a status on faith. Use `git log` since the entry's area was last touched, grep the
code, read `CHANGELOG.md`, and run a targeted test where one would settle it. Sort what you
find:

- **Done but still open** → close it with the resolving commit or version and the evidence.
- **Parked, but its reopen trigger has fired** → reopen it.
- **Scope drifted** → the entry no longer describes what is needed; edit it.
- **Re-ask date passed** → state the answer, or state that the owner did not answer. Silence
  is recorded, not assumed.
- **Trigger-gated re-check** → adjudicate each pass: fired, not fired, or cannot tell. A
  trigger nobody re-reads is a date nobody wrote down.
- **Aged** → anything tracked, escalated or blocked for longer than a week (wall-clock, since
  its disposition was set): list it with age, owner and blocker.
- **A date beside a trigger word outside the current disposition line** → move it onto the
  line, mark the old line as history, or reword it. A dead date next to a live trigger word
  is one careless read away from a false alarm.

### 3. Look for untracked work

Scan `git log` since the stamp (the whole history on a first run) and the working tree for
changes that were never filed. New entries take the next free id; work that already shipped
goes straight to Closed with its version, for the record.

### 4. Roadmap drift (only if `docs/ROADMAP.md` exists)

The roadmap should reference entry ids, never keep a parallel task list. Flag roadmap items
with no entry and entries a roadmap theme should cite. Where the roadmap lists gates rather
than tasks, ask whether each gate is still true.

### 5. Report

Present, tight:

- **Structure:** marker verified (the counts), missing headings, status and section
  disagreements, stray dates, next free id (derived / highest seen).
- **Close:** `<id> — title` → closed in <commit/version>, with the evidence.
- **Reopen / re-status:** `<id>` → new status, and why.
- **File:** new entries (id, title, type).
- **Passed re-asks, fired triggers, aged, incomplete:** one line per item — owner, age,
  blocker or missing field. Only a genuinely blocking item becomes a full question to the
  operator (one sentence with a default, the case for and against, a recommendation, and what
  happens if nobody answers).
- **Roadmap drift**, or "no roadmap".
- **Snapshot:** Open (actionable now) · Parked (blocked, on what).
- **Counts, with units:** entries read, the id-set difference before and after (removed must
  be empty unless a close moved it), closes, new entries, re-asks, triggers, aged, incomplete.
  A count that names its unit makes a drop visible; an id-set difference makes a swap visible.

### 6. Apply, then stamp

The gate is **reversibility**, not step number:

- **Apply directly** — reversible text edits in a committed file: status flips, section moves,
  new entries, disposition lines on findings. A status that becomes closed moves the entry to
  the Closed section in the same commit. A disposition change is a new line naming what it
  changes; old lines are marked as history, never silently rewritten.
- **Wait for the operator's word** — closing an entry the operator escalated, changing a
  disposition the operator set, deleting text, closing an entry another entry depends on, or
  touching an entry that is part of a question currently in front of the operator. List each
  as `awaiting the operator since <instant>`, with what happens if nobody answers, and list it
  again every run until it is answered.

Then write the stamp, generated inside the command that writes it:

```bash
date -u +%FT%H:%MZ > docs/.housekeeping
```

Commit the tracker changes and the stamp, citing the affected ids. The stamp records that the
reconciliation ran; it never claims that a waiting item was decided.

If everything was already accurate, say so, show the counts and the id-set difference, and
refresh the stamp.
