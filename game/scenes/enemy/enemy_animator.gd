class_name EnemyAnimator
## Thin wrapper around an AnimationPlayer found inside a gltf model root.
##
## Default-safe: if no AnimationPlayer is found, every method is a no-op.
## This means enemies that use EnemyModelBuilder (procedural meshes) are
## completely unaffected — they never have an AnimationPlayer in their tree.
##
## Usage:
##   var anim := EnemyAnimator.new(model_root_node)
##   anim.play_idle()
##   anim.play_walk()
##   anim.play_run()
##   anim.play_attack()
##   anim.play_death()
##   anim.play_state(horizontal_speed)  # auto-selects idle/walk/run

# Clip name constants — Quaternius "big" pack (humanoids: orc, ninja, etc.)
const CLIP_IDLE   := "Idle"
const CLIP_WALK   := "Walk"
const CLIP_RUN    := "Run"
const CLIP_JUMP   := "Jump"   # used as attack telegraph
const CLIP_PUNCH  := "Punch"  # preferred attack clip when available
const CLIP_DEATH  := "Death"

# Clip name constants — Quaternius slime pack
const CLIP_BITE   := "Bite_Front"   # attack for blob/slime types

# Clip name constants — Quaternius flying pack
const CLIP_FLY_IDLE   := "Flying_Idle"
const CLIP_FLY_MOVE   := "Fast_Flying"
const CLIP_HEADBUTT   := "Headbutt"   # attack for flyers

# Clip names — bespoke mobs from our own Blender motor.
# _mob_style_contract.md §3 fixes these names for every mob we build, so one
# mapping covers the whole bespoke roster. The generators author them with a
# "-loop" suffix to opt into Godot's glTF auto-loop; the importer consumes the
# suffix and registers the clip under the bare lowercase name (verified on
# slime_dp_01: "idle-loop" imports as "idle" with loop_mode=1).
const CLIP_DP_IDLE   := "idle"
# _mob_style_contract.md 3 fixes the clip name as "move-loop" for EVERY mob,
# with hop/slither/scurry/plod being descriptions of the locomotion, not names.
# The slime shipped its clip as "hop-loop" and this constant was written to
# match it -- the code followed the first case instead of the canon. Accept
# both: "move" is the contract, "hop" is the slime already in the game.
const CLIP_DP_MOVE   := "move"
const CLIP_DP_MOVE_ALT := "hop"
const CLIP_DP_ATTACK := "attack"
const CLIP_DP_HIT    := "hit"
const CLIP_DP_DEATH  := "death"

# Speed threshold below which Walk is preferred over Run.
# Enemies that are HUNTER_FAST (speed_mult ~1.4) will still use Walk
# unless their resultant speed exceeds this; Run is reserved for dashes.
const WALK_RUN_THRESHOLD := 5.5

var _player: AnimationPlayer = null
var _is_big_type    := false   # true = humanoid (orc/ninja clips)
var _is_flying_type := false   # true = flying (pigeon/goleling clips)
var _is_blob_type   := false   # true = slime/blob pack clips
var _is_dp_type     := false   # true = bespoke mob from our Blender motor
# Which name THIS mob used for its locomotion clip (contract: "move";
# the slime predates the contract and shipped "hop").
var _dp_move_clip   := CLIP_DP_MOVE

# Current logical state — avoids redundant play() calls.
var _current_state := ""
# True while a one-shot clip (attack, death, jump) is playing.
# play_state() is suppressed during one-shots to avoid cutting them short.
var _oneshot_active := false


## Searches model_root and its entire subtree for the first AnimationPlayer.
## Detects clip set from the available animations (humanoid vs. blob vs. flying).
func _init(model_root: Node) -> void:
	if model_root == null:
		return
	_player = _find_animation_player(model_root)
	if _player == null:
		return

	# Detect clip set
	var clips := _player.get_animation_list()
	_is_dp_type     = CLIP_DP_IDLE in clips and (CLIP_DP_MOVE in clips or CLIP_DP_MOVE_ALT in clips)
	if _is_dp_type:
		_dp_move_clip = CLIP_DP_MOVE if CLIP_DP_MOVE in clips else CLIP_DP_MOVE_ALT
	_is_big_type    = "Walk" in clips and "Run" in clips and "Idle" in clips
	_is_blob_type   = "Bite_Front" in clips
	_is_flying_type = "Flying_Idle" in clips or "Fast_Flying" in clips

	print("[EnemyAnimator] Found AnimationPlayer '%s'. Clips: %s | dp=%s big=%s blob=%s fly=%s" % [
		_player.name, ", ".join(clips), _is_dp_type, _is_big_type, _is_blob_type, _is_flying_type])

	# Start Idle immediately
	_play_clip(_idle_clip(), true)


## Finds the AnimationPlayer anywhere in the subtree (depth-first).
static func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


