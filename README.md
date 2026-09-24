# A working charter for a digital team

## TL;DR — what to actually do

You need [Claude Code](https://claude.com/claude-code) and a project in a git repository.

**1. Install the commands (once, two minutes):**

```bash
git clone https://github.com/bsusala/digital-team.git
mkdir -p ~/.claude/commands
cp digital-team/commands/*.md ~/.claude/commands/
```

**2. Once per project, run `/bootstrap`.** It looks at the repository, creates the missing
tracker files, proposes the lines for `CLAUDE.md` and explains each one. It never overwrites
anything, and changes to an existing file wait for your yes.

**3. Then, every day:**

| When | Type | What happens |
|---|---|---|
| You open a session | `/resume` | Claude reads where you left off and tells you: done, in progress, next. |
| You are about to close it | `/handover` | Claude writes `docs/CONTINUATION.md`: what changed, what is open, what comes next. Commit it. |
| Once a week | `/housekeeping` | Claude checks `docs/ISSUES.md` against the code: closes what shipped, files what was never tracked, flags what is stuck. |

That is the whole drill, and it works for one project with one session. The first
`/resume` in a project finds nothing — run `/handover` once at the end of your first
session and it has something tomorrow.

**What `/bootstrap` sets up, if you would rather do it by hand (all committed to git):**

| File | Who writes it | What it is |
|---|---|---|
| `CLAUDE.md` | you | The project's standing instructions — what it is, how to build and test it, what never to do. Claude Code reads it at every session start. |
| `docs/ISSUES.md` | Claude, as you work | The tracker: every bug, enhancement and chore, open or closed. Start from [`templates/ISSUES.md`](templates/ISSUES.md). `/housekeeping` needs it. |
| `docs/CONTINUATION.md` | `/handover` | Where the last session stopped. Never edit it by hand; regenerate it. |
| `CHANGELOG.md` | Claude, at each release | What changed, per version. Optional, but `/handover` and `/resume` read it when it exists. |
| `docs/ROADMAP.md` | you | Optional. The longer-term direction; it should cite issue ids rather than keep its own task list. |
| `docs/.housekeeping` | `/housekeeping` | One line: when the last full reconciliation ran. |

Tell Claude once, in `CLAUDE.md`: *"Track every bug and enhancement in docs/ISSUES.md, using
its template. Closing an entry moves it to Closed in the same commit."* After that, filing is
its job.

**4. Only if you run several sessions at once, one per project** (`/bootstrap` asks):

- Keep a copy of `RULES.md` where every session reads it at start — for Claude Code, that
  means pointing at it from each project's `CLAUDE.md`.
- Pick one session as the **pilot**: it keeps a shared log and passes findings between
  the others. It never approves anything — only you do.
- Adopt rules one at a time, in each session, in your own words. A rule another session
  tells it about is news, not permission.

Start with steps 1 to 3 for a week before you touch step 4. The rest of this page is why.

---

This repository holds what came out of running several AI coding sessions as a
coordinated team, each session owning one project, on one workstation:

- **`commands/`** — four slash commands: `/bootstrap`, which prepares a project;
  `/handover` and `/resume`, which give a session continuity across days; and
  `/housekeeping`, which keeps its issue tracker honest across weeks.
- **`templates/ISSUES.md`** — the issue-tracker template those commands expect.
- **`RULES.md`** — the team's rules charter in its current form.

Take what is useful. Please read the disclaimers first; they are not boilerplate.

The story behind it, in the order it happened, is a series of articles:
[susala.eu/digital-team](https://susala.eu/digital-team/).

---

## Five disclaimers

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

**5. Rules differ in age, and age here means service, not calendar.** Most clauses were
paid for by an incident before they were written. R17, reversibility, went the other way:
proposed from first principles, reviewed hard by every session, ratified, and published
before any incident had tested it in the field. It is marked as such where it appears.
Treat a ratified-but-unfielded rule as a hypothesis the team currently believes, not as a
survivor. This revision is also the first the team has **settled and frozen**: its final
review changed wording only, never shape, so new rules now wait for a newly declared review.

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

The four files in `commands/` are Claude Code slash commands. Put them in
`~/.claude/commands/` and they become `/bootstrap`, `/handover`, `/resume` and
`/housekeeping` in every project, or in a project's own `.claude/commands/` to scope them to
that project.

**`/bootstrap`** prepares a project once: it reports which files exist, creates the missing
tracker, proposes the `CLAUDE.md` lines and explains why each file exists. It downloads
nothing — the template it writes is inside the command — and it never overwrites a file.

They are a save/load pair:

- **`/handover`** reads the project's state — manifest, changelog, git log, open issues,
  memory — and writes `docs/CONTINUATION.md`: what was done, what is in progress, what
  comes next, which decisions were made and why.
- **`/resume`** reads that document back at the start of the next session and reports
  where things stand.

They auto-detect project type (Rust, Node, Python, PHP) for the version line and work in
any repository. Neither depends on the rules; they are useful on their own.

**`/housekeeping`** is the weekly read of `docs/ISSUES.md`. It checks the tracker's own
structure first (every entry has a heading, every status comes from a closed set, status
agrees with section), then checks each open entry against the code and the history: work
that shipped but was never closed, parked items whose trigger has fired, re-ask dates that
passed, work that was never filed. It applies the reversible fixes, lists the ones that need
the operator's word, and stamps the run as a UTC instant so the next one knows when it is
due. It does not require the rules either, though it speaks the charter's vocabulary for
dispositions.

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
