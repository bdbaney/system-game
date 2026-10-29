class_name ContentDB
extends RefCounted
## Loads every content resource (classes, skills, titles) from res://content.
## Content is data. Adding a skill or title means adding a .tres file, not code.

var classes: Dictionary[String, ClassData] = {}
var skills: Dictionary[String, SkillData] = {}
var titles: Dictionary[String, TitleData] = {}
var _sorted_title_ids: Array[String] = []


static func load_from(root: String = "res://content") -> ContentDB:
	var db := ContentDB.new()
	for res: Resource in _load_dir(root.path_join("classes")):
		var c := res as ClassData
		if c:
			db.classes[c.id] = c
	for res: Resource in _load_dir(root.path_join("skills")):
		var s := res as SkillData
		if s:
			db.skills[s.id] = s
	for res: Resource in _load_dir(root.path_join("titles")):
		var t := res as TitleData
		if t:
			db.titles[t.id] = t
	for tid: String in db.titles:
		db._sorted_title_ids.append(tid)
	db._sorted_title_ids.sort()
	return db


## Title ids in a fixed order, so title checks are deterministic.
func sorted_title_ids() -> Array[String]:
	return _sorted_title_ids


func playable_classes() -> Array[ClassData]:
	var out: Array[ClassData] = []
	for c: ClassData in classes.values():
		if c.playable:
			out.append(c)
	return out


func skill_display(skill_id: String, rarity_bonus: int = 0) -> String:
	var s: SkillData = skills.get(skill_id)
	if s == null:
		return "[%s]" % skill_id
	return "[%s (%s)]" % [s.display_name, Rarity.name_of(Rarity.bump(s.rarity, rarity_bonus))]


## Returns a list of problems. Empty means the content is consistent.
func validate() -> Array[String]:
	var problems: Array[String] = []
	for c: ClassData in classes.values():
		for sid: String in c.starting_skills:
			if not skills.has(sid):
				problems.append("Class '%s' starts with unknown skill '%s'" % [c.id, sid])
	for s: SkillData in skills.values():
		if s.evolution_level > 0 and s.evolutions.is_empty():
			problems.append("Skill '%s' has an evolution level but no evolutions" % s.id)
		var evo_ids: Dictionary[String, bool] = {}
		for evo: EvolutionData in s.evolutions:
			if evo_ids.has(evo.id):
				problems.append("Skill '%s' has duplicate evolution id '%s'" % [s.id, evo.id])
			evo_ids[evo.id] = true
			if not skills.has(evo.result_skill_id):
				problems.append("Evolution '%s' points at unknown skill '%s'" % [evo.id, evo.result_skill_id])
			for r: Requirement in evo.requirements:
				if r.metric.is_empty():
					problems.append("Evolution '%s' has a requirement with no metric" % evo.id)
	for t: TitleData in titles.values():
		if t.requirements.is_empty():
			problems.append("Title '%s' has no requirements" % t.id)
		for stat: String in t.stat_bonus:
			if not EntityState.STATS.has(stat):
				problems.append("Title '%s' grants unknown stat '%s'" % [t.id, stat])
	return problems


static func _load_dir(path: String) -> Array[Resource]:
	var out: Array[Resource] = []
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("ContentDB: cannot open '%s'" % path)
		return out
	var files := Array(dir.get_files())
	files.sort()
	for file: String in files:
		# Exported builds rename resources to *.tres.remap.
		var name := file.trim_suffix(".remap")
		if name.ends_with(".tres"):
			var res := load(path.path_join(name))
			if res:
				out.append(res)
	return out
