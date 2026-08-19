# Discord tooling — Dungeon Party

CLI for managing the Dungeon Party Discord server from the dev environment:
channels, threads, posts, and a git-based dev timeline. Stdlib only, no
dependencies.

## One-time setup (human steps)

1. Go to https://discord.com/developers/applications > **New Application** >
   name it (e.g. `Dungeon Party Dev`).
2. **Bot** tab > **Reset Token** > copy the token.
3. Invite the bot to the server with this URL (replace `APP_ID` with the
   Application ID from the **General Information** tab):

   ```
   https://discord.com/oauth2/authorize?client_id=APP_ID&scope=bot&permissions=326417632272
   ```

   The permissions integer covers: Manage Channels, View Channels, Send
   Messages, Embed Links, Attach Files, Read Message History, Manage Threads,
   Create Public Threads, Send Messages in Threads.
4. `cp env.example .env` and paste the token into `DISCORD_BOT_TOKEN`.

## Usage

```
python dp_discord.py channels                                  # list channels
python dp_discord.py create-category "desarrollo"
python dp_discord.py create-channel piso-1 --category desarrollo
python dp_discord.py create-thread piso-1 "golem" "Work thread for the golem miniboss"
python dp_discord.py post devlog "v17 render is out"
python dp_discord.py timeline --days 30 --channel devlog       # git log -> post
python dp_discord.py devlog devlog_pending.md --dry-run        # preview entries
python dp_discord.py devlog devlog_pending.md                  # posts only [x]
```

`timeline` groups the repo's commits by day and posts them, newest first.
Messages longer than Discord's 2000-char cap are split on line boundaries.

## timeline vs devlog

`timeline` posts commit subjects verbatim — `feat(worldgen): mine timber
framing for the floor-1 entrance`. Accurate, free, and hard to skim for anyone
who did not write it.

`devlog` posts hand-written entries that carry both audiences at once. Source
format, one entry per `## ` heading:

```markdown
## [ ] Title anyone can scan
Plain lines: what changed, in words a player understands.
@ How to reach it in a running build.
> Quoted lines: the technical half. Files, systems, numbers. Optional.
```

Each entry is posted as its own Discord message, so the channel stays
filterable by title. The `>` block renders as a blockquote, visually secondary,
so a reader who does not code can skip it without losing the entry.

### Two rules, because a devlog is a public claim

**Entries accumulate; they are not posted per change.** Reaching one result
often takes several commits, and a message per commit turns the channel into a
git log nobody reads. Entries land in `devlog_pending.md` during the session
and go out in one batch at session close.

**Nothing posts without human verification.** Every entry needs an `@ ` line
saying where to see the change in a running build, and a checkbox that starts
`[ ]`. Only `[x]` entries are posted, and only the owner ticks them — after
loading the build and looking at the thing. An agent writing "the grass looks
better" and posting it is asserting its own intent, not a fact about the game.

Rejected at parse time: an entry with no plain-language body, with no `@ ` line,
or with no checkbox. Running `devlog` with nothing approved posts nothing and
exits non-zero.

`--dry-run` prints the rendered entries with their approval state and posts
nothing; it needs no token, so entries can be proofread against the build
before they reach the server.

See `devlog_pending.md` — it is both the staging file and the worked example.
