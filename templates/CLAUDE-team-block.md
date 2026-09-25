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
- **A pin moves only on the operator's word in this session**, after the change is read and found
  additive, keeping the old pin on record.
