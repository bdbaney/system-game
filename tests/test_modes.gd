extends TestCase
## Game modes decide what death means. The core doesn't know which mode is running.


func _die(system: SystemCore, hero: EntityState) -> void:
	var killer := Fixtures.boss(system, hero.position + Vector2i(0, 1), 10)
	for i: int in range(100):
		if not hero.alive:
			break
		system.submit(AttackCommand.create(killer.id, hero.id))


func test_permadeath_ends_the_run_when_the_player_dies() -> void:
	var system := Fixtures.new_system()
	var w := Fixtures.warrior(system)
	_die(system, w)
	expect(not w.alive, "Warrior died")
	expect(system.world.run_over, "Run is over")
	expect(not system.submit(WaitCommand.create(w.id)).ok(), "Dead player cannot act")


func test_nothing_acts_after_the_run_ends() -> void:
	var system := Fixtures.new_system()
	var w := Fixtures.warrior(system)
	var wolf := Fixtures.wolf(system, Vector2i(5, 5))
	_die(system, w)
	expect(not system.submit(WaitCommand.create(wolf.id)).ok(), "World is frozen once the run ends")


func test_meta_state_survives_into_the_next_run() -> void:
	var meta := MetaState.new()
	var run1 := Fixtures.new_system(1, meta)
	var w1 := Fixtures.warrior(run1)
	Fixtures.hunt_rabbits(run1, w1, 1)
	_die(run1, w1)
	expect_eq(meta.runs_completed, 1, "Run counted")
	expect(meta.discovered_titles.has("first_blood"), "Codex remembers First Blood")

	var run2 := Fixtures.new_system(2, meta)
	var w2 := Fixtures.warrior(run2)
	expect(w2.titles.is_empty(), "New character starts with nothing")
	expect(run2.world.firsts.is_empty(), "New world has no firsts claimed")
	expect(meta.discovered_titles.has("first_blood"), "Codex still remembers")


func test_monster_death_does_not_end_the_run() -> void:
	var system := Fixtures.new_system()
	var w := Fixtures.warrior(system)
	Fixtures.hunt_rabbits(system, w, 3)
	expect(not system.world.run_over, "Killing monsters doesn't end the run")
