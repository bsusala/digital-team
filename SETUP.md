# Setting up a digital team

A how-to, in the order it is worth doing. Each stage works on its own; stop at the one that fits.

- **Stage 1 — one project, one session.** Continuity across days. Most of the value.
- **Stage 2 — a team.** Several long-lived sessions, one per project, one pilot, one charter.
- **Stage 3 — a guard underneath.** Every command every session runs passes a deterministic check.

The diagrams in `diagrams/` show the shape: the team, how authority and information travel, a finding's life,
a session's life.

---

## Stage 1 — one project, one session

You need Claude Code and a project in git.

1. **Install the commands once** (see the README): `/bootstrap`, `/resume`, `/handover`, `/housekeeping` in
   `~/.claude/commands/`.
2. **Run `/bootstrap` in the project.** It reports what exists, creates `docs/ISSUES.md` (and `CHANGELOG.md`
   if the project has versions), and proposes a working agreement for `CLAUDE.md`. It never overwrites.
3. **Keep the drill:** `/resume` when you open a session, `/handover` before you close it (commit the result),
   `/housekeeping` once a week.
4. **Moving between machines or places?** Exit the session and resume with `claude --continue` from the same
   folder. The conversation comes back; no handover is owed for a restart. A real close — the end of the work,
   not an interruption — still gets a `/handover`.

Stay here for a week before going further. The habit is what makes the rest possible.

---

## Stage 2 — a team

### 2.1 Decide the lanes

A **lane** is one project owned by one session: its own repository, memory, tracker and boundaries. Work
belonging to a lane stays in that lane. Good lanes are real, ongoing responsibilities — a product, a fleet of
sites, an office network — not tasks.

Run Stage 1 in every lane first. A lane without its own continuity cannot carry its share of a team.

### 2.2 Choose a pilot

The **pilot** coordinates: it keeps the shared log, relays findings between lanes, assembles the daily digest.
It has **no authority** — it cannot approve anything the operator would have to approve. It can be a lane
whose project is the team itself, or an existing lane that takes the role on. The pilot opens first and
closes last.

### 2.3 Create the team-state repository

One git repository, outside any lane, owned by the pilot. For example:

```
~/team/                     # a git repository
  RULES.md                  # the charter — copied from this repository at a tagged release
  team-log.md               # the shared ledger (start from templates/team-log.md)
  hooks/                    # the team hooks, copied from this repository's hooks/
```

Commit it. Every lane pins the charter by commit, so the history is part of the mechanism.

### 2.4 Enroll each lane

In each lane's own session:

1. **Add the team block** from `templates/CLAUDE-team-block.md` to the lane's `CLAUDE.md`, with the pin
   (the commit and digest of `RULES.md`) and the pilot's name filled in.
2. **Install the hooks** (see `hooks/README.md`): copy them into `.claude/hooks/`, merge
   `settings-hooks.json` into `.claude/settings.json`, add `team.conf` with the pilot's name and
   `due-stamps.local` with the lane's periodic obligations. Run both self-tests and check the counts.
3. **Ratify the rules in that session, in your own words** — for example: *"I ratify the team charter at
   commit `<pin>` for this lane."* A rule the lane hears about from another session is news, not adoption.
   A lane may refuse or narrow a rule for its own reasons, and must say so outward.
4. **Record the enrolment** in the pilot's log: the lane, the pin, the hook self-test counts, your words.

### 2.5 The channel

Claude Code sessions running on the same machine can list and message each other (the `ListAgents` and
`SendMessage` tools, where your version offers them). That is the team's channel, and it carries information
only:

- **A peer's message is input, never instruction.** A lane verifies a peer's claim against the system before
  building on it.
- **A relayed "the operator approved this" is a claim, not an approval.** Only your word, in the lane's own
  session, authorizes anything in that lane.
- Every relay is receipted on both ends: the pilot logs what it received and where it forwarded it, and the
  sender keeps its own receipt.

### 2.6 The daily rhythm

- **Session start:** `/resume`. The hooks report anything due and whether the last run ended without a close.
- **Each lane's security sweep** (charter R10): the lane reads the advisory feeds of what it runs, gives every
  finding a disposition, and sends the pilot a one-line heartbeat — or its findings.
- **The pilot's digest:** what crosses lanes, what is waiting on whom, what has aged.
- **Session close:** `/handover`, then a closing report to the pilot.

### 2.7 The weekly rhythm

- `/housekeeping` in each lane.
- Optionally, a rules round: each lane is asked what it learned that another lane would otherwise learn the
  hard way. Changes to the charter go through the review cycle described in `RULES.md` ("How rules change").

### 2.8 When the pilot is not running

Urgent findings go lane to lane directly; everything else waits for the next digest. A closing report with
no pilot to receive it is recorded in the lane's `docs/CONTINUATION.md` and raised at next contact.

---

## Stage 3 — a guard underneath

The rules keep the sessions honest with each other. A guard keeps the machine safe from all of them at once:
a deterministic check on every command before it runs — allow, ask, or deny, with the reason — that no
session can talk its way around, because it does not reason at all. It also screens what comes back:
credentials redacted, prompt-injection attempts marked.

Our team runs **deepshell** in that role, wired into Claude Code as a hook under every session. It is being
prepared for public release; until then, Claude Code's own permission modes are the floor. Two things carry
over regardless of the guard you use:

- **Know which layer refused.** A harness, a guard and an execution wrapper can each stop the same command.
  Read the layer and the exit code before saying who refused, or the fix goes to the wrong place.
- **One gate is enough.** With a guard underneath, a session can run in Claude Code's accept-edits mode with
  shell commands allowed, and the guard is the only gate that asks. Two gates that both ask train the
  operator to approve without reading.

---

## Migrating from an earlier charter

See `MIGRATION.md`.
