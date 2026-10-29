class_name ClassData
extends Resource
## Definition of a class. Player classes and monster "classes" (beast, critter)
## use the same resource, because monsters level by the same rules as players.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
## False for monster classes.
@export var playable: bool = true
## Playable classes that can be picked in this build.
@export var available: bool = false
@export var base_stats: Dictionary[String, int] = {}
@export var stats_per_level: Dictionary[String, int] = {}
@export var starting_skills: Array[String] = []
