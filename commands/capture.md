---
description: Turn a task this department just did by hand into a named procedure it can run again — the conversation is the spec, the user's corrections become rules, their hesitations become approval gates
---

# Capture a procedure

Turn something this department does again and again into a procedure it can run by name.
The procedure is a project skill: `.claude/skills/<name>/SKILL.md` in this department's
folder, committed with the rest of its work, so it travels when the department moves.

<!-- Principles for this command:
  - The conversation is the specification. A task done in this session, with the user's
    corrections, beats any description of it. Never re-interview about a task just done.
  - The user's corrections are rules; their hesitations are approval gates. Both are
    judgment the user would not have thought to state.
  - Gate what cannot be undone, and only that. A procedure that asks nine times is worse
    than doing the task by hand.
  - Tested on a known case before anyone relies on it. A procedure nobody has seen
    reproduce a known-good result gets checked by hand forever, which saves nothing.
  - A cadence is real only if something fires it. "Runs every Monday" with nothing behind
    it is a string, not a schedule.
  - Nothing is written outside this department's folder. Every file change is shown and
    waits for the user's yes.
-->

## Instructions

### 1. Find the specification

**Best: the task was done in this session.** Read back through the conversation and list
what was done, in order: what was read, what was decided, what was produced, what was sent
or changed. Mark every place the user corrected you; quote their words.

**Otherwise: ask for the last real time.** "Walk me through the last time you did this —
which file, which day, what you did first." One concrete instance, not a general
description. Ask one question at a time and stop when the steps are complete.

Show the step list and ask: "Is this the whole task?" Do not continue until it is.

### 2. Sort each step

For every step, decide which of three it is, and show the result as a table:

| Kind | What it means | Becomes |
|---|---|---|
| **Fixed** | the order, the sources, the output's shape, a rule the user stated | the procedure's steps |
| **Varies** | dates, names, amounts, which file, which customer | inputs the procedure asks for or reads |
| **Judgment** | where the user corrected you, hesitated, or said "it depends" | an approval gate |

A procedure that hardcodes last Tuesday's file only works on last Tuesday. When in doubt
whether something varies, ask.

### 3. Place the gates

A gate belongs before any step that **sends** (anything a third party sees), **spends**,
**publishes**, **deletes or overwrites**, or **commits** the business to a date, price or
scope — and at every judgment point from step 2. Reading, computing, drafting and writing
files inside the department folder are not gated.

Each gate states what will happen before it asks — the count, the totals, the recipients,
whether it can be undone:

```
Good: 6 reminder emails, one per client, USD 2,340 overdue in total, from your
      address. They cannot be unsent. Send them?
Bad:  Ready to proceed?
```

A yes covers that one action in that one run. A procedure never carries a yes forward to
the next run: a step approved a hundred times is still asked the hundred-and-first.
Three to five gates is healthy; if you count more, merge or drop the ones that guard
nothing irreversible.

### 4. Write it

Propose `.claude/skills/<name>/SKILL.md` — lowercase, hyphenated name the user agrees to:

- **Frontmatter:** `name` (matches the folder) and `description`: what it does, then when
  to use it, in the department's own words and the phrases the user actually said. The
  description is the only thing that decides whether the procedure is found; lean towards
  naming more phrases, not fewer.
- **Body:** one line on what it is for; numbered steps; the gates at their steps; a short
  "What not to do" list that holds each correction from step 1 with its reason ("never
  include invoices under USD 50 — the user writes those off").
- **Honest data:** a figure that cannot be read is reported as missing, by name, never
  guessed; an empty result is a fact about the source until shown otherwise.
- **Under about 120 lines.** Detail that is only needed at one step goes into
  `reference/<topic>.md` beside it, and the step says when to open it.

Use the user's words. If they say "the carrier file", the procedure says carrier file.
Show the full text and wait for the user's yes before writing.

### 5. Test it on the case you already know

Run the new procedure against the instance from step 1 — or another one the user already
knows the answer to — and stop at every gate without passing it. Show its output next to
what was produced by hand.

If they differ, fix the procedure and run it again. Do not ask the user to accept a
near-miss.

### 6. Register it

Propose one line in this department's `CLAUDE.md`, under a `## Procedures` heading (create
the heading if it is missing):

```
- `<name>` — <what it does, in five to ten words> · say "<the user's trigger phrase>"
```

**If it recurs**, ask how often, then offer the department's due-check: one line in
`.claude/hooks/due-stamps.local` (`<label> TAB <stamp path> TAB <period in hours>`), and a
last step in the procedure that writes the stamp (`date -u +%FT%H:%MZ > <stamp path>`) when
a full run completes. The due-check then says when it is due, at the start of a session and
at the end of every turn. If the user declines, the procedure's description says plainly
"not scheduled — run it by name".

### 7. Commit

Stage only the files this command wrote or changed, show `git status --short`, and commit
on the user's yes: `Add procedure <name>`. Then tell the user, in one line, the phrase that
runs it.

## What not to do

- **Do not re-interview about a task done in this session.** The conversation is the spec.
- **Do not hardcode the example.** Names, dates and amounts vary; the sequence does not.
- **Do not gate everything.** Gate the irreversible and the judgment points; let the rest run.
- **Do not skip the test run.** An untested procedure saves nothing.
- **Do not say "saved, runs weekly" without the due-check line.** Nothing would run it.
- **Do not write outside this department's folder** or change another department's procedures.
