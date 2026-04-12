# Statusline para Claude Code — muestra identidad del worktree.
# Leido por .claude/settings.json -> statusLine.command
# Output: una linea con [LETTER] color + branch + estado task.

$ErrorActionPreference = 'SilentlyContinue'

# Leer JSON del hook de Claude Code (stdin)
$input_json = [Console]::In.ReadToEnd()
if ($input_json) {
    try {
        $hook = $input_json | ConvertFrom-Json
        $cwd = $hook.workspace.current_dir
    } catch {
        $cwd = (Get-Location).Path
    }
} else {
    $cwd = (Get-Location).Path
}

if (-not $cwd) { $cwd = (Get-Location).Path }

# Detectar letra del worktree desde el path
$letter = '?'
if ($cwd -match 'DungeonParty-([ABCD])') {
    $letter = $Matches[1]
}

# Colores ANSI por worktree
$colorMap = @{
    'A' = "`e[91m"  # rojo brillante
    'B' = "`e[92m"  # verde brillante
    'C' = "`e[94m"  # azul brillante
    'D' = "`e[93m"  # amarillo brillante
    '?' = "`e[90m"  # gris
}
$reset = "`e[0m"
$dim = "`e[90m"
$color = $colorMap[$letter]

# Branch actual
Push-Location $cwd
$branch = (git rev-parse --abbrev-ref HEAD 2>$null)
if (-not $branch) { $branch = '(no repo)' }
$branch = $branch.Trim()
Pop-Location

# Estado basado en branch
$statusIcon = ''
$statusLabel = ''
if ($branch -eq 'master') {
    $statusIcon = '[M]'
    $statusLabel = 'coordinador'
} elseif ($branch -like 'idle/*') {
    $statusIcon = '[o]'
    $statusLabel = 'libre'
} elseif ($branch -match '^dept/([^/]+)/(.+)$') {
    $dept = $Matches[1]
    $feature = $Matches[2]
    $statusIcon = "[$dept]"
    $statusLabel = $feature
} else {
    $statusIcon = '[?]'
    $statusLabel = $branch
}

# Output
Write-Host -NoNewline "$color[$letter]$reset $dim$statusIcon$reset $statusLabel $dim|$reset $branch"
