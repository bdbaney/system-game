extends TestCase
## Commands are the only way to change the world. Invalid ones must change nothing.


func test_attack_out_of_range_is_rejected() -> void:
	var system := Fixtures.new_system()
	var w := Fixtures.warrior(system)
	var r := Fixtures.rabbit(system, Vector2i(5, 0))
	var before := system.world.events.size()
	var result := system.submit(AttackCommand.create(w.id, r.id))
	expect(not result.ok(), "Out-of-range attack rejected")
	expect_eq(system.world.events.size(), before, "No events from a rejected command")
	expect_eq(system.world.tick, 0, "Tick does not advance on rejection")


func test_cannot_use_unknown_or_passive_skill() -> void:
	var system := Fixtures.new_system()
	var w := Fixtures.warrior(system)
	var r := Fixtures.rabbit(system, Vector2i(1, 0))
	expect(not system.submit(AttackCommand.create(w.id, r.id, "mana_bolt")).ok(), "Unknown skill rejected")
	expect(not system.submit(AttackCommand.create(w.id, r.id, "basic_weapon_mastery")).ok(), "Passive skill rejected")
	expect(system.submit(AttackCommand.create(w.id, r.id, "power_strike")).ok(), "Active melee skill accepted")


func test_move_into_occupied_cell_is_rejected() -> void:
	var system := Fixtures.new_system()
	var w := Fixtures.warrior(system)
	Fixtures.rabbit(system, Vector2i(1, 0))
	expect(not system.submit(MoveCommand.create(w.id, Vector2i(1, 0))).ok(), "Occupied cell rejected")
	expect(system.submit(MoveCommand.create(w.id, Vector2i(0, 1))).ok(), "Free cell accepted")
	expect_eq(w.position, Vector2i(0, 1), "Moved")


func test_rest_blocked_with_enemy_adjacent() -> void:
	var system := Fixtures.new_system()
	var w := Fixtures.warrior(system)
	Fixtures.wolf(system, Vector2i(1, 1))
	expect(not system.submit(RestCommand.create(w.id)).ok(), "Rest blocked next to an enemy")


func test_commands_round_trip_through_dictionaries() -> void:
	# This is the shape a co-op client will send to the host.
	var cmds: Array[GameCommand] = [
		AttackCommand.create(1, 2, "power_strike"),
		MoveCommand.create(1, Vector2i(-1, 1)),
		WaitCommand.create(3),
		RestCommand.create(1),
		ChooseEvolutionCommand.create(1, "power_strike", "evo_heavy_strike"),
	]
	for cmd: GameCommand in cmds:
		var wire := JSON.parse_string(JSON.stringify(cmd.to_dict())) as Dictionary
		var rebuilt := CommandRegistry.from_dict(wire)
		expect(rebuilt != null, "Rebuilt %s" % cmd.type_name())
		if rebuilt:
			expect_eq(JSON.stringify(rebuilt.to_dict()), JSON.stringify(cmd.to_dict()), "Round trip %s" % cmd.type_name())
