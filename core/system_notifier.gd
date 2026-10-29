class_name SystemNotifier
extends RefCounted
## Turns events into System messages for one observer.
## Fixed templates, no variation, no personality. The System does not editorialize.


func format_for(observer_id: int, event: GameEvent, world: WorldState, content: ContentDB) -> String:
	var mine := event.actor_id == observer_id
	match event.type:
		GameEvent.KILL:
			if mine:
				return "*You have slain [%s – lvl %d] – Experience earned*" % [
					str(event.data["victim_name"]), int(event.data["victim_level"])]
			if event.target_id == observer_id:
				return "*You have died*"
		GameEvent.LEVEL_UP:
			if mine:
				var cls: ClassData = content.classes.get(str(event.data["class_id"]))
				var cls_name := cls.display_name if cls else str(event.data["class_id"])
				return "*'%s' has reached level %d – Stat points allocated: %s*" % [
					cls_name, int(event.data["level"]), _format_stats(event.data["gains"] as Dictionary)]
		GameEvent.SKILL_LEVEL_UP:
			if mine:
				var sid := str(event.data["skill_id"])
				return "*Skill %s has reached level %d*" % [
					content.skill_display(sid, _rarity_bonus(world, event.actor_id, sid)), int(event.data["level"])]
		GameEvent.SKILL_EVOLUTION_OFFERED:
			if mine:
				return _format_offer(event, content)
		GameEvent.SKILL_EVOLVED:
			if mine:
				return "*Skill evolved: %s → %s*" % [
					content.skill_display(str(event.data["from"])),
					content.skill_display(str(event.data["to"]), int(event.data["rarity_bonus"]))]
		GameEvent.TITLE_EARNED:
			if mine:
				var t: TitleData = content.titles.get(str(event.data["title_id"]))
				if t:
					return "*Title earned: [%s] – %s*" % [t.display_name, _format_stats(t.stat_bonus)]
		GameEvent.WORLD_FIRST:
			var what := _first_name(event, content)
			if mine:
				return "*World first – You are the first in existence to obtain %s*" % what
			return "*Announcement – A world first has been achieved: %s*" % what
		GameEvent.RUN_ENDED:
			if mine:
				return "*Your run has ended at level %d*" % int(event.data["level"])
	return ""


func format_all(observer_id: int, events: Array[GameEvent], world: WorldState, content: ContentDB) -> Array[String]:
	var out: Array[String] = []
	for e: GameEvent in events:
		var line := format_for(observer_id, e, world, content)
		if line != "":
			out.append(line)
	return out


func _format_offer(event: GameEvent, content: ContentDB) -> String:
	var sid := str(event.data["skill_id"])
	var source: SkillData = content.skills.get(sid)
	var lines: Array[String] = ["*Skill evolution available: %s*" % content.skill_display(sid)]
	var firsts: Array = event.data["first_options"]
	for evo_id: Variant in event.data["options"]:
		var evo := source.find_evolution(str(evo_id))
		var bonus := 1 if firsts.has(evo_id) else 0
		lines.append("  → %s" % content.skill_display(evo.result_skill_id, bonus))
	for i: int in range(int(event.data["hidden_count"])):
		lines.append("  → [???] (Requirements not met)")
	return "\n".join(lines)


func _first_name(event: GameEvent, content: ContentDB) -> String:
	if str(event.data["kind"]) == "title":
		var t: TitleData = content.titles.get(str(event.data["id"]))
		return "[%s]" % (t.display_name if t else str(event.data["id"]))
	return content.skill_display(str(event.data.get("skill_id", "")), 1)


func _rarity_bonus(world: WorldState, entity_id: int, skill_id: String) -> int:
	var e := world.get_entity(entity_id)
	if e and e.skills.has(skill_id):
		return e.skills[skill_id].rarity_bonus
	return 0


func _format_stats(stats: Dictionary) -> String:
	var parts: Array[String] = []
	for stat: Variant in stats:
		parts.append("+%d %s" % [int(stats[stat]), str(stat).capitalize()])
	return ", ".join(parts)
