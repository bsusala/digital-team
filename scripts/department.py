#!/usr/bin/env python3
"""Pack a department into one zip, to move it to another computer or keep a copy.

  python3 department.py pack <folder> [--out <dir>]
  python3 department.py --selftest

The zip holds four things:
  department/   the folder exactly as it is: files, git history, uncommitted and untracked work
  claude/       what Claude Code keeps about the folder outside it, in ~/.claude/projects/<name>/
                (memory and conversations), if there is any
  HOW-TO.md     what the zip holds and how to put it back by hand
  MANIFEST.txt  where it came from, and what the zip found about git and team rules

Never packed: anything else under ~/.claude, the Claude Code sign-in included.
Exit: 0 packed (or self-test passed), 1 refused or failed.
"""
import argparse
import datetime
import getpass
import os
import re
import socket
import stat
import subprocess
import sys
import tempfile
import zipfile

TEAM_BLOCK = "## Team rules — binding at session start"


def claude_name(path):
    """The name Claude Code gives a folder under ~/.claude/projects/: its path, '-' for every other character."""
    return re.sub(r"[^A-Za-z0-9]", "-", path)


def git_state(folder):
    def run(*args):
        r = subprocess.run(["git", "-C", folder, *args], capture_output=True, text=True)
        return r.returncode, r.stdout.strip()

    if not os.path.isdir(os.path.join(folder, ".git")):
        return "not a git repository"
    rc, count = run("rev-list", "--count", "--all")
    commits = int(count) if rc == 0 and count.isdigit() else 0
    rc, status = run("status", "--porcelain")
    changed = len(status.splitlines()) if rc == 0 else -1
    head = "no commits yet" if commits == 0 else f"{commits} commit(s)"
    return f"{head}, {changed} uncommitted or untracked path(s)"


def team_state(folder):
    found = []
    claude_md = os.path.join(folder, "CLAUDE.md")
    if os.path.isfile(claude_md):
        with open(claude_md, encoding="utf-8", errors="replace") as f:
            if TEAM_BLOCK in f.read():
                found.append("CLAUDE.md carries the team block")
    for rel in (".claude/hooks", ".claude/team.conf"):
        if os.path.exists(os.path.join(folder, rel)):
            found.append(f"{rel} present")
    return "; ".join(found) if found else "no team rules found (a single department)"


def add_tree(zf, source, prefix, skipped):
    count = 0
    for root, dirs, files in os.walk(source, followlinks=False):
        dirs.sort()
        for name in sorted(files) + [d for d in dirs if os.path.islink(os.path.join(root, d))]:
            full = os.path.join(root, name)
            rel = os.path.relpath(full, source)
            if os.path.islink(full):
                skipped.append(f"{prefix}/{rel} (symbolic link, not followed)")
                continue
            if not stat.S_ISREG(os.lstat(full).st_mode):
                skipped.append(f"{prefix}/{rel} (not a regular file)")
                continue
            info = zipfile.ZipInfo.from_file(full, f"{prefix}/{rel}")
            info.compress_type = zipfile.ZIP_DEFLATED
            with open(full, "rb") as f:
                zf.writestr(info, f.read())
            count += 1
    return count


HOW_TO = """# What this zip holds

A department packed by `department.py pack`, from `{source}` on {host}, {created}.

- `department/` — the folder exactly as it was: its files, its git history, and work not yet committed.
- `claude/` — what Claude Code remembered about the folder (memory and conversations). {claude_line}
- `MANIFEST.txt` — the details.

**Treat this zip like the computer it came from.** It holds your conversations with Claude, and anything
you pasted into them. Delete it once the move is done.

# Putting it back by hand

1. Unzip it somewhere temporary:

   ```bash
   unzip {zipname} -d ~/unpacked
   ```

2. Move the department into place (here, back into the company folder):

   ```bash
   mv ~/unpacked/department ~/Company/{dept}
   ```

3. Make the folder where Claude Code keeps what it remembers:

   ```bash
   mkdir -p ~/.claude/projects
   ```

4. Find the name Claude Code expects for the new place: the folder's full path with `-` in place of every
   `/` (and of any character that is not a letter or a digit). For `/home/<you>/Company/{dept}` it is
   `-home-<you>-Company-{dept}`. Move Claude's part there:

   ```bash
   mv ~/unpacked/claude ~/.claude/projects/-home-$USER-Company-{dept}
   ```

5. Go into the department and continue the last conversation:

   ```bash
   cd ~/Company/{dept}
   ```

   ```bash
   claude --continue
   ```

6. Remove the temporary folder:

   ```bash
   rm -rf ~/unpacked
   ```

Team rules travel inside the department (its `CLAUDE.md` and `.claude/` folder), but they bind only after
you ratify them again in the department's own session, on the new computer.
"""


