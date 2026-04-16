# Dept Bus — detecta inbox (B/C/D) u outbox (A) nuevos.
# Invocado por SessionStart + UserPromptSubmit + Stop hooks.
# Bus dir: C:/Users/the_j/Desktop/_dept-bus (fuera de worktrees, sin git).
#
# Comportamiento por evento:
#   SessionStart / UserPromptSubmit -> output systemMessage (info, no fuerza accion).
#   Stop                            -> output decision:block (fuerza al agente a continuar
#                                      con el contenido del inbox/outbox como nuevo input).
#
# Marker files {bus}/.seen-* evitan re-mostrar el mismo mensaje.

$ErrorActionPreference = 'SilentlyContinue'

$bus = 'C:\Users\the_j\Desktop\_dept-bus'
if (-not (Test-Path $bus)) {
    New-Item -ItemType Directory -Path $bus -Force | Out-Null
    exit 0
}

# Parse Claude hook JSON desde stdin: cwd + hook_event_name.
$cwd = ''
$event = ''
try {
    $input_json = [Console]::In.ReadToEnd()
    if ($input_json) {
        $hook = $input_json | ConvertFrom-Json
        if ($hook.cwd) { $cwd = $hook.cwd }
        elseif ($hook.workspace -and $hook.workspace.current_dir) { $cwd = $hook.workspace.current_dir }
        if ($hook.hook_event_name) { $event = $hook.hook_event_name }
    }
} catch {}
if (-not $cwd) { $cwd = (Get-Location).Path }

$letter = '?'
if ($cwd -match 'DungeonParty-([ABCD])') { $letter = $Matches[1] }
if ($letter -eq '?') { exit 0 }

# Stop hook con stop_hook_active=true significa que ya forzamos block antes
# y el agente esta re-procesando -> NO re-bloquear (loop infinito).
if ($event -eq 'Stop' -and $hook.stop_hook_active -eq $true) { exit 0 }

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
    $body = ($parts -join "`n`n---`n`n")

    if ($event -eq 'Stop') {
        # Forzar continuacion: el agente recibe esto como instruccion nueva
        # en lugar de terminar el turn.
        $reason = "[DEPT-BUS auto-resume] Mensaje nuevo detectado al cierre del turn. Procesa este contenido como tarea/handoff:`n`n" + $body
        $out = @{ decision = "block"; reason = $reason } | ConvertTo-Json -Compress
    } else {
        # Solo notificar (SessionStart / UserPromptSubmit).
        $intro = "[DEPT-BUS] Mensajes nuevos detectados. Leelos y actua:`n`n"
        $out = @{ systemMessage = ($intro + $body) } | ConvertTo-Json -Compress
    }
    Write-Output $out
}
