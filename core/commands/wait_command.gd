class_name WaitCommand
extends GameCommand
## Do nothing for a turn.


static func create(p_actor_id: int) -> WaitCommand:
	var c := WaitCommand.new()
	c.actor_id = p_actor_id
	return c


func type_name() -> String:
	return "wait"


func execute(world: WorldState, _content: ContentDB) -> void:
	world.record_event(GameEvent.WAIT, actor_id, -1, {})


static func from_dict(d: Dictionary) -> WaitCommand:
	return WaitCommand.create(int(d["actor_id"]))