## Returns true if a live AnimationPlayer was found.
func is_valid() -> bool:
	return _player != null and is_instance_valid(_player)


## Auto-selects Idle / Walk / Run based on horizontal speed magnitude.
## Call every physics frame for smooth state transitions.
## Suppressed while a one-shot (attack / jump / death) is playing.
func play_state(horizontal_speed: float) -> void:
	if not is_valid():
		return
	# Check if a one-shot just finished — clear the flag so locomotion resumes.
	if _oneshot_active:
		if not _player.is_playing():
			_oneshot_active = false
		else:
			return  # one-shot still playing, don't interrupt
	var target_clip: String
	if horizontal_speed > WALK_RUN_THRESHOLD:
		target_clip = _run_clip()
	elif horizontal_speed > 0.5:
		target_clip = _walk_clip()
	else:
		target_clip = _idle_clip()
	_play_clip(target_clip, true)


## Play idle (looping). Safe to call every frame — skipped if already playing.
func play_idle() -> void:
	if not is_valid():
		return
	_play_clip(_idle_clip(), true)


## Play walk (looping). Safe to call every frame.
func play_walk() -> void:
	if not is_valid():
		return
	_play_clip(_walk_clip(), true)


## Play run (looping). Falls back to Walk if no Run clip.
func play_run() -> void:
	if not is_valid():
		return
	_play_clip(_run_clip(), true)


## Play attack clip (one-shot). Does NOT block; attack logic continues.
## After the clip finishes naturally the AnimationPlayer stops;
## play_state() will resume Idle/Walk next physics frame.
func play_attack() -> void:
	if not is_valid():
		return
	var clip := _attack_clip()
	_play_clip(clip, false)  # one-shot


## Play a jump/hop clip (one-shot). Used by slime locomotion hops.
## Falls back to attack clip if no Jump clip exists.
func play_jump() -> void:
	if not is_valid():
		return
	# For a bespoke mob the locomotion clip IS the hop — using the attack clip
	# here would fire a lunge every time the slime simply moves.
	if _is_dp_type:
		_play_clip(_dp_move_clip, false)
		return
	if _has_clip(CLIP_JUMP):
		_play_clip(CLIP_JUMP, false)
	else:
		play_attack()


## Play death clip (one-shot). Should be called from die() / _on_death hook.
## The clip plays through; the base_enemy tween + queue_free happen on a timer
## that is >= the death clip duration so the anim is visible.
func play_death() -> void:
	if not is_valid():
		return
	_play_clip(CLIP_DP_DEATH if _is_dp_type else CLIP_DEATH, false)


# ── Internals ────────────────────────────────────────────────────────────────

func _idle_clip() -> String:
	if _is_dp_type:
		return CLIP_DP_IDLE
	if _is_flying_type:
		return CLIP_FLY_IDLE
	return CLIP_IDLE


func _walk_clip() -> String:
	if _is_dp_type:
		return _dp_move_clip
	if _is_flying_type:
		return CLIP_FLY_MOVE
	if _is_blob_type:
		# Blob/slime pack has Walk (they hop, but the anim name is Walk)
		return CLIP_WALK if _has_clip(CLIP_WALK) else CLIP_IDLE
	return CLIP_WALK


func _run_clip() -> String:
	# Bespoke mobs ship ONE locomotion clip; speed is speed_scale in Godot, not
	# a duplicate clip (contract §3).
	if _is_dp_type:
		return _dp_move_clip
	if _is_flying_type:
		return CLIP_FLY_MOVE
	if _is_big_type and _has_clip(CLIP_RUN):
		return CLIP_RUN
	# Fall back to Walk if no Run (blob/slime pack)
	return _walk_clip()


func _attack_clip() -> String:
	if _is_dp_type:
		return CLIP_DP_ATTACK
	if _is_flying_type:
		return CLIP_HEADBUTT
	if _is_blob_type:
		return CLIP_BITE
	# Humanoid: prefer Punch, fall back to Jump as lunge telegraph
	if _has_clip(CLIP_PUNCH):
		return CLIP_PUNCH
	return CLIP_JUMP


func _has_clip(name: String) -> bool:
	if not is_valid():
		return false
	return _player.has_animation(name)


## Internal play — avoids redundant play() calls for the same looping state.
func _play_clip(clip_name: String, looping: bool) -> void:
	if not is_valid():
		return
	if not _has_clip(clip_name):
		return

	# For looping clips, skip if already in this state (avoids restart every frame)
	if looping and _current_state == clip_name and _player.is_playing():
		return

	_current_state = clip_name
	_oneshot_active = not looping

	# Set loop mode on the animation resource.
	# Quaternius clips import as non-looping by default; we override at runtime.
	var anim: Animation = _player.get_animation(clip_name)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE

	_player.play(clip_name)
