class_name AttackCommand
extends GameCommand
## Melee attack on an adjacent target, optionally using an active melee skill.

var target_id: int = -1
## Active skill to use, or "" for a basic attack.
var skill_id: String = ""


static func create(p_actor_id: int, p_target_id: int, p_skill_id: String = "") -> AttackCommand:
	var c := AttackCommand.new()
	c.actor_id = p_actor_id
	c.target_id = p_target_id
	c.skill_id = p_skill_id
	return c


func type_name() -> String:
	return "attack"


func validate(world: WorldState, content: ContentDB, mode: GameMode) -> String:
	var err := _check_actor(world, mode)
	if err != "":
		return err
	var actor := world.get_entity(actor_id)
	var target := world.get_entity(target_id)
	if target == null or not target.alive:
		return "Invalid target"
	if target.id == actor.id:
		return "Cannot attack yourself"
	if actor.distance_to(target) > 1:
		return "Target is out of melee range"
	if skill_id != "":
		if not actor.skills.has(skill_id):
			return "Skill not known"
		var data: SkillData = content.skills.get(skill_id)
		if data == null or data.kind != SkillData.Kind.ACTIVE or not data.tags.has("melee"):
			return "Skill is not an active melee attack"
	return ""


func execute(world: WorldState, content: ContentDB) -> void:
	Combat.melee_attack(world, content, world.get_entity(actor_id), world.get_entity(target_id), skill_id)


func to_dict() -> Dictionary:
	var d := super.to_dict()
	d["target_id"] = target_id
	d["skill_id"] = skill_id
	return d


static func from_dict(d: Dictionary) -> AttackCommand:
	return AttackCommand.create(int(d["actor_id"]), int(d["target_id"]), str(d.get("skill_id", "")))
