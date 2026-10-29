class_name SkillState
extends RefCounted
## One entity's instance of a skill. The definition lives in a SkillData resource;
## this holds only what changes during play.

var skill_id: String = ""
var level: int = 1
var xp: int = 0
var uses: int = 0
## Extra rarity tiers granted to this instance (e.g. +1 for a world-first evolution).
var rarity_bonus: int = 0
## True once an evolution has been offered for this skill.
var evolution_offered: bool = false


static func create(p_skill_id: String) -> SkillState:
	var s := SkillState.new()
	s.skill_id = p_skill_id
	return s


func to_dict() -> Dictionary:
	return {
		"skill_id": skill_id,
		"level": level,
		"xp": xp,
		"uses": uses,
		"rarity_bonus": rarity_bonus,
		"evolution_offered": evolution_offered,
	}


static func from_dict(d: Dictionary) -> SkillState:
	var s := SkillState.create(str(d["skill_id"]))
	s.level = int(d["level"])
	s.xp = int(d["xp"])
	s.uses = int(d["uses"])
	s.rarity_bonus = int(d["rarity_bonus"])
	s.evolution_offered = bool(d["evolution_offered"])
	return s
