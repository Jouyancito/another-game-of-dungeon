# validate.ps1 - Dungeon Party headless Godot validation.
#
# Imports all resources + compiles every GDScript in the project and reports any
# parse/import/script errors. This is the "did my blind edit break anything?" check
# (mirror of the Blender gen->preview loop, but for Godot code/scenes).
#
# Usage (from anywhere):
#   powershell -ExecutionPolicy Bypass -File game\tools\godot\validate.ps1
#   powershell -ExecutionPolicy Bypass -File game\tools\godot\validate.ps1 -Godot "C:\path\Godot_console.exe"
#
# Exit codes: 0 = clean / 1 = errors found (printed) / 2 = Godot exe not found.
#
# NOTE: the repo-root "Godot_v4.6.2-stable_win64.exe" is a FOLDER (zip extracted to a
# dir named like the exe). The real binaries live nested inside it.
#
# NOTE: keep this file ASCII-only. Windows PowerShell 5.1 reads it as ANSI and
# multi-byte UTF-8 chars (em dashes etc.) break string parsing.

param(
    [string]$Godot   = (Join-Path $PSScriptRoot "..\..\..\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe"),
    [string]$Project = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

if (-not (Test-Path $Godot)) {
    Write-Host "[validate] Godot executable not found: $Godot" -ForegroundColor Red
    Write-Host "[validate] Pass -Godot <path-to-Godot_console.exe>."
    exit 2
}

Write-Host "[validate] Godot   : $Godot"
Write-Host "[validate] Project : $Project"
Write-Host "[validate] Running headless import + script compile..."

# Phase 1: --editor --quit imports every resource and compiles the scripts the
# editor loads, then exits. Catches import errors and most script errors.
$log = & $Godot --headless --editor --quit --path $Project 2>&1 | Out-String
$lines = $log -split "`r?`n"

$pattern = 'SCRIPT ERROR|Parse Error|ERROR:|Failed to (load|parse)|Cannot open|Invalid|expected'
$errs = $lines | Where-Object { $_ -match $pattern }

if ($errs) {
    Write-Host "=== VALIDATION FAILED ($($errs.Count) line(s)) ===" -ForegroundColor Red
    $errs | ForEach-Object { Write-Host "  $_" }
    exit 1
}

# Phase 2: compile sweep. The editor pass above does NOT compile scripts no
# loaded scene references, so a broken orphan script slips through. The sweep
# force-loads every .gd in one engine boot and fails on any compile error.
Write-Host "[validate] Running full script compile sweep..."
$sweepLog = & $Godot --headless --path $Project --script res://tools/godot/compile_sweep.gd 2>&1 | Out-String
$sweepLines = $sweepLog -split "`r?`n"
$sweepFails = $sweepLines | Where-Object { $_ -match 'SWEEP FAIL|SCRIPT ERROR|Parse Error' }
$sweepPassed = $sweepLines | Where-Object { $_ -match 'SWEEP PASSED' }

if ($sweepFails -or -not $sweepPassed) {
    Write-Host "=== VALIDATION FAILED (compile sweep) ===" -ForegroundColor Red
    if ($sweepFails) { $sweepFails | ForEach-Object { Write-Host "  $_" } }
    else { Write-Host "  Sweep did not report PASSED. Raw tail:"; $sweepLines | Select-Object -Last 10 | ForEach-Object { Write-Host "  $_" } }
    exit 1
}

$checked = ($sweepLines | Where-Object { $_ -match '\[sweep\] scripts checked' }) -join ''
Write-Host "=== VALIDATION PASSED - no script/import errors ($checked) ===" -ForegroundColor Green
exit 0
