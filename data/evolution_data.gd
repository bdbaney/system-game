class_name EvolutionData
extends Resource
## One possible evolution of a skill. Offered only if every requirement is met.

@export var id: String = ""
@export var result_skill_id: String = ""
@export var requirements: Array[Requirement] = []
## If true, the first entity in existence to take this evolution gets +1 rarity.
## Turn this off for baseline evolutions that anyone can take, so firsts stay meaningful.
@export var world_first_bonus: bool = true
