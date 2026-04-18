extends Node

# AutoLoad — registry global de skills cargadas desde .tres.
# Nombre de AutoLoad esperado: "SkillDB".
# Usage: SkillDB.get_skill("warrior_shield_bash")

const SKILLS_DIR := "res://shared/skills/resources/"

var _skills: Dictionary = {}  # StringName → SkillResource


func _ready() -> void:
	_load_all_skills(SKILLS_DIR)


func _load_all_skills(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("SkillDB: dir no accesible: %s" % path)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		# Skip carpetas especiales — _archive contiene .tres obsoletos no registrables.
		if dir.current_is_dir() and entry != "." and entry != ".." and not entry.begins_with("_"):
			_load_all_skills(path + entry + "/")
		elif entry.ends_with(".tres"):
			_register_skill(path + entry)
		entry = dir.get_next()
	dir.list_dir_end()


func _register_skill(file_path: String) -> void:
	var res = load(file_path)
	if res == null or not (res is SkillResource):
		push_warning("SkillDB: '%s' no es SkillResource válida" % file_path)
		return
	var skill: SkillResource = res
	if skill.id == "":
		push_warning("SkillDB: skill en '%s' sin id — skip" % file_path)
		return
	_skills[skill.id] = skill


func get_skill(id: StringName) -> SkillResource:
	if not _skills.has(id):
		push_warning("SkillDB: skill '%s' no registrada" % id)
		return null
	return _skills[id]


func has_skill(id: StringName) -> bool:
	return _skills.has(id)


func all_skills_for_class(class_id: StringName) -> Array[SkillResource]:
	var result: Array[SkillResource] = []
	for s in _skills.values():
		if s.class_id == class_id:
			result.append(s)
	return result


## Para tests — registrar skill manualmente sin cargar .tres
func register_skill_for_test(skill: SkillResource) -> void:
	if skill and skill.id != "":
		_skills[skill.id] = skill
