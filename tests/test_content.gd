extends TestCase
## Content is data. These tests catch broken references before they become runtime bugs.


func test_content_validates() -> void:
	var problems := Fixtures.content().validate()
	expect(problems.is_empty(), "Content problems: %s" % ", ".join(problems))


func test_six_playable_classes_with_three_available() -> void:
	var playable := Fixtures.content().playable_classes()
	expect_eq(playable.size(), 6, "Playable class count")
	var available: Array[String] = []
	for c: ClassData in playable:
		if c.available:
			available.append(c.id)
	available.sort()
	expect_eq(available, ["archer", "mage", "warrior"] as Array[String], "Available classes")


func test_monster_classes_are_not_playable() -> void:
	var db := Fixtures.content()
	expect(not db.classes["beast"].playable, "Beast is not playable")
	expect(not db.classes["critter"].playable, "Critter is not playable")


func test_warrior_spawns_with_class_stats_and_skills() -> void:
	var system := Fixtures.new_system()
	var w := Fixtures.warrior(system)
	expect_eq(w.level, 1, "Starts at level 1")
	expect_eq(w.get_stat("strength"), 8, "Warrior base strength")
	expect_eq(w.hp, w.max_hp(), "Spawns at full HP")
	expect(w.skills.has("basic_weapon_mastery"), "Has Basic Weapon Mastery")
	expect(w.skills.has("power_strike"), "Has Power Strike")


func test_spawning_above_level_one_applies_class_growth() -> void:
	var system := Fixtures.new_system()
	var wolf := Fixtures.wolf(system, Vector2i(3, 3), 5)
	# Beast: 6 base strength, +1 per level → 10 at level 5.
	expect_eq(wolf.get_stat("strength"), 10, "Level 5 wolf strength")
