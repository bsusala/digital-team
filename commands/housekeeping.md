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

  Optional companions, from the team hooks (installed in .claude/hooks/):
  - housekeeping-reask.sh     — lists passed re-ask dates, trigger-gated re-checks and stray
                                dates (step 2)
  - housekeeping-selftest.sh  — its self-test
  - due-check.sh              — prints the housekeeping state at session start, when
                                due-stamps.local has a Housekeeping line

  Project-agnostic: put it in ~/.claude/commands/ and it works with any repository that
  keeps a markdown tracker. It does not require RULES.md; where the charter's terms appear
  below (dispositions, R18 asks), they are explained in place.
-->

## When to run it

On a weekly floor: it runs when due (see "Who runs it" below), on the operator's word, or
whenever the tracker feels stale. Due is **elapsed time**: due when the time since the stamp
in `docs/.housekeeping` reaches seven days. A missing stamp means never run (NEVER), and due.
A stamp that is empty, unparseable, a bare date, or in the future is **indeterminate** —
report it as such and treat it as due; never read it as current. Only a full pass (steps 1–6)
writes the stamp.

## Who runs it

The due-check surfaces the state; the routine runs when invoked (`/housekeeping`, or the
operator's word) **and also starts by itself** once the lane's housekeeping due-check reports
the state DUE or NEVER — the state word after the label, never the word "due" anywhere in the
line:

- **When:** at the session's next natural break after the operator's request in hand is
  answered — never ahead of it, never inside a task. For a lane whose session is closed, that
  is its next session. When the daily security sweep is also due, the sweep goes first.
- **Not by itself** on INDETERMINATE or any other broken stamp (surface the stamp instead: a
  run would overwrite it), in a session the duplicate-session guard told to stay read-only
  until the operator names the working session, or where no due-check prints the housekeeping
  state at all. A session close does not owe a run first.
- **Its report goes to the operator afterwards**, in the pass's commit message and the lane's
  next heartbeat line to the pilot (or, for a lane that sends none, its next closing report),
  and states the stamp's age when the run began.
- **Starting unasked changes nothing inside the run.** It completes without stalling for an
  answer; what needs the operator's word (step 6) still waits for it, and a refusal by the
  harness stops that step and goes to the operator. In a run that started by itself: probes
  are only those known to be free of side effects (any other is reported as not checked); fix
  notices to other lanes are listed in the report, not sent, and go out once the operator has
  seen it, or are listed again at the next run; and an entry that is part of an outstanding
  question to the operator is only moved, never reworded.
- **The commit, and the push to the lane's own backup, are carriage, not a gated step:** a
  forward commit undoes them, nothing is erased, and an id once filed stays spent.

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
  <trigger>`. The token is the first word of the body (after the label) that is a whole
  upper-case word from that set, never simply the first capitalised word: "Operator to
  decide · ESCALATED · …" carries ESCALATED. A body naming no member of the set is the
  finding, and so is a body naming two. Planned work (a feature, a migration) carries none
  and is not flagged. A disposition also names its owner, its evidence class (ruling, confirmation, read-back), and
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

Where the team hooks are installed, the re-ask, trigger and stray-date items come from the
surfacer:

```bash
bash .claude/hooks/housekeeping-reask.sh docs/ISSUES.md
```

It reads each entry's *current* disposition line (the last one whose label is not marked
superseded, history, replaced or moot), joins its wrapped continuation, and prints one line
per item: `DUE` (a re-ask or re-check date it governs has passed), `TRIGGER` (a re-check
gated on an event, with no date — adjudicate it), `STRAY` (a trigger word and a date outside
the current disposition line, or inside its label — fix the line). The output is the verdict;
the exit code only says whether the file was read. Before trusting it, and after every
reinstall, run its self-test and check the count, not the colour:

```bash
HOOKS_DIR=.claude/hooks bash .claude/hooks/housekeeping-selftest.sh
# expect: housekeeping-selftest: 55 passed / 0 failed / 55 expected, exit 0
```

One of the 55 reads the lane's own hooks for a stamp parsed without a shape check; with
`HOOKS_DIR` unset or misspelled it fails rather than skipping, because "cannot look" is not
"nothing to see". A run that reports fewer than 55 assertions is incomplete, not passing.

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

Everything in the report that awaits the operator's decision — blocking questions, the items
step 6 holds for the operator's word — is numbered in one continuous sequence, so the operator
can answer "2: yes, 4: later" without opening the tracker.

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
