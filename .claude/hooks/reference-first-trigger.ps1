# reference-first auto-activation hook (UserPromptSubmit)
# Enforces the reference-first protocol (PO decision 2026-07-17): before building any
# asset/scene/character, the reference library must be consulted. Fires when the prompt
# asks to CREATE/BUILD something visual, and injects the current library index so the
# matching topics are loaded before any modeling starts. A missing reference is not a
# blocker: it must be flagged as a gap instead.
# NOTE: keep this file ASCII-only. PowerShell 5 reads BOM-less files as ANSI and
# multi-byte characters (em-dash, accents) corrupt the parser.
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
try { $j = $raw | ConvertFrom-Json } catch { exit 0 }
$p = "$($j.prompt)".ToLower()
if ([string]::IsNullOrWhiteSpace($p)) { exit 0 }

# creation intent (verbs) + visual-asset context (nouns), both required, to avoid
# firing on code/design/doc prompts that merely mention an entity name
$create = $p -match 'crea|generar|genera|modela|modelar|construi|construy|dise[nn]a|hace(r|me)?\s|arma(r|me)?\s|build|make|model|sculpt|renderiza|render\b|animar|anima\b|rig'
$asset = $p -match 'asset|modelo|mesh|malla|escenario|escena|piso\s|mapa|bioma|paisaje|prop|personaje|character|criatura|enemigo|mob|slime|golem|boss|vfx|logo|minimapa|ui\b|inventario|blender|glb|gltf|sprite|textura|shader|vegetaci|terreno'

if ($create -and $asset) {
    $refRoot = Join-Path $env:CLAUDE_PROJECT_DIR 'game\docs\art\_references'
    $topics = (Get-ChildItem -Directory $refRoot | Select-Object -ExpandProperty Name) -join ', '
    $ctx = "Reference-first protocol (PO 2026-07-17) is MANDATORY for this build request. BEFORE modeling/rendering/iterating: (1) match the concept against the reference library topics [$topics] under game/docs/art/_references/; (2) Read the matching topics' _synthesis.md AND their images, and build FROM them, never from memory of a description; (3) if NO reference matches, say so explicitly, imagine from the corpus, and record the gap in the topic's folder. Do not skip this because the task 'seems simple'."
    $out = @{ hookSpecificOutput = @{ hookEventName = 'UserPromptSubmit'; additionalContext = $ctx } }
    $out | ConvertTo-Json -Compress -Depth 5
}
exit 0
