"""Dungeon Party Discord bot CLI — channel/thread management + dev timeline.

Zero dependencies (stdlib only). Reads DISCORD_BOT_TOKEN and optional
DISCORD_GUILD_ID from tools/discord/.env (KEY=VALUE lines).

Usage:
  python dp_discord.py guilds                       # list servers the bot is in
  python dp_discord.py channels                     # list channels in the guild
  python dp_discord.py create-category <name>
  python dp_discord.py create-channel <name> [--category <category-name>]
  python dp_discord.py delete-channel <name>
  python dp_discord.py post <channel-name> <message>
  python dp_discord.py create-thread <channel-name> <thread-name> <first-message>
  python dp_discord.py thread-post <thread-name> <message>
  python dp_discord.py post-file <channel-name> <utf8-file>     # post file contents
  python dp_discord.py post-attachment <channel-name> <file> [message]  # upload a real file
  python dp_discord.py timeline [--days N] [--channel <name>] [--repo <path>]
  python dp_discord.py devlog <file.md> [--channel <name>] [--dry-run]
      Posts only entries ticked '[x]' by a human who checked them in a build.
"""
import json
import os
import re
import subprocess
import sys
import time
import urllib.request

sys.stdout.reconfigure(encoding="utf-8")  # Windows consoles default to cp1252

API = "https://discord.com/api/v10"
HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))


def load_env():
    path = os.path.join(HERE, ".env")
    if os.path.exists(path):
        for line in open(path, encoding="utf-8"):
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())


def api(method, path, body=None):
    req = urllib.request.Request(
        API + path,
        data=json.dumps(body).encode() if body is not None else None,
        method=method,
        headers={
            "Authorization": "Bot " + os.environ["DISCORD_BOT_TOKEN"],
            "Content-Type": "application/json",
            "User-Agent": "DungeonPartyBot (https://github.com/Jouyancito/another-game-of-dungeon, 1.0)",
        },
    )
    try:
        with urllib.request.urlopen(req) as r:
            data = r.read()
            return json.loads(data) if data else None
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")
        if e.code == 429:  # rate limited: wait and retry once
            retry = json.loads(detail).get("retry_after", 1)
            time.sleep(retry + 0.5)
            return api(method, path, body)
        sys.exit(f"Discord API {e.code} on {method} {path}: {detail}")


def upload_attachment(channel_id, file_path, content=""):
    """POST a binary file to a channel as a real attachment (multipart/form-data).

    api() only speaks JSON; Discord needs multipart for file uploads, so the body
    is assembled by hand to keep this module dependency-free.
    """
    name = os.path.basename(file_path)
    with open(file_path, "rb") as fh:
        blob = fh.read()
    boundary = "----dpBoundary" + str(int(time.time() * 1000))
    payload = json.dumps({"content": content, "attachments": [{"id": 0, "filename": name}]})
    sep = ("--" + boundary).encode()
    body = b"\r\n".join([
        sep,
        b'Content-Disposition: form-data; name="payload_json"',
        b"Content-Type: application/json",
        b"",
        payload.encode("utf-8"),
        sep,
        f'Content-Disposition: form-data; name="files[0]"; filename="{name}"'.encode("utf-8"),
        b"Content-Type: application/octet-stream",
        b"",
        blob,
        ("--" + boundary + "--\r\n").encode(),
    ])
    req = urllib.request.Request(
        f"{API}/channels/{channel_id}/messages",
        data=body,
        method="POST",
        headers={
            "Authorization": "Bot " + os.environ["DISCORD_BOT_TOKEN"],
            "Content-Type": "multipart/form-data; boundary=" + boundary,
            "User-Agent": "DungeonPartyBot (https://github.com/Jouyancito/another-game-of-dungeon, 1.0)",
        },
    )
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        sys.exit(f"Discord upload {e.code}: {e.read().decode(errors='replace')}")


def guild_id():
    gid = os.environ.get("DISCORD_GUILD_ID")
    if gid:
        return gid
    guilds = api("GET", "/users/@me/guilds")
    if len(guilds) == 1:
        return guilds[0]["id"]
    sys.exit("Bot is in multiple guilds; set DISCORD_GUILD_ID in .env:\n"
             + "\n".join(f"  {g['id']}  {g['name']}" for g in guilds))


def channels():
    return api("GET", f"/guilds/{guild_id()}/channels")


def find_channel(name, types=(0, 4, 5, 15)):
    name = name.lstrip("#").lower()
    for c in channels():
        if c["name"].lower() == name and c["type"] in types:
            return c
    sys.exit(f"Channel not found: {name}")


