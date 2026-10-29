extends TestCase
## The core promise: what you do decides what the System offers you.


func test_playstyle_changes_the_evolution_offer() -> void:
	# Warrior A ends fights with Power Strike. Warrior B only uses basic attacks.
	var sys_a := Fixtures.new_system(7)
	var a := Fixtures.warrior(sys_a)
	Fixtures.hunt_rabbits(sys_a, a, 25, true)

	var sys_b := Fixtures.new_system(7)
	var b := Fixtures.warrior(sys_b)
	Fixtures.hunt_rabbits(sys_b, b, 25, false)

	var offer_a := Fixtures.offer_for(a, "basic_weapon_mastery")
	var offer_b := Fixtures.offer_for(b, "basic_weapon_mastery")
	expect(not offer_a.is_empty(), "A was offered a Weapon Mastery evolution")
	expect(not offer_b.is_empty(), "B was offered a Weapon Mastery evolution")
	if offer_a.is_empty() or offer_b.is_empty():
		return
	var opts_a: Array = offer_a["options"]
	var opts_b: Array = offer_b["options"]
	expect(opts_a.has("evo_executioner"), "Power Strike user qualifies for Executioner")
	expect(not opts_b.has("evo_executioner"), "Basic attacker does not")
	expect(opts_a.has("evo_weapon_mastery") and opts_b.has("evo_weapon_mastery"), "Baseline evolution offered to both")
	expect_eq(int(offer_a["hidden_count"]) + opts_a.size(), 5, "Hidden + visible = all evolutions")


func test_offer_shows_hidden_options_as_unknown() -> void:
	var system := Fixtures.new_system(7)
	var w := Fixtures.warrior(system)
	var events: Array[GameEvent] = []
	for i: int in range(25):
		var prey := Fixtures.rabbit(system, Vector2i(1, 0))
		events.append_array(Fixtures.kill(system, w, prey))
	var text := "\n".join(system.notifications_for(w.id, events))
	expect(text.contains("*Skill evolution available: [Basic Weapon Mastery (Inferior)]*"), "Offer header")
	expect(text.contains("[???] (Requirements not met)"), "Unmet options shown as [???]")


func test_choosing_an_evolution_replaces_the_skill() -> void:
	var system := Fixtures.new_system(7)
	var w := Fixtures.warrior(system)
	Fixtures.hunt_rabbits(system, w, 25, true)
	var result := system.submit(ChooseEvolutionCommand.create(w.id, "basic_weapon_mastery", "evo_executioner"))
	expect(result.ok(), "Choice accepted: %s" % result.error)
	expect(not w.skills.has("basic_weapon_mastery"), "Old skill is gone")
	expect(w.skills.has("executioners_weapon_mastery"), "New skill learned")
	var again := system.submit(ChooseEvolutionCommand.create(w.id, "basic_weapon_mastery", "evo_weapon_mastery"))
	expect(not again.ok(), "Choices are permanent. No second pick")


func test_cannot_choose_an_evolution_you_do_not_qualify_for() -> void:
	var system := Fixtures.new_system(7)
	var w := Fixtures.warrior(system)
	Fixtures.hunt_rabbits(system, w, 25, false)
	var result := system.submit(ChooseEvolutionCommand.create(w.id, "basic_weapon_mastery", "evo_duelist"))
	expect(not result.ok(), "Unqualified evolution rejected")


func test_first_in_existence_gets_a_rarity_bump() -> void:
	var system := Fixtures.new_system(7)
	var a := Fixtures.warrior(system, Vector2i(0, 0))
	var b := Fixtures.warrior(system, Vector2i(20, 0))
	Fixtures.hunt_rabbits(system, a, 25, true)
	Fixtures.hunt_rabbits(system, b, 25, true)
	system.submit(ChooseEvolutionCommand.create(a.id, "basic_weapon_mastery", "evo_executioner"))
	system.submit(ChooseEvolutionCommand.create(b.id, "basic_weapon_mastery", "evo_executioner"))
	expect_eq(a.skills["executioners_weapon_mastery"].rarity_bonus, 1, "First to evolve gets +1 rarity")
	expect_eq(b.skills["executioners_weapon_mastery"].rarity_bonus, 0, "Second does not")


func test_baseline_evolution_never_counts_as_a_world_first() -> void:
	var system := Fixtures.new_system(7)
	var w := Fixtures.warrior(system)
	Fixtures.hunt_rabbits(system, w, 25, false)
	system.submit(ChooseEvolutionCommand.create(w.id, "basic_weapon_mastery", "evo_weapon_mastery"))
	expect_eq(w.skills["weapon_mastery"].rarity_bonus, 0, "No bonus for the default path")
	expect(not system.world.firsts.has("evolution:evo_weapon_mastery"), "Not recorded as a first")
