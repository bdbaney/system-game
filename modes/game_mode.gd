class_name GameMode
extends Resource
## A game mode is a policy over the authoritative state. It decides what death means
## and who is allowed to act. The System core does not know which mode is running.
##
## To add a mode (persistent world, hardcore, co-op...): subclass this and override
## on_entity_died() and can_act(). Nothing else in the core should need to change.

@export var mode_id: String = "base"
@export var display_name: String = "Base"


## Called by the Arbiter when any entity dies.
func on_entity_died(_world: WorldState, _meta: MetaState, _entity: EntityState) -> void:
	pass


## Commands from an actor are rejected unless this returns true.
func can_act(_world: WorldState, entity: EntityState) -> bool:
	return entity.alive
