class_name CommandResult
extends RefCounted
## What SystemCore.submit() returns: either an error, or the events the command caused.

var error: String = ""
var events: Array[GameEvent] = []


func ok() -> bool:
	return error == ""
