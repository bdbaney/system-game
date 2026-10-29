class_name ChooseEvolutionCommand
extends GameCommand
## Pick one of the evolutions the System offered for a skill. Permanent.

var skill_id: String = ""
var evolution_id: String = ""


static func create(p_actor_id: int, p_skill_id: String, p_evolution_id: String) -> ChooseEvolutionCommand:
	var c := ChooseEvolutionCommand.new()
	c.actor_id = p_actor_id
	c.skill_id = p_skill_id
	c.evolution_id = p_evolution_id
	return c


func type_name() -> String:
	return "choose_evolution"


func validate(world: WorldState, content: ContentDB, mode: GameMode) -> String:
	var err := super.validate(world, content, mode)
	if err != "":
		return err
	return Arbiter.check_evolution_choice(world.get_entity(actor_id), skill_id, evolution_id)


func execute(world: WorldState, content: ContentDB) -> void:
	Arbiter.apply_evolution(world, content, world.get_entity(actor_id), skill_id, evolution_id)


func to_dict() -> Dictionary:
	var d := super.to_dict()
	d["skill_id"] = skill_id
	d["evolution_id"] = evolution_id
	return d


static func from_dict(d: Dictionary) -> ChooseEvolutionCommand:
	return ChooseEvolutionCommand.create(int(d["actor_id"]), str(d["skill_id"]), str(d["evolution_id"]))
