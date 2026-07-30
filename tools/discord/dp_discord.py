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
  python dp_discord.py timeline [--days N] [--channel <name>] [--repo <path>]
"""
import json
import os
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


def main():
    load_env()
    if "DISCORD_BOT_TOKEN" not in os.environ:
        sys.exit("Missing DISCORD_BOT_TOKEN — copy .env.example to .env and fill it in.")
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    cmd, rest = args[0], args[1:]

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
    elif cmd == "timeline":
        days = int(rest[rest.index("--days") + 1]) if "--days" in rest else 14
        channel = rest[rest.index("--channel") + 1] if "--channel" in rest else "devlog"
        repo = rest[rest.index("--repo") + 1] if "--repo" in rest else REPO_ROOT
        text = git_timeline(days, repo)
        if not text:
            sys.exit(f"No commits in the last {days} days.")
        post_message(find_channel(channel)["id"], text)
        print(f"Timeline ({days} days) posted to #{channel}")
    else:
        sys.exit(f"Unknown command: {cmd}\n{__doc__}")


if __name__ == "__main__":
    main()
