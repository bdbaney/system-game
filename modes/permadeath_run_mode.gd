class_name PermadeathRunMode
extends GameMode
## Classic roguelike runs: when every player is dead the run ends and the world is
## discarded. Only MetaState (the codex and run history) carries into the next run.


func _init() -> void:
	mode_id = "permadeath_run"
	display_name = "Permadeath Run"


func on_entity_died(world: WorldState, meta: MetaState, entity: EntityState) -> void:
	if not entity.is_player:
		return
	for p: EntityState in world.players():
		if p.alive:
			return
	world.run_over = true
	meta.record_run_end(entity)
	world.record_event(GameEvent.RUN_ENDED, entity.id, -1, {
		"level": entity.level,
		"tick": world.tick,
		"mode": mode_id,
	})


func can_act(world: WorldState, entity: EntityState) -> bool:
	return entity.alive and not world.run_over
