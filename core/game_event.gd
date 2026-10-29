class_name GameEvent
extends RefCounted
## A fact about something that happened. Events are the only input the Arbiter reads.
## Commands produce events; the Arbiter turns events into consequences (XP, skills,
## titles, evolutions), which are themselves recorded as events.

const SPAWN := "spawn"
const MOVE := "move"
const WAIT := "wait"
const REST := "rest"
const DAMAGE := "damage"
const KILL := "kill"
const DEATH := "death"
const LEVEL_UP := "level_up"
const SKILL_LEVEL_UP := "skill_level_up"
const SKILL_EVOLUTION_OFFERED := "skill_evolution_offered"
const SKILL_EVOLVED := "skill_evolved"
const TITLE_EARNED := "title_earned"
const WORLD_FIRST := "world_first"
const RUN_ENDED := "run_ended"

var tick: int = 0
var type: String = ""
var actor_id: int = -1
var target_id: int = -1
var data: Dictionary = {}


static func make(p_tick: int, p_type: String, p_actor: int, p_target: int, p_data: Dictionary) -> GameEvent:
	var e := GameEvent.new()
	e.tick = p_tick
	e.type = p_type
	e.actor_id = p_actor
	e.target_id = p_target
	e.data = p_data
	return e


func to_dict() -> Dictionary:
	return {
		"tick": tick,
		"type": type,
		"actor_id": actor_id,
		"target_id": target_id,
		"data": data.duplicate(true),
	}


static func from_dict(d: Dictionary) -> GameEvent:
	return GameEvent.make(
		int(d["tick"]), str(d["type"]), int(d["actor_id"]), int(d["target_id"]),
		(d["data"] as Dictionary).duplicate(true)
	)
