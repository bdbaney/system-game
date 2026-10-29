class_name Fixtures
extends RefCounted
## Shared helpers for building test worlds and driving them with real commands.
## Tests never poke state directly. They submit commands, like a player would.

static var _content: ContentDB


static func content() -> ContentDB:
	if _content == null:
		_content = ContentDB.load_from()
	return _content


static func new_system(world_seed: int = 1, meta: MetaState = null) -> SystemCore:
	return SystemCore.new(content(), PermadeathRunMode.new(), world_seed, meta)


static func warrior(system: SystemCore, position: Vector2i = Vector2i.ZERO) -> EntityState:
	return system.spawn("Warrior", "warrior", 1, position, ["human"] as Array[String], true)


static func rabbit(system: SystemCore, position: Vector2i, level: int = 1) -> EntityState:
	return system.spawn("Rabbit", "critter", level, position, ["rabbit", "critter"] as Array[String])


static func wolf(system: SystemCore, position: Vector2i, level: int = 1) -> EntityState:
	return system.spawn("Grey Wolf", "beast", level, position, ["wolf", "beast"] as Array[String])


static func boss(system: SystemCore, position: Vector2i, level: int) -> EntityState:
	return system.spawn("Alpha Wolf", "beast", level, position, ["wolf", "beast", "boss"] as Array[String])


## The attacker's first active melee skill, or "" if it has none.
static func active_skill(system: SystemCore, entity: EntityState) -> String:
	for sid: String in entity.skills:
		var data: SkillData = system.content.skills.get(sid)
		if data and data.kind == SkillData.Kind.ACTIVE and data.tags.has("melee"):
			return sid
	return ""


## Attacks until the target dies (or `max_swings` is hit). Returns every event produced.
static func kill(system: SystemCore, attacker: EntityState, target: EntityState, use_skill: bool = false, max_swings: int = 100) -> Array[GameEvent]:
	var all: Array[GameEvent] = []
	for i: int in range(max_swings):
		if not target.alive:
			break
		var sid := active_skill(system, attacker) if use_skill else ""
		var result := system.submit(AttackCommand.create(attacker.id, target.id, sid))
		if not result.ok():
			break
		all.append_array(result.events)
	return all


## Spawns `count` rabbits next to `hunter` one at a time and kills each.
static func hunt_rabbits(system: SystemCore, hunter: EntityState, count: int, use_skill: bool = false) -> void:
	for i: int in range(count):
		var prey := rabbit(system, hunter.position + Vector2i(1, 0))
		kill(system, hunter, prey, use_skill)


static func offer_for(entity: EntityState, skill_id: String) -> Dictionary:
	for offer: Dictionary in entity.pending_evolutions:
		if str(offer["skill_id"]) == skill_id:
			return offer
	return {}


static func count_events(events: Array[GameEvent], type: String) -> int:
	var n := 0
	for e: GameEvent in events:
		if e.type == type:
			n += 1
	return n
