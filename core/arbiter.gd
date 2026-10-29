class_name Arbiter
extends RefCounted
## The System's judgment.
##
## Reads events, updates behavior profiles, and applies every consequence: XP,
## skill growth, titles, evolution offers, world firsts and death handling.
## It is fully deterministic. The same events always produce the same consequences.
## There is no AI here and no randomness outside world.rng.

var mode: GameMode
var meta: MetaState


func _init(p_mode: GameMode, p_meta: MetaState) -> void:
	mode = p_mode
	meta = p_meta


## Processes every event from `start_index` to the end of the log, including events
## produced while processing, then runs title and evolution checks on every entity
## whose profile changed.
func process_from(world: WorldState, content: ContentDB, start_index: int) -> void:
	var i := start_index
	var dirty: Dictionary[int, bool] = {}
	while true:
		while i < world.events.size():
			_handle(world, content, world.events.at(i), dirty)
			i += 1
		if dirty.is_empty():
			break
		var ids: Array[int] = []
		for id: int in dirty:
			ids.append(id)
		ids.sort()
		dirty.clear()
		for id: int in ids:
			var e := world.get_entity(id)
			if e == null or not e.alive:
				continue
			_check_titles(world, content, e)
			_check_evolutions(world, content, e)


func _handle(world: WorldState, content: ContentDB, event: GameEvent, dirty: Dictionary[int, bool]) -> void:
	match event.type:
		GameEvent.DAMAGE:
			_on_damage(world, content, event, dirty)
		GameEvent.KILL:
			_on_kill(world, content, event, dirty)
		GameEvent.DEATH:
			var dead := world.get_entity(event.actor_id)
			if dead:
				mode.on_entity_died(world, meta, dead)
		GameEvent.TITLE_EARNED:
			var holder := world.get_entity(event.actor_id)
			if holder and holder.is_player:
				meta.record_discovery("title", str(event.data["title_id"]))
		GameEvent.SKILL_EVOLVED:
			var evolver := world.get_entity(event.actor_id)
			if evolver and evolver.is_player:
				meta.record_discovery("skill", str(event.data["to"]))


func _on_damage(world: WorldState, content: ContentDB, event: GameEvent, dirty: Dictionary[int, bool]) -> void:
	var amount := int(event.data["amount"])
	var attacker := world.get_entity(event.actor_id)
	if attacker:
		if bool(event.data.get("melee", false)):
			attacker.profile.add("melee_hits")
		attacker.profile.add("damage_dealt", amount)
		for sid: Variant in event.data["skills_used"]:
			attacker.profile.add("skill_uses:" + str(sid))
			Progression.use_skill(world, content, attacker, str(sid))
		dirty[attacker.id] = true
	var target := world.get_entity(event.target_id)
	if target:
		target.profile.add("hits_taken")
		target.profile.add("damage_taken", amount)
		var hp_left := int(event.data["target_hp"])
		var hp_max := maxi(1, int(event.data["target_max_hp"]))
		if hp_left > 0 and float(hp_left) / float(hp_max) <= 0.10:
			target.profile.add("near_death_survivals")
		dirty[target.id] = true


func _on_kill(world: WorldState, content: ContentDB, event: GameEvent, dirty: Dictionary[int, bool]) -> void:
	var killer := world.get_entity(event.actor_id)
	if killer == null:
		return
	var killer_level := int(event.data["killer_level"])
	var victim_level := int(event.data["victim_level"])
	var gap := victim_level - killer_level
	killer.profile.add("kills")
	for tag: Variant in event.data["victim_tags"]:
		killer.profile.add("kills_tag:" + str(tag))
	if gap >= 3:
		killer.profile.add("kills_above_level_3")
	killer.profile.set_max("max_kill_level_gap", gap)
	if float(event.data["killer_hp_ratio"]) <= 0.25:
		killer.profile.add("low_hp_kills")
	if bool(event.data["flawless"]):
		killer.profile.add("flawless_kills")
	Progression.grant_xp(world, content, killer, Progression.kill_xp(killer_level, victim_level))
	dirty[killer.id] = true


