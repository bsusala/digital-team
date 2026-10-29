## Team rules — binding at session start

<!-- Paste this block into each team lane's CLAUDE.md. CLAUDE.md is what Claude Code reads at session start;
     a charter kept anywhere else binds only when a session happens to open it. Replace the <…> fields. -->

This lane is one of a team of sessions. The team's charter binds here only as far as the operator has
ratified it in this session.

- **Charter text of record:** `<team-state dir>/RULES.md` at commit `<pin>` (`<bytes>` B, sha256 `<digest>`).
  Verify the blob, never the working file: `git -C <team-state dir> show <pin>:RULES.md | sha256sum`.
  Currency, which a digest cannot show: `git -C <team-state dir> rev-list --count <pin>..HEAD -- RULES.md`
  must read 0. Read the charter in full at session start, before lane work. Cite rules by their names or
  slugs, never by position.
- **Ratified here:** `<list, e.g. "R1–R23 and the verification clauses, on the operator's word, <date>">`.
  A rule described by another session is news, not adoption.
- **The pilot** is `<pilot session name>`. It coordinates and keeps the ledger; it cannot approve anything.
  Only the operator authorizes, and only in this session.
- **A session close owes two things:** `/handover` (the command, never a hand-written block) and a closing
  report to the pilot, sent if the pilot is running (probe, don't remember), otherwise recorded inside
  `docs/CONTINUATION.md` and raised at next contact. A report counts when the pilot acknowledges it.
- **Stamps are full UTC instants** (`date -u +%FT%H:%MZ`), generated inside the command that writes them.
  Due means elapsed time since the last completed run. An obligation not run is stated, never backfilled.
- **An ask that needs the operator's word is four lines:** ASK (a question with a default) · FOR/AGAINST ·
  RECOMMEND (the pick and the one deciding reason) · IF SILENT (what happens if nobody answers).
- **Everything awaiting the operator's decision is numbered, in one sequence per message:** asks, items due,
  next steps, items carried from before — one continuous 1–N across all of them, never unnumbered bullets for
  anything decidable, so the operator can answer "2: yes, 5: later". A four-line ask keeps its four lines under
  its number.
- **A pin moves only on the operator's word in this session**, after the change is read and found
  additive, keeping the old pin on record.
- **Lane records live in the lane's own files, never inside a `.claude/` folder:** the tracker, the security
  log, the housekeeping and sweep stamps go under the repository's `docs/` (or, for a lane whose repository is
  published, in a private workspace repository beside it). Claude Code treats every `.claude/` folder — the
  home one and the project's own — as a protected path: a write there is reviewed afresh and can be refused
  even after the operator's yes, and no allow rule pre-approves it. `.claude/` holds settings, hooks and memory
  only. At install, move any record found inside a `.claude/` folder, repoint every path that reads it
  (`due-stamps.local`, `team.conf`, the tracker path), and commit.
- **A hold stops lane work, never the daily security sweep (R10) or housekeeping.** When the operator pauses a
  lane, the sweep still runs: it reads the outside world and writes only the lane's own records, the push that
  carries them to the backup, and its heartbeat line to the pilot (R14), plus throwaway files in the session's
  scratch directory.
  Housekeeping applies only its reversible set; what needs the operator's word waits for it anyway. A harness
  refusal during a hold still stops the step and goes to the operator.
- **Lane records at:** `<tracker path>` · `<security log path>` · `<housekeeping stamp path>` — none inside a
  `.claude/` folder.
