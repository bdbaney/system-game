class_name GameCommand
extends RefCounted
## Base class for every action. Player input, monster AI and (later) messages from co-op
## clients all become GameCommands. The authority (SystemCore.submit) validates and
## executes them. Nothing else is allowed to change the WorldState.
##
## Every command must round-trip through to_dict()/CommandRegistry.from_dict(), because
## that dictionary is what a co-op client will send to the host.

var actor_id: int = -1


func type_name() -> String:
	return "base"


## Returns "" if the command may run, otherwise the reason it can't.
## Must not change any state.
func validate(world: WorldState, _content: ContentDB, mode: GameMode) -> String:
	return _check_actor(world, mode)


## Applies the command. Only called after validate() returned "".
func execute(_world: WorldState, _content: ContentDB) -> void:
	pass


func to_dict() -> Dictionary:
	return {"type": type_name(), "actor_id": actor_id}


func _check_actor(world: WorldState, mode: GameMode) -> String:
	var actor := world.get_entity(actor_id)
	if actor == null:
		return "Unknown actor"
	if not mode.can_act(world, actor):
		return "Actor cannot act"
	return ""
