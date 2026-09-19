# music_dynamic — Left 4 Dead music director ("planned serendipity")

**Joan dijo (2026-08-29, textual):** "otra referencia que me llamó mucho la atención y ataca algo
que no hemos trabajado, los soundtrack. Me apareció que Valve con Left 4 Dead tiene música auto
generada, tiene unos patrones fijos que con algoritmo básico cambia y eso también cambia entre
cada jugador. Lo encontré woaaaa, me encantaría poder hacer eso, literal le da una ambientación
distinta. Serendipia calculada de Mike Morasky."

No image reference — the subject is a system, not a look. Text-only entry.

## Idea / Concepto (verified against Valve's developer commentary)

- Composer: **Mike Morasky**. Term: **"planned serendipity"** (not "calculated").
- The music is **not generated**. Every phrase is composed by hand. What is algorithmic is
  **selection + layering + volume**: a rule-set watches the player's immediate situation and
  picks which composed phrase plays, how loud, and how it transitions. Morasky's stated goal:
  design music *and* rules so that "beautiful happenstance" is likely and inappropriate cues are
  rare — most cues land as planned, a middle share are "artfully wrong", very few are bad.
- **Per-player**: each survivor hears a mix driven by *their own* state (health, incoming
  special infected, being dragged, dying). Two players in the same room hear different music.
  This is what Joan means by "cambia entre cada jugador".
- Inputs are cheap scalars (danger nearby, health, event flags), not audio analysis. The
  intelligence is in the *composition being modular* enough to recombine, not in the code.

## Qué capturar (translation to Dungeon Party)

| L4D | Dungeon Party equivalent | Cost |
|---|---|---|
| Exploration bed loops | `dungeon_ambient.wav` (placeholder, exists) | 0 |
| Danger layers fade in with threat | Layer stems by *nearest aggro'd enemy distance* + *player HP %* | small |
| Per-player stingers (special attacks you) | Stinger when a mob targets YOU; each client mixes its own | small, needs per-client audio bus |
| Boss / horde piece with states | Boss track with intro → loop → low-HP layer → death resolve | medium |
| Silence as a tool | Drop the bed after a fight ends — reward, not filler | 0 |

Rule that transfers verbatim: **write the music modular first, code second.** Without stems that
are composed to be layered (same key, same tempo, bar-aligned loops) no amount of code makes it
work.

## Engine (Godot 4.6 — native, no middleware)

Godot 4.3+ ships the three primitives this needs, verified in docs:
- `AudioStreamInteractive` — named clips (explore / combat / boss) with a transition table
  (switch on next beat / bar / end, with fade).
- `AudioStreamSynchronized` — N looping stems played in lockstep; volume per stem = the L4D
  "scalar rule-set".
- `AudioStreamPlaylist` — sequential/shuffled variation inside a state.
They nest: each Interactive clip can itself be a Synchronized stack.

## Estado actual en el repo (medido 2026-08-29)

- `game/scenes/levels/components/music_player.gd` — 18 lines, one looping track, no states.
- `game/assets/sounds/music/` — 4 placeholder wavs: `boss_theme`, `combat_loop`, `dungeon_ambient`,
  `taverna_ambient`. None are stem-split. `music_player.gd` mentions `windswept.ogg`, which is
  not in the folder (track is assigned in the inspector or missing).
- Zero design docs mention soundtrack, adaptive or dynamic music (rg over `game/docs`, control
  probe positive on `AudioStreamPlayer`).
So the gap is real: audio direction has never been designed, only a placeholder loop wired.

## Scope note

Post scope-reset filter: does this get into the 10-minute demo video? **Yes — audio is half of
"feel"**, and a two-state (explore/combat) Interactive stream with one danger stem is a day of
work once stems exist. The blocker is content (stems), not code. Do not build the system before
there is at least one track composed as stems.

## Fuente / Fecha

- Valve developer commentary, Left 4 Dead (2008) — Mike Morasky nodes on the music director.
  https://left4dead.fandom.com/wiki/Developer_Commentary_(Left_4_Dead)
- PCG wiki, "Is the music of Left4Dead procedural?" — http://pcg.wikidot.com/left4dead-music
- Godot docs: AudioStreamSynchronized / AudioStreamInteractive (4.3+).
- Captured 2026-08-29, session refs-con-contexto (continuación).
