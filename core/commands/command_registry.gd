class_name CommandRegistry
extends RefCounted
## Rebuilds a GameCommand from its dictionary form (save files, replays, network).
## Register every new command type here.


static func from_dict(d: Dictionary) -> GameCommand:
	match str(d.get("type", "")):
		"attack":
			return AttackCommand.from_dict(d)
		"move":
			return MoveCommand.from_dict(d)
		"wait":
			return WaitCommand.from_dict(d)
		"rest":
			return RestCommand.from_dict(d)
		"choose_evolution":
			return ChooseEvolutionCommand.from_dict(d)
	push_error("CommandRegistry: unknown command type '%s'" % str(d.get("type", "")))
	return null
