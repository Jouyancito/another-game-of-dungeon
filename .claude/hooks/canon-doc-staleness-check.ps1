# Canon Doc Staleness Check
# Compara mtime de canon docs vs CLAUDE.md raíz.
# Si algún canon doc es más nuevo que CLAUDE.md → emite systemMessage avisando actualizar.
# Marker file evita re-warning misma stale.
#
# Trigger: SessionStart + UserPromptSubmit.

$ErrorActionPreference = 'SilentlyContinue'

$cwd = ''
try {
    $input_json = [Console]::In.ReadToEnd()
    if ($input_json) {
        $hook = $input_json | ConvertFrom-Json
        if ($hook.cwd) { $cwd = $hook.cwd }
        elseif ($hook.workspace -and $hook.workspace.current_dir) { $cwd = $hook.workspace.current_dir }
    }
} catch {}
if (-not $cwd) { $cwd = (Get-Location).Path }

# Solo correr en worktree A (master). B/C/D no necesitan este check.
if ($cwd -notmatch 'DungeonParty-A') { exit 0 }

$claudeMd = Join-Path $cwd 'CLAUDE.md'
if (-not (Test-Path $claudeMd)) { exit 0 }

$claudeMtime = (Get-Item $claudeMd).LastWriteTimeUtc

# Lista de canon docs a vigilar (paths relativos al cwd).
$canonDocs = @(
    'game/docs/skills/_system.md',
    'game/docs/skills/_synergies.md',
    'game/docs/skills/_status_effects.md',
    'game/docs/skills/warrior.md',
    'game/docs/skills/mage.md',
    'game/docs/skills/archer.md',
    'game/docs/skills/cleric.md',
    'game/docs/skills/necromancer.md',
    'game/docs/skills/danzante_sombras.md',
    'game/docs/balance_v2.md',
    'game/docs/balance/_drop_ownership_canon.md',
    'game/docs/balance/_mimic.md',
    'game/docs/balance/p1_loot_table.md',
    'PROJECT_STATE.md',
    'GDD_DungeonParty.md'
)

$stale = @()
foreach ($rel in $canonDocs) {
    $full = Join-Path $cwd $rel
    if (-not (Test-Path $full)) { continue }
    $mt = (Get-Item $full).LastWriteTimeUtc
    if ($mt -gt $claudeMtime) {
        $delta = [math]::Round(($mt - $claudeMtime).TotalHours, 1)
        $stale += "  - $rel  (+${delta}h newer)"
    }
}

if ($stale.Count -eq 0) { exit 0 }

# Marker para no spamear: si ya avisamos en este estado (hash de stale list), skip.
$stateDir = Join-Path $cwd '.claude'
$markerFile = Join-Path $stateDir '.canon-staleness-seen.txt'
$currentHash = ($stale -join "`n")
$seenHash = ''
if (Test-Path $markerFile) {
    try { $seenHash = Get-Content $markerFile -Raw } catch { $seenHash = '' }
}
if ($currentHash -eq $seenHash.Trim()) { exit 0 }
Set-Content -Path $markerFile -Value $currentHash -NoNewline

$body = "[CANON-STALENESS] CLAUDE.md más viejo que estos canon docs (mtime newer):`n"
$body += ($stale -join "`n")
$body += "`n`nConsidera actualizar CLAUDE.md con surgicales (no rewrite) para reflejar canon vigente."

$out = @{ systemMessage = $body } | ConvertTo-Json -Compress
Write-Output $out