def find_thread(name):
    threads = api("GET", f"/guilds/{guild_id()}/threads/active").get("threads", [])
    name = name.lower()
    for t in threads:
        if t["name"].lower() == name:
            return t
    sys.exit(f"Active thread not found: {name}")


def post_message(channel_id, content):
    # Discord caps messages at 2000 chars; split on line boundaries.
    while content:
        chunk = content[:2000]
        if len(content) > 2000:
            cut = chunk.rfind("\n")
            if cut > 0:
                chunk = chunk[:cut]
        api("POST", f"/channels/{channel_id}/messages", {"content": chunk})
        content = content[len(chunk):].lstrip("\n")


def git_timeline(days, repo=REPO_ROOT):
    out = subprocess.run(
        ["git", "-C", repo, "log", f"--since={days} days ago",
         "--pretty=%ad|%s", "--date=format:%Y-%m-%d"],
        capture_output=True, text=True, check=True).stdout.strip()
    if not out:
        return None
    by_day = {}
    for line in out.splitlines():
        day, subject = line.split("|", 1)
        by_day.setdefault(day, []).append(subject)
    parts = [f"**Dev timeline — last {days} days**"]
    for day in sorted(by_day, reverse=True):
        parts.append(f"\n**{day}**")
        parts += [f"- {s}" for s in by_day[day]]
    return "\n".join(parts)


def parse_devlog(path):
    """Parse a devlog source file into one entry per '## ' heading.

    `timeline` posts raw commit subjects, which read like `feat(worldgen): mine
    timber framing for the floor-1 entrance` — accurate, and useless to anyone
    scanning for what actually changed. A devlog entry carries both audiences:
    a title you can filter by, a plain sentence for players, and an optional
    technical note for whoever reads code.

        ## [ ] Title anyone can scan
        One or more plain lines. What changed, in words a player understands.
        @ Where to see it: how to reach it in a running build.
        > Technical detail. Files, systems, numbers. Optional, repeatable.

    Two rules exist because a devlog is a public claim, not a work log:

    - The '@ ' line is REQUIRED. An entry that cannot be checked in a running
      build is an assertion about intent, not about the game. Owner's words:
      "si colocás que se mejoró el pasto, pero cuando entro no veo eso, es una
      falacia o pensamiento netamente tuyo."
    - The checkbox gates posting. '[ ]' means written but unverified; only
      '[x]' — ticked by a human who looked at the build — is publishable.

    Blank lines separate paragraphs; '>' lines become the technical block.
    """
    entries, current = [], None
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            if line.startswith("## "):
                if current:
                    entries.append(current)
                title = line[3:].strip()
                approved = False
                mark = re.match(r"^\[([ xX])\]\s*(.*)$", title)
                if mark:
                    approved = mark.group(1).lower() == "x"
                    title = mark.group(2).strip()
                current = {"title": title, "approved": approved, "checkbox": bool(mark),
                           "plain": [], "where": [], "tech": []}
            elif current is None:
                continue  # preamble before the first heading is ignored
            elif line.startswith(">"):
                current["tech"].append(line.lstrip("> ").rstrip())
            elif line.startswith("@ "):
                current["where"].append(line[2:].strip())
            else:
                current["plain"].append(line.rstrip())
    if current:
        entries.append(current)

    for e in entries:
        e["plain"] = "\n".join(e["plain"]).strip()
        e["where"] = " ".join(e["where"]).strip()
        e["tech"] = "\n".join(e["tech"]).strip()

    problems = []
    for e in entries:
        if not e["plain"]:
            problems.append(f"{e['title']!r}: title with no plain-language body")
        if not e["where"]:
            problems.append(f"{e['title']!r}: missing '@ ' line — say where to see it in the build")
        if not e["checkbox"]:
            problems.append(f"{e['title']!r}: missing '[ ]'/'[x]' checkbox in the heading")
    if problems:
        sys.exit("Devlog entries are not postable:\n  " + "\n  ".join(problems))
    return entries


def render_devlog(entry):
    out = "## " + entry["title"]
    if entry["plain"]:
        out += "\n" + entry["plain"]
    if entry["where"]:
        out += "\n*Dónde verlo: " + entry["where"] + "*"
    if entry["tech"]:
        # Blockquote keeps the technical half visually secondary, so a reader
        # who does not code can skip it without losing the entry.
        out += "\n" + "\n".join("> " + ln if ln else ">" for ln in entry["tech"].splitlines())
    return out


