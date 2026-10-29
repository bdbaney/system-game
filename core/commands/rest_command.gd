class_name RestCommand
extends GameCommand
## Recover to full HP. Not allowed with another living entity adjacent.


static func create(p_actor_id: int) -> RestCommand:
	var c := RestCommand.new()
	c.actor_id = p_actor_id
	return c


func type_name() -> String:
	return "rest"


func validate(world: WorldState, content: ContentDB, mode: GameMode) -> String:
	var err := super.validate(world, content, mode)
	if err != "":
		return err
	var actor := world.get_entity(actor_id)
	for e: EntityState in world.entities.values():
		if e.alive and e.id != actor.id and actor.distance_to(e) <= 1:
			return "Cannot rest with enemies nearby"
	return ""


func execute(world: WorldState, _content: ContentDB) -> void:
	var actor := world.get_entity(actor_id)
	var healed := actor.max_hp() - actor.hp
	actor.hp = actor.max_hp()
	world.record_event(GameEvent.REST, actor.id, -1, {"healed": healed})


static func from_dict(d: Dictionary) -> RestCommand:
	return RestCommand.create(int(d["actor_id"]))