def pack(folder, out_dir, home=None, projects_dir=None, now=None):
    home = home or os.path.expanduser("~")
    projects_dir = projects_dir or os.path.join(home, ".claude", "projects")
    folder = os.path.realpath(folder)
    if not os.path.isdir(folder):
        print(f"department.py: not a folder: {folder}", file=sys.stderr)
        return 1, None
    out_dir = os.path.realpath(out_dir)
    if out_dir == folder or out_dir.startswith(folder + os.sep):
        print("department.py: the zip would land inside the folder it packs; choose --out elsewhere", file=sys.stderr)
        return 1, None
    os.makedirs(out_dir, exist_ok=True)

    now = now or datetime.datetime.now(datetime.timezone.utc)
    stamp = now.strftime("%Y%m%dT%H%MZ")
    dept = os.path.basename(folder)
    zip_path = os.path.join(out_dir, f"{dept}-{stamp}.zip")
    if os.path.exists(zip_path):
        print(f"department.py: {zip_path} exists; not overwritten", file=sys.stderr)
        return 1, None

    cname = claude_name(folder)
    claude_dir = os.path.join(projects_dir, cname)
    has_claude = os.path.isdir(claude_dir)
    skipped = []
    partial = zip_path + ".partial"
    try:
        with zipfile.ZipFile(partial, "w") as zf:
            n_dept = add_tree(zf, folder, "department", skipped)
            n_claude = add_tree(zf, claude_dir, "claude", skipped) if has_claude else 0
            created = now.strftime("%Y-%m-%dT%H:%MZ")
            host = socket.gethostname()
            manifest = [
                f"source: {folder}",
                f"claude-name: {cname}",
                f"user: {getpass.getuser()}",
                f"host: {host}",
                f"created: {created}",
                f"git: {git_state(folder)}",
                f"team: {team_state(folder)}",
                f"files: department {n_dept}, claude {n_claude}",
                "claude-part: " + ("packed" if has_claude else f"none found at {claude_dir}"),
            ] + [f"skipped: {s}" for s in skipped]
            zf.writestr("MANIFEST.txt", "\n".join(manifest) + "\n")
            claude_line = ("" if has_claude else
                           "Empty here: Claude Code had kept nothing for this folder.")
            zf.writestr("HOW-TO.md", HOW_TO.format(
                source=folder, host=host, created=created, zipname=os.path.basename(zip_path),
                dept=dept, claude_line=claude_line))
        os.chmod(partial, 0o600)
        os.rename(partial, zip_path)
    except Exception as e:
        if os.path.exists(partial):
            os.remove(partial)
        print(f"department.py: packing failed: {e}", file=sys.stderr)
        return 1, None

    print(f"packed: {zip_path}")
    print(f"  department: {n_dept} files ({git_state(folder)})")
    print(f"  claude: {n_claude} files" if has_claude else f"  claude: nothing kept for this folder ({cname})")
    print(f"  team: {team_state(folder)}")
    for s in skipped:
        print(f"  skipped: {s}")
    print("  The zip holds your conversations with Claude: keep it private, delete it after the move.")
    return 0, zip_path


