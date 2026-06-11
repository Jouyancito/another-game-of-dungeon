# Godot testing tools

Mirror of `game/tools/blender/` but for the engine side — so we can validate code
and SEE runtime visuals without opening the editor by hand each iteration.

## Tools

| Tool | What it does | Run |
|---|---|---|
| `validate.ps1` | Imports all resources + compiles every GDScript → reports parse/import/script errors. The "did my edit break anything?" check. | `powershell -ExecutionPolicy Bypass -File game\tools\godot\validate.ps1` |
| `preview_runner.tscn` + `.gd` | Instances a target scene/glb, frames a 3/4 (or front/side) camera, renders to PNG, quits. The Godot equivalent of the Blender preview. | `<Godot> --path game res://tools/godot/preview_runner.tscn -- <target> <out.png> [front\|34\|side]` |

### Examples

```powershell
# Validate the whole project (catches GDScript parse errors)
powershell -ExecutionPolicy Bypass -File game\tools\godot\validate.ps1

# Screenshot the dressed golem (moss + cyan eyes + floating rocks)
<Godot> --path game res://tools/godot/preview_runner.tscn -- res://scenes/enemy/golem.tscn C:/tmp/golem_front.png front

# Screenshot just the bare body glb
<Godot> --path game res://tools/godot/preview_runner.tscn -- res://assets/art/piso1_pradera/enemies/big/golem_dp_body_01.glb C:/tmp/body.png 34
```

> `preview_runner` runs **without** `--headless` on purpose: the headless display
> driver cannot capture viewport images. It opens a brief window, grabs the frame,
> and quits.

## ⚠️ Godot executable — nested-folder gotcha (corrected 2026-06-10)

The repo-root `Godot_v4.6.2-stable_win64.exe` is **not an exe — it is a FOLDER**
(the release zip was extracted into a directory named like the exe). That is why
`Get-Item` reports `Attributes: Directory` and bash says "Is a directory" when you
try to execute it. The real binaries live nested inside:

```
Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe          (editor, 172 MB)
Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe  (CLI, writes stdout)
```

`validate.ps1`'s default `-Godot` already points at the nested `_console.exe`.
(An earlier note here blamed a OneDrive online-only placeholder — wrong diagnosis;
the binaries are local and run fine from scripts.)

Use the **`_console.exe`** variant for CLI runs — it writes stdout/stderr so the
validation log is capturable.
