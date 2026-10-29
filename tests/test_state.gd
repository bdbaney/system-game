extends TestCase
## The authoritative state must be saveable and replayable. Those two properties are
## what make saves, replays and host-owned co-op possible.


func _normalized(d: Dictionary) -> String:
	# JSON turns ints into floats. Pass both sides through it before comparing.
	return JSON.stringify(JSON.parse_string(JSON.stringify(d)), "", true)


func test_world_round_trips_through_json() -> void:
	var system := Fixtures.new_system(42)
	var w := Fixtures.warrior(system)
	Fixtures.hunt_rabbits(system, w, 25, true)
	var before := system.world.to_dict()
	var restored := WorldState.from_dict(JSON.parse_string(JSON.stringify(before)) as Dictionary)
	expect_eq(_normalized(restored.to_dict()), _normalized(before), "World survives save/load")


func test_restored_world_continues_identically() -> void:
	var system := Fixtures.new_system(42)
	var w := Fixtures.warrior(system)
	Fixtures.hunt_rabbits(system, w, 5)

	var copy := Fixtures.new_system(0)
	copy.world = WorldState.from_dict(JSON.parse_string(JSON.stringify(system.world.to_dict())) as Dictionary)
	var w_copy := copy.world.get_entity(w.id)

	Fixtures.hunt_rabbits(system, w, 10)
	Fixtures.hunt_rabbits(copy, w_copy, 10)
	expect_eq(_normalized(copy.world.to_dict()), _normalized(system.world.to_dict()),
		"Loaded world plays out exactly like the original (RNG state saved)")


func test_same_seed_same_commands_same_world() -> void:
	var a := Fixtures.new_system(99)
	var b := Fixtures.new_system(99)
	Fixtures.hunt_rabbits(a, Fixtures.warrior(a), 20, true)
	Fixtures.hunt_rabbits(b, Fixtures.warrior(b), 20, true)
	expect_eq(_normalized(a.world.to_dict()), _normalized(b.world.to_dict()), "Deterministic")


func test_meta_state_round_trips() -> void:
	var meta := MetaState.new()
	meta.record_discovery("title", "first_blood")
	meta.record_discovery("skill", "heavy_strike")
	meta.record_run_end(EntityState.new())
	var restored := MetaState.from_dict(JSON.parse_string(JSON.stringify(meta.to_dict())) as Dictionary)
	expect_eq(_normalized(restored.to_dict()), _normalized(meta.to_dict()), "Meta survives save/load")
