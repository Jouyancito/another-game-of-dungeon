# Dept Bus — detecta inbox (B/C/D) u outbox (A) nuevos y los muestra al agente.
# Invocado por SessionStart + UserPromptSubmit hooks.
# Bus dir: C:/Users/the_j/Desktop/_dept-bus (fuera de worktrees, sin git).
#
# Protocolo:
#   A escribe a {bus}/inbox-{b,c,d}.md  -> B/C/D ven en su hook
#   B/C/D escriben a {bus}/outbox-{b,c,d}.md -> A ve en su hook
#
# Marker files {bus}/.seen-* evitan re-mostrar el mismo mensaje.

$ErrorActionPreference = 'SilentlyContinue'

$bus = 'C:\Users\the_j\Desktop\_dept-bus'
if (-not (Test-Path $bus)) {
    New-Item -ItemType Directory -Path $bus -Force | Out-Null
    exit 0
}

# Detectar worktree desde stdin (Claude hook JSON) o cwd fallback.
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

$letter = '?'
if ($cwd -match 'DungeonParty-([ABCD])') { $letter = $Matches[1] }
if ($letter -eq '?') { exit 0 }

function Check-BusFile {
    param($path, $markerPath, $label)
    if (-not (Test-Path $path)) { return $null }
    $mtime = (Get-Item $path).LastWriteTimeUtc.Ticks
    $seen = 0
    if (Test-Path $markerPath) {
        try { $seen = [long]((Get-Content $markerPath -Raw).Trim()) } catch { $seen = 0 }
    }
    if ($mtime -le $seen) { return $null }
    $content = Get-Content $path -Raw
    Set-Content -Path $markerPath -Value "$mtime" -NoNewline
    return "=== $label ===`n$content"
}

$parts = @()
if ($letter -eq 'A') {
    foreach ($code in 'b','c','d') {
        $msg = Check-BusFile "$bus\outbox-$code.md" "$bus\.seen-outbox-$code-by-A.txt" "HANDOFF $($code.ToUpper()) -> A ($bus\outbox-$code.md)"
        if ($msg) { $parts += $msg }
    }
} else {
    $code = $letter.ToLower()
    $msg = Check-BusFile "$bus\inbox-$code.md" "$bus\.seen-inbox-$code.txt" "TAREA A -> $letter ($bus\inbox-$code.md)"
    if ($msg) { $parts += $msg }
}

if ($parts.Count -gt 0) {
    $intro = "[DEPT-BUS] Mensajes nuevos detectados. Leelos y actua:`n`n"
    $body = $intro + ($parts -join "`n`n---`n`n")
    $out = @{ systemMessage = $body } | ConvertTo-Json -Compress
    Write-Output $out
}