def main():
    load_env()
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    cmd, rest = args[0], args[1:]
    # A dry run only formats text, so it must work without credentials.
    offline = cmd == "devlog" and "--dry-run" in rest
    if not offline and "DISCORD_BOT_TOKEN" not in os.environ:
        sys.exit("Missing DISCORD_BOT_TOKEN — copy .env.example to .env and fill it in.")

    if cmd == "guilds":
        for g in api("GET", "/users/@me/guilds"):
            print(g["id"], g["name"])
    elif cmd == "channels":
        cats = {c["id"]: c["name"] for c in channels() if c["type"] == 4}
        for c in sorted(channels(), key=lambda c: (c.get("parent_id") or "", c["position"])):
            kind = {0: "text", 2: "voice", 4: "category", 15: "forum"}.get(c["type"], c["type"])
            parent = cats.get(c.get("parent_id"), "")
            print(f"{c['id']}  [{kind:8}] {parent + '/' if parent else ''}{c['name']}")
    elif cmd == "create-category":
        c = api("POST", f"/guilds/{guild_id()}/channels", {"name": rest[0], "type": 4})
        print("Created category:", c["name"], c["id"])
    elif cmd == "create-channel":
        body = {"name": rest[0], "type": 0}
        if "--category" in rest:
            body["parent_id"] = find_channel(rest[rest.index("--category") + 1], types=(4,))["id"]
        c = api("POST", f"/guilds/{guild_id()}/channels", body)
        print("Created channel:", c["name"], c["id"])
    elif cmd == "delete-channel":
        c = find_channel(rest[0])
        api("DELETE", f"/channels/{c['id']}")
        print("Deleted channel:", c["name"])
    elif cmd == "post":
        post_message(find_channel(rest[0])["id"], rest[1])
        print("Posted to", rest[0])
    elif cmd == "create-thread":
        t = api("POST", f"/channels/{find_channel(rest[0])['id']}/threads",
                {"name": rest[1], "type": 11, "auto_archive_duration": 10080})
        post_message(t["id"], rest[2])
        print("Created thread:", t["name"], t["id"])
    elif cmd == "thread-post":
        post_message(find_thread(rest[0])["id"], rest[1])
        print("Posted to thread", rest[0])
    elif cmd == "post-file":
        content = open(rest[1], encoding="utf-8").read().strip()
        post_message(find_channel(rest[0])["id"], content)
        print("Posted file to", rest[0])
    elif cmd == "post-attachment":
        message = rest[2] if len(rest) > 2 else ""
        upload_attachment(find_channel(rest[0])["id"], rest[1], message)
        print("Uploaded", os.path.basename(rest[1]), "to", rest[0])
    elif cmd == "timeline":
        days = int(rest[rest.index("--days") + 1]) if "--days" in rest else 14
        channel = rest[rest.index("--channel") + 1] if "--channel" in rest else "devlog"
        repo = rest[rest.index("--repo") + 1] if "--repo" in rest else REPO_ROOT
        text = git_timeline(days, repo)
        if not text:
            sys.exit(f"No commits in the last {days} days.")
        post_message(find_channel(channel)["id"], text)
        print(f"Timeline ({days} days) posted to #{channel}")
    elif cmd == "devlog":
        if not rest:
            sys.exit("devlog needs a source file. See --help.")
        channel = rest[rest.index("--channel") + 1] if "--channel" in rest else "devlog"
        entries = parse_devlog(rest[0])
        if not entries:
            sys.exit(f"No '## ' entries found in {rest[0]}.")
        approved = [e for e in entries if e["approved"]]
        pending = [e for e in entries if not e["approved"]]
        if "--dry-run" in rest:
            # Preview without a token, so an entry can be proofread — and
            # checked against a running build — before it reaches the server.
            for e in entries:
                print(("[x] " if e["approved"] else "[ ] ") + "-" * 56)
                print(render_devlog(e))
            print(f"\n{len(approved)} approved, {len(pending)} awaiting review.")
            if pending:
                print("Pending: " + ", ".join(e["title"] for e in pending))
            print(f"Would post the {len(approved)} approved to #{channel}")
            return
        if not approved:
            sys.exit(f"Nothing approved in {rest[0]}. Tick '[x]' on the entries you "
                     "checked in a running build. Nothing was posted.")
        cid = find_channel(channel)["id"]
        for e in approved:
            # One message per entry: Discord shows each as its own block, so the
            # channel stays scannable by title instead of one wall of text.
            post_message(cid, render_devlog(e))
        print(f"Posted {len(approved)} devlog entries to #{channel}"
              + (f"; {len(pending)} left unapproved" if pending else ""))
    else:
        sys.exit(f"Unknown command: {cmd}\n{__doc__}")


if __name__ == "__main__":
    main()
