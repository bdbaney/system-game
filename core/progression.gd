class_name Progression
extends RefCounted
## Shared progression rules. Players, monsters and NPCs all level through these
## functions. There is no separate monster leveling.

const BASE_KILL_XP := 10
const XP_TO_NEXT_FACTOR := 20


static func xp_to_next(level: int) -> int:
	return XP_TO_NEXT_FACTOR * level


## XP for killing something. Killing above your level pays more, below pays less.
static func kill_xp(killer_level: int, victim_level: int) -> int:
	var gap := victim_level - killer_level
	var mult := clampf(1.0 + 0.25 * gap, 0.1, 3.0)
	return maxi(1, roundi(BASE_KILL_XP * victim_level * mult))


static func grant_xp(world: WorldState, content: ContentDB, entity: EntityState, amount: int) -> void:
	entity.xp += amount
	while entity.xp >= xp_to_next(entity.level):
		entity.xp -= xp_to_next(entity.level)
		entity.level += 1
		var gains := apply_level_stats(content, entity)
		world.record_event(GameEvent.LEVEL_UP, entity.id, -1, {
			"level": entity.level,
			"class_id": entity.class_id,
			"gains": gains,
		})


## Applies one level's worth of class stats. Current HP rises by the max HP gained.
static func apply_level_stats(content: ContentDB, entity: EntityState) -> Dictionary:
	var cls: ClassData = content.classes.get(entity.class_id)
	var gains: Dictionary = {}
	if cls == null:
		return gains
	var old_max := entity.max_hp()
	for stat: String in cls.stats_per_level:
		var amount: int = cls.stats_per_level[stat]
		entity.stats[stat] = int(entity.stats.get(stat, 0)) + amount
		gains[stat] = amount
	entity.hp += entity.max_hp() - old_max
	return gains


## Records one use of a skill and levels it up when it has enough uses.
static func use_skill(world: WorldState, content: ContentDB, entity: EntityState, skill_id: String) -> void:
	if not entity.skills.has(skill_id):
		return
	var state: SkillState = entity.skills[skill_id]
	var data: SkillData = content.skills.get(skill_id)
	if data == null:
		return
	state.uses += 1
	state.xp += 1
	if state.xp >= data.xp_per_level:
		state.xp -= data.xp_per_level
		state.level += 1
		world.record_event(GameEvent.SKILL_LEVEL_UP, entity.id, -1, {
			"skill_id": skill_id,
			"level": state.level,
		})
