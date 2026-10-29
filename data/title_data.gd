class_name TitleData
extends Resource
## Definition of a title. Granted automatically the moment the requirements are met.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rarity: Rarity.Tier = Rarity.Tier.COMMON
@export var requirements: Array[Requirement] = []
## Only one entity in existence can ever hold this title.
@export var first_only: bool = false
@export var stat_bonus: Dictionary[String, int] = {}