def selftest():
    passed = failed = 0

    def check(name, cond):
        nonlocal passed, failed
        if cond:
            passed += 1
        else:
            failed += 1
            print(f"FAIL {name}", file=sys.stderr)

    with tempfile.TemporaryDirectory() as t:
        home = os.path.join(t, "home")
        dept = os.path.join(home, "Company", "sign.age")
        os.makedirs(os.path.join(dept, "docs"))
        with open(os.path.join(dept, "CLAUDE.md"), "w") as f:
            f.write("# x\n" + TEAM_BLOCK + "\n")
        with open(os.path.join(dept, "docs", "ISSUES.md"), "w") as f:
            f.write("open\n")
        os.symlink("/etc/passwd", os.path.join(dept, "link"))
        subprocess.run(["git", "init", "-q", dept], check=True)
        projects = os.path.join(home, ".claude", "projects")
        cdir = os.path.join(projects, claude_name(os.path.realpath(dept)))
        os.makedirs(os.path.join(cdir, "memory"))
        with open(os.path.join(cdir, "s1.jsonl"), "w") as f:
            f.write("{}\n")
        with open(os.path.join(home, ".claude", ".credentials.json"), "w") as f:
            f.write("SECRET\n")
        out = os.path.join(t, "out")
        fixed = datetime.datetime(2026, 11, 2, 19, 0, tzinfo=datetime.timezone.utc)

        check("name: every non-alphanumeric becomes '-'", claude_name("/home/user/Company/sign.age") == "-home-user-Company-sign-age")

        rc, z = pack(dept, out, home=home, projects_dir=projects, now=fixed)
        check("pack: exit 0", rc == 0 and z is not None)
        names = zipfile.ZipFile(z).namelist() if z else []
        check("pack: untracked work in a repo with no commits is packed", "department/docs/ISSUES.md" in names)
        check("pack: git history is packed", any(n.startswith("department/.git/") for n in names))
        check("pack: Claude's part is packed", "claude/s1.jsonl" in names)
        check("pack: the sign-in is never packed", not any("credentials" in n for n in names))
        check("pack: a symbolic link is not followed", "department/link" not in names)
        manifest = zipfile.ZipFile(z).read("MANIFEST.txt").decode() if z else ""
        check("manifest: names the skipped link and why", "skipped: department/link (symbolic link" in manifest)
        check("manifest: reads the team block", "CLAUDE.md carries the team block" in manifest)
        check("manifest: no commits stated", "no commits yet" in manifest)
        check("zip: private (0600)", z is not None and stat.S_IMODE(os.stat(z).st_mode) == 0o600)

        rc, _ = pack(dept, out, home=home, projects_dir=projects, now=fixed)
        check("refuses: an existing zip is never overwritten", rc == 1)
        rc, _ = pack(os.path.join(home, "missing"), out, home=home, projects_dir=projects, now=fixed)
        check("refuses: a folder that does not exist", rc == 1)
        rc, _ = pack(dept, os.path.join(dept, "inside"), home=home, projects_dir=projects, now=fixed)
        check("refuses: a zip inside the folder it packs", rc == 1)

        other = os.path.join(home, "Company", "empty")
        os.makedirs(other)
        rc, z2 = pack(other, out, home=home, projects_dir=projects, now=fixed)
        m2 = zipfile.ZipFile(z2).read("MANIFEST.txt").decode() if z2 else ""
        check("pack: no Claude part is stated, not hidden", rc == 0 and "claude-part: none found" in m2)
        check("pack: a folder outside git is stated", "not a git repository" in m2)

    print(f"department.py selftest: {passed} passed, {failed} failed")
    return 0 if failed == 0 else 1


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--selftest":
        return selftest()
    p = argparse.ArgumentParser(prog="department.py")
    sub = p.add_subparsers(dest="cmd", required=True)
    pk = sub.add_parser("pack", help="pack a department into one zip")
    pk.add_argument("folder", nargs="?", default=".")
    pk.add_argument("--out", default=os.path.expanduser("~"), help="where the zip goes (default: your home folder)")
    a = p.parse_args()
    if a.cmd == "pack":
        rc, _ = pack(a.folder, a.out)
        return rc
    return 1


if __name__ == "__main__":
    sys.exit(main())
