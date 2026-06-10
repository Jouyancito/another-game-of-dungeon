# compile_sweep.gd - loads and compiles EVERY .gd under res:// in one engine boot.
#
# Why: "--editor --quit" only compiles scripts the editor happens to load, so a
# broken script that no open scene references slips through (the mimic.gd case).
# This sweep force-loads each script so parse/compile errors always surface.
#
# Usage:
#   Godot_console.exe --headless --path <project> --script res://tools/godot/compile_sweep.gd
#
# Exit codes: 0 = all scripts compile / 1 = failures (printed as "SWEEP FAIL: <path>").
extends SceneTree

const SKIP_DIRS: Array[String] = [".godot", ".git", ".import"]
# Vendor/raw asset staging - third-party scripts there may reference base
# classes their free tiers do not ship. Not game code, not swept.
const SKIP_PATH_PREFIXES: Array[String] = ["res://assets/art/_raw"]


func _initialize() -> void:
	var scripts: Array[String] = []
	_collect_scripts("res://", scripts)

	var failures: Array[String] = []
	for path in scripts:
		var res := ResourceLoader.load(path, "GDScript", ResourceLoader.CACHE_MODE_REPLACE)
		var script := res as GDScript
		if script == null or not script.can_instantiate():
			failures.append(path)

	print("[sweep] scripts checked: %d" % scripts.size())
	if failures.is_empty():
		print("SWEEP PASSED")
		quit(0)
	else:
		for f in failures:
			print("SWEEP FAIL: %s" % f)
		print("SWEEP FAILED (%d script(s))" % failures.size())
		quit(1)


func _is_skipped_path(path: String) -> bool:
	for prefix in SKIP_PATH_PREFIXES:
		if path.begins_with(prefix):
			return true
	return false


func _collect_scripts(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			if not SKIP_DIRS.has(entry) and not _is_skipped_path(full):
				_collect_scripts(full, out)
		elif entry.ends_with(".gd"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
