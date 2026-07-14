class_name FloorDescent
extends Node3D

# The way down, revealed when the floor's boss dies.
#
# Canon (lore/_alpha_5_maps.md, "P2 — Alcance del Demo"): the demo's real ending is
# the descent toward Floor 2 — the forest antechamber past it is explicitly the first
# thing to cut, with the doc naming this exact fallback: "solo el descenso como
# cliffhanger". So this closes the run without a Floor 2 existing.
#
# Interaction follows the same contract as loot_chest / mimic: be in the
# "interactables" group and expose open(player). BasePlayer._try_interact_nearby()
# does the rest (range + look-at check).

## Floor the player is descending FROM. The cliffhanger copy reads off this.
@export var from_floor: int = 1

var _used := false


func _ready() -> void:
	add_to_group("interactables")
	_build_visuals()


## Signals "there is a way down now" — a cold updraft from the dark below.
## Built procedurally to match the rest of the level (all CSG/primitives, no scene deps).
func _build_visuals() -> void:
	# The pit: a dark opening in the arena floor.
	var pit := CSGBox3D.new()
	pit.name = "Pit"
	pit.size = Vector3(4.0, 0.2, 4.0)
	pit.position = Vector3(0, 0.05, 0)
	var pit_mat := StandardMaterial3D.new()
	pit_mat.albedo_color = Color(0.02, 0.02, 0.04)
	pit_mat.roughness = 1.0
	pit.material = pit_mat
	add_child(pit)

	# Bioluminescent draft rising out of it — per canon the P2 glow "drains downward",
	# so at the lip it reads as light leaking UP from a world that already exists.
	var glow := OmniLight3D.new()
	glow.name = "DescentGlow"
	glow.light_color = Color(0.45, 0.85, 0.95)
	glow.light_energy = 1.6
	glow.omni_range = 14.0
	glow.position = Vector3(0, 1.2, 0)
	add_child(glow)

	var pulse := create_tween().set_loops()
	pulse.tween_property(glow, "light_energy", 2.4, 1.8).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(glow, "light_energy", 1.6, 1.8).set_trans(Tween.TRANS_SINE)


## BasePlayer interact hook. One-shot: the run ends here.
func open(_player: Node) -> void:
	if _used:
		return
	_used = true
	remove_from_group("interactables")

	if AudioManager:
		AudioManager.play_sfx(&"level_up")

	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_demo_ending"):
		hud.show_demo_ending(from_floor)
	else:
		# No HUD (dev scene): still honour the interaction rather than trapping the player.
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
