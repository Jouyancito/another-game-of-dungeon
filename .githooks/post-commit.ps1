# Post-commit hook — Escribe estado del dept a .dept-status/{code}.json
# Se consume al arrancar sesión Claude: lee el archivo y sincroniza a engram.

$ErrorActionPreference = 'SilentlyContinue'

$branch = (git rev-parse --abbrev-ref HEAD).Trim()

# Skip branches que no son depto
if ($branch -eq 'master' -or $branch -eq 'HEAD' -or $branch -like 'idle/*') {
    exit 0
}

# Parsear dept/{code}/{feature}
if ($branch -notmatch '^dept/([^/]+)/(.+)$') {
    Write-Host "[post-commit] Branch '$branch' no sigue convencion dept/{code}/{feature}. Skip." -ForegroundColor Yellow
    exit 0
}
$code = $Matches[1]
$feature = $Matches[2]

# Worktree actual
$worktreePath = (git rev-parse --show-toplevel).Trim()
$worktreeLetter = ($worktreePath -replace '.*DungeonParty-', '').Substring(0, 1).ToUpper()

# Ultimo commit
$hash = (git rev-parse --short HEAD).Trim()
$msg = (git log -1 --format="%s").Trim()
$date = (git log -1 --format="%cI").Trim()
$files = @(git show --name-only --format="" HEAD | Where-Object { $_ -ne '' })

# Repo root (main worktree)
$repoCommonDir = (git rev-parse --git-common-dir).Trim()
if (-not [System.IO.Path]::IsPathRooted($repoCommonDir)) {
    $repoCommonDir = Join-Path $worktreePath $repoCommonDir
}
$mainRepo = Split-Path -Parent $repoCommonDir
$statusDir = Join-Path $mainRepo '.dept-status'
if (-not (Test-Path $statusDir)) { New-Item -ItemType Directory -Path $statusDir | Out-Null }

$statusFile = Join-Path $statusDir "$code.json"

$payload = [ordered]@{
    code         = $code
    branch       = $branch
    feature      = $feature
    worktree     = $worktreeLetter
    worktree_path = $worktreePath
    status       = 'EN PROGRESO'
    last_commit  = [ordered]@{
        hash  = $hash
        msg   = $msg
        date  = $date
        files = $files
    }
    updated_at   = (Get-Date -Format 'o')
}

$payload | ConvertTo-Json -Depth 5 | Out-File -FilePath $statusFile -Encoding utf8

Write-Host "[post-commit] Dept-status actualizado: $code (worktree $worktreeLetter, branch $branch)" -ForegroundColor Cyan
