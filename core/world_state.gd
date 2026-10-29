class_name WorldState
extends RefCounted
## The single authoritative game state.
##
## Rules (also in CLAUDE.md):
## - Everything that matters lives here, or in an EntityState it owns.
## - Only GameCommands (through SystemCore.submit) and the Arbiter change it.
##   Spawning is a world-authority action done through SystemCore.spawn.
## - Presentation code (scenes, UI, sprites) reads it and never writes it.
## - All randomness goes through `rng`, so a seed plus a command list replays exactly.
##   This is also what lets a co-op host own the state and clients send commands.

var world_seed: int = 0
var tick: int = 0
var run_over: bool = false
var next_entity_id: int = 1
var entities: Dictionary[int, EntityState] = {}
## World-firsts ledger: "title:progenitor_slayer" -> id of the entity that claimed it.
var firsts: Dictionary[String, int] = {}
var events: EventLog = EventLog.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(p_seed: int = 0) -> void:
	world_seed = p_seed
	rng.seed = p_seed


func add_entity(entity: EntityState) -> EntityState:
	entity.id = next_entity_id
	next_entity_id += 1
	entities[entity.id] = entity
	return entity


func get_entity(id: int) -> EntityState:
	if entities.has(id):
		return entities[id]
	return null


## The living entity standing on `cell`, or null.
func entity_at(cell: Vector2i) -> EntityState:
	for e: EntityState in entities.values():
		if e.alive and e.position == cell:
			return e
	return null


func players() -> Array[EntityState]:
	var out: Array[EntityState] = []
	for e: EntityState in entities.values():
		if e.is_player:
			out.append(e)
	return out


func record_event(type: String, actor_id: int, target_id: int, data: Dictionary) -> GameEvent:
	var e := GameEvent.make(tick, type, actor_id, target_id, data)
	events.append(e)
	return e


## Claims a world first. Returns true only for the first entity in existence to claim `key`.
func claim_first(key: String, entity_id: int) -> bool:
	if firsts.has(key):
		return false
	firsts[key] = entity_id
	return true


func to_dict() -> Dictionary:
	var ents: Array = []
	var ids := entities.keys()
	ids.sort()
	for id: int in ids:
		ents.append(entities[id].to_dict())
	var firsts_copy: Dictionary = {}
	for k: String in firsts:
		firsts_copy[k] = firsts[k]
	return {
		"world_seed": world_seed,
		"tick": tick,
		"run_over": run_over,
		"next_entity_id": next_entity_id,
		# 64-bit RNG state is stored as a string so JSON doesn't round it.
		"rng_state": str(rng.state),
		"entities": ents,
		"firsts": firsts_copy,
		"events": events.to_array(),
	}


static func from_dict(d: Dictionary) -> WorldState:
	var w := WorldState.new(int(d["world_seed"]))
	w.tick = int(d["tick"])
	w.run_over = bool(d["run_over"])
	w.next_entity_id = int(d["next_entity_id"])
	w.rng.state = str(d["rng_state"]).to_int()
	for ed: Variant in d["entities"]:
		var e := EntityState.from_dict(ed as Dictionary)
		w.entities[e.id] = e
	var firsts_d: Dictionary = d["firsts"]
	for k: Variant in firsts_d:
		w.firsts[str(k)] = int(firsts_d[k])
	w.events = EventLog.from_array(d["events"] as Array)
	return w
