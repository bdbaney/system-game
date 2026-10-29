class_name SkillData
extends Resource
## Definition of a skill. Per-entity progress lives in SkillState.

enum Kind { PASSIVE, ACTIVE }

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rarity: Rarity.Tier = Rarity.Tier.INFERIOR
@export var kind: Kind = Kind.PASSIVE
## "melee", "ranged", "magic", "weapon", "strike"...
@export var tags: Array[String] = []
## Active skills: damage multiplier when used.
@export var damage_multiplier: float = 1.0
## Passive melee skills: added to the damage multiplier per skill level.
@export var passive_damage_bonus: float = 0.0
## Uses needed to gain one skill level.
@export var xp_per_level: int = 5
## Skill level at which evolutions are checked. 0 = this skill does not evolve.
@export var evolution_level: int = 0
@export var evolutions: Array[EvolutionData] = []


func find_evolution(evolution_id: String) -> EvolutionData:
	for evo: EvolutionData in evolutions:
		if evo.id == evolution_id:
			return evo
	return null
