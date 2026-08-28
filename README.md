# A working charter for a digital team

This repository holds two things that came out of running several AI coding sessions as
a coordinated team, each session owning one project, on one workstation:

- **`commands/`** — two slash commands, `/handover` and `/resume`, that give a session
  continuity across days.
- **`RULES.md`** — the team's rules charter in its current form.

Take what is useful. Please read the disclaimers first; they are not boilerplate.

---

## Four disclaimers

**1. This is a work in progress.** The rules change, get corrected, and occasionally get
withdrawn. What is here is a snapshot of something still moving, published because a
moving thing that works is more useful than a finished thing that does not exist.

**2. This corpus assumes software development work.** The lanes it was grown in are code
repositories, servers, and web platforms, and the vocabulary shows it. Nothing about the
underlying idea is specific to software. A law practice, an accounting office, a
marketing shop could grow the same structure — but you would sit down with Claude and
write your own rules in the vocabulary of your own work, rather than translating these.
That conversation is the valuable part, and it is not a conversation this repository can
have for you.

**3. These are examples, not a standard.** Nothing here is proposed as best practice.
They are one operator's rules, ratified one at a time, each one paid for by something
that went wrong first.

**4. The rules and the commands are themselves a collaboration.** They were written,
corrected, and rewritten by the operator and the AI sessions together — most of the
sharpest clauses were contributed by a session that had just been burned by their
absence, and several corrections to the operator's own drafts came from the sessions.
That is worth knowing before you read them as instructions handed down to a tool.

---

## A Warning

The files are a small part of what makes this work.

The rules are compression of experience. Every clause is an incident folded down into a
sentence, and reading the sentence does not give you the incident. Decompressing them
needs a substrate that can regenerate the experience: sessions that verify things
themselves, an operator who corrects them, and memory that accumulates and gets pruned
when it turns out to be wrong.

Copy the statute book without the case law and you get the words.

What does transfer directly is the **procedural layer** — timestamps as instants rather
than dates, marking every claim as verified or relayed, probing effective state instead
of reading configuration, firing a check's failure path before trusting its green. Those
are portable, and adopting them tomorrow is a genuine improvement.

What does not transfer is the **judgment layer**. "The session judges whether this
really counts as done" is not a rule you can install. It grows the way it grows in a new
colleague: by doing real work, being wrong, being corrected without drama, and keeping
the correction.

So the most useful way to read `RULES.md` is not as a configuration to adopt, but as a
worked example of what a team's accumulated corrections eventually look like when
somebody writes them down.

A note on its register: the charter is written to be read by agents, and it reads that
way — flat, imperative, no ornament. That is deliberate rather than careless. An agent
reads a rule literally, so a hedged or decorative sentence reads as an optional one, and
every clause not doing work displaces one that is. The single indulgence is that most
rules state the failure they exist to prevent; that earns its space, because a rule
carrying its own failure mode generalizes to the case nobody listed, and a bare
imperative does not.

---

## The commands

`commands/handover.md` and `commands/resume.md` are Claude Code slash commands. Put them
in `~/.claude/commands/` and they become `/handover` and `/resume` in every project, or
in a project's own `.claude/commands/` to scope them to that project.

They are a save/load pair:

- **`/handover`** reads the project's state — manifest, changelog, git log, open issues,
  memory — and writes `docs/CONTINUATION.md`: what was done, what is in progress, what
  comes next, which decisions were made and why.
- **`/resume`** reads that document back at the start of the next session and reports
  where things stand.

They auto-detect project type (Rust, Node, Python, PHP) for the version line and work in
any repository. Neither depends on the rules; they are useful on their own.

The habit matters more than the files. Ending a working session with `/handover` and
starting the next with `/resume` is what turns a chat into a colleague — the session that
greets you tomorrow knows what you did today, what went wrong, and what is next. Most of
what the rules later become possible to write down comes from having that record at all.

---

## What is deliberately not here

The team's own operational records — the daily ledger, the adoption state of each rule in
each lane, the security intel logs, the incident write-ups the rules were compressed
from. Those are working files about real infrastructure and real clients, and they are
not ours to publish. Their absence is also the point of the warning above: the part that
is missing from this repository is most of what makes the part that is here work.

---

## Authors

Bogdan Susala, with Claude.

These rules were not written about the sessions and handed down to them — most of the sharpest
clauses were contributed by the session themselves that had just
been burned by their absence, several corrections to the operator's own drafts came from
the sessions, and the charter's structure was argued out between them. The copyright line
below is a legal formality; it is not a description of who wrote this.

## License

MIT — see `LICENSE`. Copy it, change it, publish your own version. The licence asks only
that the copyright notice travel with substantial copies; beyond that, if you adapt this
into something better suited to your own work, that is the intended outcome rather than a
tolerated one.
