class_name DemoScenario
extends RefCounted
## A scripted Phase 0 run: a Warrior hunts rabbits and wolves, the wolves fight back,
## and the System reports everything. Used by the debug scene, and handy for checking
## how the System "feels" after content changes.


static func run(world_seed: int = 1337, waves: int = 40) -> Array[String]:
	var system := SystemCore.new(ContentDB.load_from(), PermadeathRunMode.new(), world_seed)
	var hero := system.spawn("Hero", "warrior", 1, Vector2i.ZERO, ["human"] as Array[String], true)
	var lines: Array[String] = ["=== %s | seed %d ===" % [system.mode.display_name, world_seed], ""]

	for wave: int in range(waves):
		if system.world.run_over:
			break
		var foe: EntityState
		if wave % 3 == 2:
			foe = system.spawn("Grey Wolf", "beast", 1 + floori(wave / 10.0), hero.position + Vector2i(1, 0),
				["wolf", "beast"] as Array[String])
		else:
			foe = system.spawn("Rabbit", "critter", 1, hero.position + Vector2i(1, 0),
				["rabbit", "critter"] as Array[String])

		var swing := 0
		while foe.alive and hero.alive:
			# Alternate Power Strike and basic attacks.
			var skill := _active_skill(system, hero) if swing % 2 == 0 else ""
			_say(lines, system, hero, system.submit(AttackCommand.create(hero.id, foe.id, skill)))
			swing += 1
			if foe.alive and not foe.has_tag("critter"):
				_say(lines, system, hero, system.submit(AttackCommand.create(foe.id, hero.id)))

		if hero.alive:
			_choose_evolutions(lines, system, hero)
			system.submit(RestCommand.create(hero.id))

	lines.append("")
	lines.append("Final: level %d, titles %s, skills %s" % [hero.level, hero.titles, hero.skills.keys()])
	return lines


static func _say(lines: Array[String], system: SystemCore, hero: EntityState, result: CommandResult) -> void:
	if result.ok():
		lines.append_array(system.notifications_for(hero.id, result.events))


## The demo always takes the first world-first option if there is one, else the rarest.
static func _choose_evolutions(lines: Array[String], system: SystemCore, hero: EntityState) -> void:
	while not hero.pending_evolutions.is_empty():
		var offer: Dictionary = hero.pending_evolutions[0]
		var options: Array = offer["options"]
		var firsts: Array = offer["first_options"]
		var pick: String = str(firsts[firsts.size() - 1]) if not firsts.is_empty() else str(options[options.size() - 1])
		_say(lines, system, hero, system.submit(ChooseEvolutionCommand.create(hero.id, str(offer["skill_id"]), pick)))


static func _active_skill(system: SystemCore, entity: EntityState) -> String:
	for sid: String in entity.skills:
		var data: SkillData = system.content.skills.get(sid)
		if data and data.kind == SkillData.Kind.ACTIVE and data.tags.has("melee"):
			return sid
	return ""
