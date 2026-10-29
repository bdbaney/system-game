class_name MetaState
extends RefCounted
## State that lives outside any single world: the codex of everything the player has
## ever discovered, plus run history. Saved separately from WorldState.
## In Permadeath Run mode this is the only thing that survives death.

var runs_completed: int = 0
var best_level: int = 0
var discovered_titles: Array[String] = []
var discovered_skills: Array[String] = []


func record_discovery(kind: String, id: String) -> void:
	var target := discovered_titles if kind == "title" else discovered_skills
	if not target.has(id):
		target.append(id)


func record_run_end(entity: EntityState) -> void:
	runs_completed += 1
	best_level = maxi(best_level, entity.level)


func to_dict() -> Dictionary:
	return {
		"runs_completed": runs_completed,
		"best_level": best_level,
		"discovered_titles": Array(discovered_titles),
		"discovered_skills": Array(discovered_skills),
	}


static func from_dict(d: Dictionary) -> MetaState:
	var m := MetaState.new()
	m.runs_completed = int(d["runs_completed"])
	m.best_level = int(d["best_level"])
	for t: Variant in d["discovered_titles"]:
		m.discovered_titles.append(str(t))
	for s: Variant in d["discovered_skills"]:
		m.discovered_skills.append(str(s))
	return m
