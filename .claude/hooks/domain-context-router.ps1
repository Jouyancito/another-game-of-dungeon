# domain-context-router (UserPromptSubmit)
#
# Loads the context of a SUBJECT domain (vegetation, mobs, boss, terrain, vfx) only
# when the prompt actually asks for work on it. Exists because a skill's declared
# "trigger automatico" is not a mechanism: the harness only shows the model a list of
# descriptions and the model decides. Measured 2026-08-08 -- godot-game-designer
# declares an automatic path trigger for Dungeon* and had not loaded after four turns
# in that very directory. A hook is the deterministic half; the skill is the payload.
#
# Firing rule, all three required:
#   1. work intent  (a verb that asks for something to be built or changed)
#   2. domain match (a noun from that domain's pattern)
#   3. no meta veto (the prompt is about the tooling, not about the subject)
#
# The veto exists because of a confirmed false positive: a prompt discussing how
# context loading should work mentioned "mobs" and "vegetacion" and pulled in the
# whole reference-first protocol. Talking ABOUT a domain is not working ON it.
#
# NOTE: keep this file ASCII-only. PowerShell 5 reads BOM-less files as ANSI and
# multi-byte characters (em-dash, accents) corrupt the parser. Accented prompt text
# is handled by writing patterns as unaccented substrings in domains.json.
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
try { $j = $raw | ConvertFrom-Json } catch { exit 0 }
$p = "$($j.prompt)".ToLower()
if ([string]::IsNullOrWhiteSpace($p)) { exit 0 }

$root = $env:CLAUDE_PROJECT_DIR
if ([string]::IsNullOrWhiteSpace($root)) { $root = "$($j.cwd)" }
if ([string]::IsNullOrWhiteSpace($root)) { exit 0 }

$cfgPath = Join-Path $root '.claude\domains.json'
if (-not (Test-Path $cfgPath)) { exit 0 }
try { $cfg = (Get-Content $cfgPath -Raw -Encoding UTF8) | ConvertFrom-Json } catch { exit 0 }

# 3) meta veto first -- cheapest way to drop a whole class of false positives
if ($p -match $cfg.meta_veto) { exit 0 }

# 1) work intent
if ($p -notmatch $cfg.work_intent) { exit 0 }

# 2) domain match, and only for domains whose skill actually exists on disk. An
# entry with no skill stays inert rather than announcing context that is not there.
$hits = @()
foreach ($d in $cfg.domains) {
    if ($p -notmatch $d.pattern) { continue }
    $skillDir = Join-Path $root (".claude\skills\" + $d.skill)
    if (-not (Test-Path (Join-Path $skillDir 'SKILL.md'))) { continue }
    $hits += $d.skill
}
if ($hits.Count -eq 0) { exit 0 }

$list = ($hits | Select-Object -Unique) -join ', '
$ctx = "Domain work detected. BEFORE planning or writing anything, invoke the Skill tool for: $list. " +
       "That skill carries this domain's build rules, canon pointers, reference topics and tests -- " +
       "read it first instead of reconstructing the domain from memory. If the prompt turns out to be " +
       "about the tooling rather than the subject, ignore this and proceed."

$out = @{ hookSpecificOutput = @{ hookEventName = 'UserPromptSubmit'; additionalContext = $ctx } }
$out | ConvertTo-Json -Compress -Depth 5
exit 0
