class_name SystemCore
extends RefCounted
## The System. The one entry point for changing the world.
##
##   var system := SystemCore.new(ContentDB.load_from(), PermadeathRunMode.new(), 1337)
##   var hero := system.spawn("Hero", "warrior", 1, Vector2i(0, 0), ["human"], true)
##   var result := system.submit(AttackCommand.create(hero.id, wolf.id))
##   for line in system.notifications_for(hero.id, result.events): print(line)
##
## In single player, the game calls submit() directly. In co-op, the host owns the
## SystemCore and clients send command dictionaries (CommandRegistry.from_dict).

var world: WorldState
var content: ContentDB
var mode: GameMode
var meta: MetaState
var arbiter: Arbiter
var notifier: SystemNotifier = SystemNotifier.new()


func _init(p_content: ContentDB, p_mode: GameMode, p_seed: int = 0, p_meta: MetaState = null) -> void:
	content = p_content
	mode = p_mode
	meta = p_meta if p_meta else MetaState.new()
	world = WorldState.new(p_seed)
	arbiter = Arbiter.new(mode, meta)


## Validates and executes one command, then lets the Arbiter judge the result.
func submit(command: GameCommand) -> CommandResult:
	var result := CommandResult.new()
	result.error = command.validate(world, content, mode)
	if result.error != "":
		return result
	var start := world.events.size()
	command.execute(world, content)
	world.tick += 1
	arbiter.process_from(world, content, start)
	result.events = world.events.slice_from(start)
	return result


## World-authority action: brings an entity into existence at `level`, with its class's
## stats and starting skills. Used for players, monsters and NPCs alike.
func spawn(display_name: String, class_id: String, level: int, position: Vector2i, tags: Array[String] = [], is_player: bool = false) -> EntityState:
	var cls: ClassData = content.classes.get(class_id)
	assert(cls != null, "Unknown class '%s'" % class_id)
	var e := EntityState.new()
	e.display_name = display_name
	e.class_id = class_id
	e.is_player = is_player
	e.position = position
	for t: String in tags:
		e.tags.append(t)
	for stat: String in cls.base_stats:
		e.stats[stat] = cls.base_stats[stat]
	for i: int in range(1, level):
		Progression.apply_level_stats(content, e)
	e.level = level
	for sid: String in cls.starting_skills:
		e.skills[sid] = SkillState.create(sid)
	world.add_entity(e)
	e.hp = e.max_hp()
	world.record_event(GameEvent.SPAWN, e.id, -1, {
		"class_id": class_id,
		"level": level,
		"position": [position.x, position.y],
	})
	return e


func notifications_for(observer_id: int, events: Array[GameEvent]) -> Array[String]:
	return notifier.format_all(observer_id, events, world, content)
