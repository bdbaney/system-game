class_name Combat
extends RefCounted
## Combat resolution. Produces facts (damage, kill, death events) only.
## It does not grant XP or skill progress. That is the Arbiter's job.


static func melee_attack(world: WorldState, content: ContentDB, attacker: EntityState, target: EntityState, active_skill_id: String) -> void:
	var skills_used: Array = []
	var mult := 1.0
	if active_skill_id != "":
		var active: SkillData = content.skills[active_skill_id]
		mult = active.damage_multiplier
		skills_used.append(active_skill_id)
	for sid: String in attacker.skills:
		var data: SkillData = content.skills.get(sid)
		if data and data.kind == SkillData.Kind.PASSIVE and data.tags.has("melee"):
			var state: SkillState = attacker.skills[sid]
			mult += data.passive_damage_bonus * state.level
			skills_used.append(sid)

	var raw := attacker.get_stat("strength") * mult * world.rng.randf_range(0.85, 1.15)
	var dmg := maxi(1, roundi(raw - target.get_stat("toughness") * 0.5))
	target.hp = maxi(0, target.hp - dmg)
	target.damage_taken_from[attacker.id] = int(target.damage_taken_from.get(attacker.id, 0)) + dmg

	world.record_event(GameEvent.DAMAGE, attacker.id, target.id, {
		"amount": dmg,
		"melee": true,
		"active_skill_id": active_skill_id,
		"skills_used": skills_used,
		"target_hp": target.hp,
		"target_max_hp": target.max_hp(),
	})

	if target.hp <= 0:
		target.alive = false
		world.record_event(GameEvent.KILL, attacker.id, target.id, {
			"killer_level": attacker.level,
			"victim_level": target.level,
			"victim_name": target.display_name,
			"victim_tags": Array(target.tags),
			"killer_hp_ratio": attacker.hp_ratio(),
			"flawless": int(attacker.damage_taken_from.get(target.id, 0)) == 0,
		})
		world.record_event(GameEvent.DEATH, target.id, attacker.id, {})
