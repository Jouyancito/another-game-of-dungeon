# Pre-push hook — Semáforo de conflictos entre worktrees
# Clasifica el push como VERDE / AMARILLO / ROJO según overlap con otras branches activas.

$ErrorActionPreference = 'Stop'

function Write-Color($Text, $Color) {
    Write-Host $Text -ForegroundColor $Color
}

# 1. Branch actual
$branch = (git rev-parse --abbrev-ref HEAD).Trim()

# 2. Skip casos sin conflicto posible
if ($branch -eq 'master' -or $branch -eq 'HEAD') {
    Write-Color "[VERDE] Push en master - sin checks." Green
    exit 0
}
if ($branch -like 'idle/*') {
    Write-Color "[VERDE] Branch idle - sin tarea asignada, push libre." Green
    exit 0
}

# 3. Archivos tocados por esta branch vs master
$myFiles = git diff --name-only master...HEAD 2>$null
if (-not $myFiles) {
    Write-Color "[VERDE] Sin cambios vs master." Green
    exit 0
}
$myFilesSet = @{}
$myFiles | ForEach-Object { $myFilesSet[$_] = $true }

Write-Color "`n=== Semaforo de conflictos ===" Cyan
Write-Host "Branch actual: $branch"
Write-Host "Archivos tocados: $($myFiles.Count)"

# 4. Otras branches activas (de otros worktrees, no idle, no master, no la propia)
$worktrees = git worktree list --porcelain | Select-String '^branch refs/heads/(.+)$' | ForEach-Object { $_.Matches[0].Groups[1].Value }
$otherBranches = $worktrees | Where-Object { $_ -ne $branch -and $_ -ne 'master' -and $_ -notlike 'idle/*' }

if (-not $otherBranches) {
    Write-Color "`n[VERDE] Ninguna otra branch activa. Push libre." Green
    exit 0
}

# 5. Comparar contra cada una
$worstLevel = 'green'
$conflicts = @()

foreach ($other in $otherBranches) {
    $otherFiles = git diff --name-only master...$other 2>$null
    if (-not $otherFiles) { continue }

    $overlap = $otherFiles | Where-Object { $myFilesSet[$_] }
    if (-not $overlap) {
        Write-Color "  [VERDE] $other - sin overlap" Green
        continue
    }

    # Overlap existe: chequear si merge-tree detecta conflicto real
    $mergeBase = (git merge-base HEAD $other).Trim()
    $mergeOut = git merge-tree $mergeBase HEAD $other 2>&1 | Out-String
    $hasConflict = $mergeOut -match '<<<<<<<|>>>>>>>'

    if ($hasConflict) {
        Write-Color "  [ROJO] $other - CONFLICTO real en: $($overlap -join ', ')" Red
        $worstLevel = 'red'
        $conflicts += [pscustomobject]@{ Branch = $other; Level = 'red'; Files = $overlap }
    } else {
        Write-Color "  [AMARILLO] $other - overlap sin conflicto: $($overlap -join ', ')" Yellow
        if ($worstLevel -ne 'red') { $worstLevel = 'yellow' }
        $conflicts += [pscustomobject]@{ Branch = $other; Level = 'yellow'; Files = $overlap }
    }
}

Write-Host ""

switch ($worstLevel) {
    'green' {
        Write-Color "[VERDE] Push libre." Green
        exit 0
    }
    'yellow' {
        Write-Color "[AMARILLO] Overlap detectado pero merge limpio." Yellow
        Write-Color "Coordinar con ventanas afectadas antes de mergear a master." Yellow
        $resp = Read-Host "Continuar con push? (y/N)"
        if ($resp -eq 'y' -or $resp -eq 'Y') { exit 0 } else { exit 1 }
    }
    'red' {
        Write-Color "[ROJO] CONFLICTO REAL - push bloqueado." Red
        Write-Color "Resolver con las ventanas:" Red
        foreach ($c in $conflicts | Where-Object Level -eq 'red') {
            Write-Host "  - $($c.Branch): $($c.Files -join ', ')"
        }
        Write-Color "`nOpciones:" Red
        Write-Host "  1. Mergear manualmente antes de push: git fetch; git merge <branch-en-conflicto>"
        Write-Host "  2. Pedir a otra ventana que termine primero"
        Write-Host "  3. Re-estructurar cambios para no tocar mismos bloques"
        exit 1
    }
}
