# Setting up a digital team

A how-to, in the order it is worth doing. Each stage works on its own; stop at the one that fits.

- **Stage 0 — the workstation.** A Linux machine with Claude Code and git. Skip it if you have one.
- **Stage 1 — one department, one session.** Continuity across days. Most of the value.
- **Stage 2 — a team.** Several long-lived sessions, one per department, one pilot, one charter.
- **Stage 3 — a guard underneath.** Every command every session runs passes a deterministic check.

The diagrams in `diagrams/` show the shape: the team, how authority and information travel, a session's life,
a finding's life.

---

## Stage 0 — the workstation

This is the setup our team runs on, written for someone who has used computers for years but never Linux.
If you already have a Linux or macOS machine with a terminal you are comfortable in, skip to Stage 1.

### Why Linux

The sessions work by running ordinary commands in a terminal - reading files, running tests, using git - and
the team's hooks are small shell scripts. Linux (and macOS, which is close) runs all of that natively. On
Windows it works inside WSL, a Linux environment built into Windows (see the note at the end of this stage).

### The machine

Any laptop or desktop from the last several years. Claude Code itself needs 4 GB of RAM; 16 GB is
comfortable once several sessions run side by side. You do not need a powerful machine - the thinking happens
on Anthropic's side; your machine runs the commands.

### 1. Install Ubuntu

We use **Ubuntu 24.04 LTS** ("LTS" means long-term support: security updates for years, no surprises).

1. Download the desktop image from [ubuntu.com/download/desktop](https://ubuntu.com/download/desktop).
2. Write it to a USB stick. From Windows or macOS, [balenaEtcher](https://etcher.balena.io/) is the simplest
   tool; from an existing Ubuntu, use the built-in *Startup Disk Creator*.
3. Boot from the stick and follow the installer. If this machine will do nothing else, "Erase disk and install
   Ubuntu" is the straightforward choice. Pick a strong password: you will type it for administrative commands.

### 2. Meet the terminal

Open it with **Ctrl+Alt+T**. Everything below is typed there, one line at a time, followed by Enter. The few
commands worth knowing on day one:

| Command | What it does |
|---|---|
| `pwd` | shows which folder you are in |
| `ls` | lists the files in it |
| `cd Company` | moves into the folder `Company` (`cd ..` goes back up, `cd` alone goes home) |
| `mkdir name` | creates a folder |
| `cat file` | prints a file |
| Ctrl+C | stops whatever is running |

`sudo` in front of a command runs it as administrator and asks for your password. Nothing appears on screen
while you type the password; that is normal.

### 3. Update the system and install the tools

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git jq curl
```

`git` keeps the history of every department, `jq` is used by the team hooks, `curl` downloads files.

### 4. Install Claude Code

The official installer (it needs neither Node.js nor npm):

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

This downloads a script from Anthropic and runs it. If you prefer to read a script before running it - a good
habit - download it first with `curl -fsSL https://claude.ai/install.sh -o install.sh`, read it with
`less install.sh`, then run `bash install.sh`.

Open a **new** terminal, then check the installation:

```bash
claude --version
claude doctor
```

### 5. Sign in

```bash
claude
```

A browser window opens; sign in with your Claude account. You need a subscription that includes Claude Code
(the Pro or Max plans), or Console credentials. Once it says "Login successful" you are in. Type `/exit` to
leave for now. Claude Code updates itself; `claude update` forces an update.

### 6. Tell git who you are

Every commit records its author. Once:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

### 7. Make a home for your company

One folder for the business, one folder per department inside it, and every department a git repository:

```bash
mkdir -p ~/Company/marketing
cd ~/Company/marketing
git init
```

Work you already keep elsewhere: copy that folder into `~/Company/` and run `git init` inside it, or clone it
with `git clone <address>` if it already lives in a git service.

### 8. Keep a second copy from day one

A single laptop is a single point of failure. Both options below need the department to have at least one commit
(`git add -A && git commit -m "First commit"`; after Stage 1, every `/handover` gives you another). Two simple
options:

- **A private repository** on a git hosting service (GitHub, GitLab, Codeberg). Create an empty private
  repository there, then in the department's folder: `git remote add origin <its address>` and `git push -u origin main`.
- **A USB drive**, if you would rather keep everything offline. With the drive mounted:
  `git clone --bare ~/Company/marketing /media/$USER/<drive>/marketing.git`, then in the
  department's folder `git remote add usb /media/$USER/<drive>/marketing.git` and, after each working day,
  `git push usb main`.

Whichever you choose, check now and then that the copy really has your latest work - a push that failed looks
exactly like one that succeeded until you look.

### Windows and macOS

- **Windows:** install WSL (in PowerShell as administrator: `wsl --install`), which gives you Ubuntu inside
  Windows; then follow this stage from step 2 inside the Ubuntu terminal. Claude Code also has a native Windows
  installer (`irm https://claude.ai/install.ps1 | iex` in PowerShell), but the team hooks are shell scripts, so
  WSL is the smoother path.
- **macOS:** open Terminal and use the same installer (`curl -fsSL https://claude.ai/install.sh | bash`), or
  Homebrew (`brew install --cask claude-code`). Install `git` and `jq` with Homebrew (`brew install git jq`).
  Everything else in this guide applies as written.

Now go to Stage 1.

---

## Stage 1 — one department, one session

You need Claude Code and a folder in git for one department of your business.

1. **Install the commands once** (see the README): `/bootstrap`, `/resume`, `/handover`, `/housekeeping` in
   `~/.claude/commands/`.
2. **Run `/bootstrap` in the department's folder.** It reports what exists, creates `docs/ISSUES.md` (and `CHANGELOG.md`
   if it has versions, as software does), and proposes a working agreement for `CLAUDE.md`. It never overwrites.
3. **Keep the drill:** `/resume` when you open a session, `/handover` before you close it (commit the result),
   `/housekeeping` once a week.
4. **Moving between machines or places?** Exit the session and resume with `claude --continue` from the same
   folder. The conversation comes back; no handover is owed for a restart. A real close — the end of the work,
   not an interruption — still gets a `/handover`.

Stay here for a week before going further. The habit is what makes the rest possible.

---

## Stage 2 — a team

### 2.1 Decide the lanes

A **lane** is one department of the business, owned by one session: its own folder in git, memory, tracker and
boundaries. Work
belonging to a lane stays in that lane. Good lanes are real, ongoing responsibilities — a product, marketing, the books,
the client websites, the office network — not tasks.

Run Stage 1 in every lane first. A lane without its own continuity cannot carry its share of a team.

### 2.2 Choose a pilot

The **pilot** coordinates: it keeps the shared log, relays findings between lanes, assembles the daily digest.
It has **no authority** — it cannot approve anything the operator would have to approve. It can be a lane
whose department is the team itself, or an existing lane that takes the role on. The pilot opens first and
closes last.

### 2.3 Create the team-state repository

One git repository, beside the departments, owned by the pilot. For example:

```
~/Company/team/             # a git repository
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
   `due-stamps.local` with the lane's periodic obligations. Run the three self-tests and check the counts.
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
- **Long-lived sessions:** a department can run for days on one conversation. From the second compaction on,
  a hook says so: at the next natural break, `/handover` and start a fresh session.
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
