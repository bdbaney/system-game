class_name EntityState
extends RefCounted
## The authoritative data for one entity: player, monster or NPC.
## There is deliberately no "player-only" data here. Everything that exists is
## subject to the same System.

const STATS: Array[String] = [
	"strength", "agility", "endurance", "vitality", "toughness",
	"intelligence", "wisdom", "perception", "willpower",
]

var id: int = -1
var display_name: String = ""
var class_id: String = ""
var tags: Array[String] = []
var is_player: bool = false
var level: int = 1
var xp: int = 0
var stats: Dictionary[String, int] = {}
## Stats granted by titles. Kept separate so the source of every point is traceable.
var bonus_stats: Dictionary[String, int] = {}
var hp: int = 1
var position: Vector2i = Vector2i.ZERO
var alive: bool = true
var skills: Dictionary[String, SkillState] = {}
var titles: Array[String] = []
var profile: BehaviorProfile = BehaviorProfile.new()
## Damage received, keyed by attacker id. Used for "flawless" kills.
var damage_taken_from: Dictionary[int, int] = {}
## Offers waiting for a choice: {skill_id, options, first_options, hidden_count}.
var pending_evolutions: Array[Dictionary] = []


func get_stat(stat: String) -> int:
	return int(stats.get(stat, 0)) + int(bonus_stats.get(stat, 0))


func max_hp() -> int:
	return maxi(1, get_stat("vitality") * 10)


func hp_ratio() -> float:
	return float(hp) / float(max_hp())


## Grid distance (diagonals count as 1).
func distance_to(other: EntityState) -> int:
	var d := other.position - position
	return maxi(absi(d.x), absi(d.y))


func has_tag(tag: String) -> bool:
	return tags.has(tag)


func to_dict() -> Dictionary:
	var skill_list: Array = []
	for s: SkillState in skills.values():
		skill_list.append(s.to_dict())
	var dmg: Dictionary = {}
	for k: int in damage_taken_from:
		dmg[str(k)] = damage_taken_from[k]
	var stat_copy: Dictionary = {}
	for k: String in stats:
		stat_copy[k] = stats[k]
	var bonus_copy: Dictionary = {}
	for k: String in bonus_stats:
		bonus_copy[k] = bonus_stats[k]
	var pending: Array = []
	for offer: Dictionary in pending_evolutions:
		pending.append(offer.duplicate(true))
	return {
		"id": id,
		"display_name": display_name,
		"class_id": class_id,
		"tags": Array(tags),
		"is_player": is_player,
		"level": level,
		"xp": xp,
		"stats": stat_copy,
		"bonus_stats": bonus_copy,
		"hp": hp,
		"position": [position.x, position.y],
		"alive": alive,
		"skills": skill_list,
		"titles": Array(titles),
		"profile": profile.to_dict(),
		"damage_taken_from": dmg,
		"pending_evolutions": pending,
	}


static func from_dict(d: Dictionary) -> EntityState:
	var e := EntityState.new()
	e.id = int(d["id"])
	e.display_name = str(d["display_name"])
	e.class_id = str(d["class_id"])
	for t: Variant in d["tags"]:
		e.tags.append(str(t))
	e.is_player = bool(d["is_player"])
	e.level = int(d["level"])
	e.xp = int(d["xp"])
	var stat_d: Dictionary = d["stats"]
	for k: Variant in stat_d:
		e.stats[str(k)] = int(stat_d[k])
	var bonus_d: Dictionary = d["bonus_stats"]
	for k: Variant in bonus_d:
		e.bonus_stats[str(k)] = int(bonus_d[k])
	e.hp = int(d["hp"])
	var pos: Array = d["position"]
	e.position = Vector2i(int(pos[0]), int(pos[1]))
	e.alive = bool(d["alive"])
	for sd: Variant in d["skills"]:
		var s := SkillState.from_dict(sd as Dictionary)
		e.skills[s.skill_id] = s
	for t: Variant in d["titles"]:
		e.titles.append(str(t))
	e.profile = BehaviorProfile.from_dict(d["profile"] as Dictionary)
	var dmg_d: Dictionary = d["damage_taken_from"]
	for k: Variant in dmg_d:
		e.damage_taken_from[int(str(k))] = int(dmg_d[k])
	for offer: Variant in d["pending_evolutions"]:
		var o: Dictionary = offer
		e.pending_evolutions.append({
			"skill_id": str(o["skill_id"]),
			"options": _string_array(o["options"] as Array),
			"first_options": _string_array(o["first_options"] as Array),
			"hidden_count": int(o["hidden_count"]),
		})
	return e


static func _string_array(items: Array) -> Array:
	var out: Array = []
	for v: Variant in items:
		out.append(str(v))
	return out