func _check_titles(world: WorldState, content: ContentDB, e: EntityState) -> void:
	for tid: String in content.sorted_title_ids():
		if e.titles.has(tid):
			continue
		var t: TitleData = content.titles[tid]
		if not Requirement.all_met(t.requirements, e.profile):
			continue
		if t.first_only and not world.claim_first("title:" + tid, e.id):
			continue
		e.titles.append(tid)
		for stat: String in t.stat_bonus:
			e.bonus_stats[stat] = int(e.bonus_stats.get(stat, 0)) + t.stat_bonus[stat]
		world.record_event(GameEvent.TITLE_EARNED, e.id, -1, {
			"title_id": tid,
			"first_only": t.first_only,
		})
		if t.first_only:
			world.record_event(GameEvent.WORLD_FIRST, e.id, -1, {"kind": "title", "id": tid})


func _check_evolutions(world: WorldState, content: ContentDB, e: EntityState) -> void:
	for sid: String in e.skills.keys():
		var state: SkillState = e.skills[sid]
		var data: SkillData = content.skills.get(sid)
		if data == null or data.evolution_level <= 0 or data.evolutions.is_empty():
			continue
		if state.evolution_offered or state.level < data.evolution_level:
			continue
		var eligible: Array = []
		var first_options: Array = []
		for evo: EvolutionData in data.evolutions:
			if Requirement.all_met(evo.requirements, e.profile):
				eligible.append(evo.id)
				if evo.world_first_bonus and not world.firsts.has("evolution:" + evo.id):
					first_options.append(evo.id)
		if eligible.is_empty():
			# Nothing qualifies yet. Check again as the entity keeps acting.
			continue
		state.evolution_offered = true
		var offer := {
			"skill_id": sid,
			"options": eligible,
			"first_options": first_options,
			"hidden_count": data.evolutions.size() - eligible.size(),
		}
		e.pending_evolutions.append(offer)
		world.record_event(GameEvent.SKILL_EVOLUTION_OFFERED, e.id, -1, offer.duplicate(true))
		if not e.is_player:
			# Monsters choose by the same rules every time: highest rarity, then list order.
			apply_evolution(world, content, e, sid, _auto_pick(content, data, eligible))


func _auto_pick(content: ContentDB, data: SkillData, eligible: Array) -> String:
	var best_id := ""
	var best_rarity := -1
	for evo_id: Variant in eligible:
		var evo := data.find_evolution(str(evo_id))
		var result: SkillData = content.skills[evo.result_skill_id]
		if int(result.rarity) > best_rarity:
			best_rarity = int(result.rarity)
			best_id = evo.id
	return best_id


## Returns "" if `evolution_id` can be chosen for `skill_id` right now, or the reason it can't.
static func check_evolution_choice(e: EntityState, skill_id: String, evolution_id: String) -> String:
	for offer: Dictionary in e.pending_evolutions:
		if str(offer["skill_id"]) == skill_id:
			if (offer["options"] as Array).has(evolution_id):
				return ""
			return "That evolution is not available"
	return "No evolution is pending for that skill"


static func apply_evolution(world: WorldState, content: ContentDB, e: EntityState, skill_id: String, evolution_id: String) -> String:
	var err := check_evolution_choice(e, skill_id, evolution_id)
	if err != "":
		return err
	for i: int in range(e.pending_evolutions.size()):
		if str(e.pending_evolutions[i]["skill_id"]) == skill_id:
			e.pending_evolutions.remove_at(i)
			break
	var data: SkillData = content.skills[skill_id]
	var evo := data.find_evolution(evolution_id)
	var result: SkillData = content.skills[evo.result_skill_id]
	e.skills.erase(skill_id)
	var new_state := SkillState.create(result.id)
	var first := evo.world_first_bonus and world.claim_first("evolution:" + evolution_id, e.id)
	if first:
		new_state.rarity_bonus = 1
	e.skills[result.id] = new_state
	world.record_event(GameEvent.SKILL_EVOLVED, e.id, -1, {
		"from": skill_id,
		"to": result.id,
		"evolution_id": evolution_id,
		"rarity_bonus": new_state.rarity_bonus,
		"world_first": first,
	})
	if first:
		world.record_event(GameEvent.WORLD_FIRST, e.id, -1, {
			"kind": "evolution",
			"id": evolution_id,
			"skill_id": result.id,
		})
	return ""
