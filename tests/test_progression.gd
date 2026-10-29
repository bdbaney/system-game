extends TestCase
## XP, skill growth and titles. Everything here applies to monsters exactly as to players.


func test_kill_grants_xp_and_first_blood() -> void:
	var system := Fixtures.new_system()
	var w := Fixtures.warrior(system)
	var r := Fixtures.rabbit(system, Vector2i(1, 0))
	var events := Fixtures.kill(system, w, r)
	expect(not r.alive, "Rabbit died")
	expect_eq(int(w.profile.get_metric("kills")), 1, "Kill counted")
	expect(w.xp > 0 or w.level > 1, "XP granted")
	expect(w.titles.has("first_blood"), "First Blood earned")
	expect_eq(w.bonus_stats.get("strength", 0), 1, "First Blood strength bonus applied")
	var lines := system.notifications_for(w.id, events)
	expect(lines.has("*You have slain [Rabbit – lvl 1] – Experience earned*"), "Kill message uses the fixed template")


func test_skills_level_from_use() -> void:
	var system := Fixtures.new_system()
	var w := Fixtures.warrior(system)
	Fixtures.hunt_rabbits(system, w, 5)
	var mastery: SkillState = w.skills["basic_weapon_mastery"]
	expect(mastery.uses >= 5, "Weapon mastery used on every hit")
	expect(mastery.level >= 2, "Weapon mastery leveled from use")
	expect_eq(w.skills["power_strike"].uses, 0, "Unused skill does not grow")


func test_monsters_follow_the_same_rules() -> void:
	var system := Fixtures.new_system()
	var wolf := Fixtures.wolf(system, Vector2i.ZERO)
	Fixtures.hunt_rabbits(system, wolf, 10)
	expect(wolf.level > 1, "Wolf leveled from kills")
	expect(wolf.titles.has("first_blood"), "Wolf earned First Blood too")
	expect(not wolf.skills.has("natural_weapons"), "Wolf's Natural Weapons evolved on its own")
	expect(wolf.pending_evolutions.is_empty(), "Monsters choose their evolutions automatically")


func test_kill_above_level_grants_giant_slayer_and_bonus_xp() -> void:
	var system := Fixtures.new_system()
	var w := Fixtures.warrior(system)
	var big := Fixtures.wolf(system, Vector2i(1, 0), 4)
	Fixtures.kill(system, w, big)
	expect(w.titles.has("giant_slayer"), "Giant Slayer for a kill 3+ levels up")
	expect(Progression.kill_xp(1, 4) > Progression.kill_xp(4, 4), "Killing above your level pays more")


func test_first_only_title_goes_to_exactly_one_entity() -> void:
	var system := Fixtures.new_system()
	var a := Fixtures.warrior(system, Vector2i(0, 0))
	var b := Fixtures.warrior(system, Vector2i(10, 0))
	var boss_a := Fixtures.boss(system, Vector2i(1, 0), 4)
	var boss_b := Fixtures.boss(system, Vector2i(11, 0), 4)
	var events := Fixtures.kill(system, a, boss_a)
	Fixtures.kill(system, b, boss_b)
	expect(a.titles.has("progenitor_slayer"), "First boss killer gets Progenitor Slayer")
	expect(not b.titles.has("progenitor_slayer"), "Second boss killer does not")
	expect(b.titles.has("giant_slayer"), "Second killer still gets non-exclusive titles")
	expect_eq(system.world.firsts.get("title:progenitor_slayer", -1), a.id, "Firsts ledger records the claimer")
	var b_lines := system.notifications_for(b.id, events)
	expect(b_lines.has("*Announcement – A world first has been achieved: [Progenitor Slayer]*"),
		"Other players see the world-first announcement")
