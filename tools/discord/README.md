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
```

`timeline` groups the repo's commits by day and posts them, newest first.
Messages longer than Discord's 2000-char cap are split on line boundaries.
