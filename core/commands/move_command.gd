class_name MoveCommand
extends GameCommand
## Step one cell in any of the 8 directions.

var direction: Vector2i = Vector2i.ZERO


static func create(p_actor_id: int, p_direction: Vector2i) -> MoveCommand:
	var c := MoveCommand.new()
	c.actor_id = p_actor_id
	c.direction = p_direction
	return c


func type_name() -> String:
	return "move"


func validate(world: WorldState, content: ContentDB, mode: GameMode) -> String:
	var err := super.validate(world, content, mode)
	if err != "":
		return err
	if direction == Vector2i.ZERO or absi(direction.x) > 1 or absi(direction.y) > 1:
		return "Invalid direction"
	var actor := world.get_entity(actor_id)
	if world.entity_at(actor.position + direction) != null:
		return "Cell is occupied"
	return ""


func execute(world: WorldState, _content: ContentDB) -> void:
	var actor := world.get_entity(actor_id)
	var from := actor.position
	actor.position += direction
	world.record_event(GameEvent.MOVE, actor.id, -1, {
		"from": [from.x, from.y],
		"to": [actor.position.x, actor.position.y],
	})


func to_dict() -> Dictionary:
	var d := super.to_dict()
	d["direction"] = [direction.x, direction.y]
	return d


static func from_dict(d: Dictionary) -> MoveCommand:
	var dir: Array = d["direction"]
	return MoveCommand.create(int(d["actor_id"]), Vector2i(int(dir[0]), int(dir[1])))
