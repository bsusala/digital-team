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

### #1 — <one-line title: the observable, not the guess>

- **Type:** Bug | Enhancement | Chore — <component>. Found by: <who or what, date>.
- **Observed:** <what was read or probed, with the tool and the time — configured state is a claim, inspected state is a fact>.
- **Expected:** <what should happen>.
- **Evidence:** <steps to reproduce, or the log lines>.
- **Proposed fix:** <small and reversible first; what would undo it>.
- **Not checked:** <what was not verified — the boundary of the finding>.
- **Disposition:** <for findings only — TRACKED here · or ESCALATED <to whom, for what> · re-ask <date> · or ACCEPTED <reason> · re-check <trigger> · or BLOCKED <gate> · re-check <trigger>>.
- **Pairs with:** <other ids, files, docs>.

---

## Parked

<!-- deliberately deferred, each with the trigger that reopens it -->

### #2 — <title> — PARKED: <reason>; reopen when <trigger>

---

## Closed

<!-- newest first; an entry arrives here in the same commit that closes it -->

### #3 — <title>

- **Type:** …
- **Observed:** …
- **Status:** **FIXED <date> (<version>)** — <the fix in one sentence>.
- **Why it hid:** <why it was not caught earlier — the part that becomes a lesson>.
- **Pairs with:** …
