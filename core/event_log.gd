class_name EventLog
extends RefCounted
## Append-only record of every GameEvent in a world. The System sees everything.

var _events: Array[GameEvent] = []


func append(event: GameEvent) -> void:
	_events.append(event)


func size() -> int:
	return _events.size()


func at(index: int) -> GameEvent:
	return _events[index]


func slice_from(index: int) -> Array[GameEvent]:
	var out: Array[GameEvent] = []
	for i: int in range(index, _events.size()):
		out.append(_events[i])
	return out


func to_array() -> Array:
	var out: Array = []
	for e: GameEvent in _events:
		out.append(e.to_dict())
	return out


static func from_array(items: Array) -> EventLog:
	var log_out := EventLog.new()
	for d: Variant in items:
		log_out.append(GameEvent.from_dict(d as Dictionary))
	return log_out
