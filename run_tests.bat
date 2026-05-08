@echo off
REM Headless GUT runner — corre todos los tests unitarios sin abrir editor.
REM Uso: doble click o `run_tests.bat` desde la consola.

setlocal
set GODOT="%~dp0Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe"
set PROJECT_PATH="%~dp0game"

%GODOT% --headless --path %PROJECT_PATH% -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json
endlocal
