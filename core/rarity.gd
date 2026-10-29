class_name Rarity
extends RefCounted
## Rarity tiers for skills, titles, and anything else the System grades.

enum Tier { INFERIOR, COMMON, UNCOMMON, RARE, EPIC, ANCIENT, LEGENDARY, MYTHICAL, DIVINE }

const NAMES: Array[String] = [
	"Inferior", "Common", "Uncommon", "Rare", "Epic",
	"Ancient", "Legendary", "Mythical", "Divine",
]


static func name_of(tier: int) -> String:
	return NAMES[clampi(tier, 0, NAMES.size() - 1)]


## Returns the tier raised by `steps`, capped at the highest tier.
static func bump(tier: int, steps: int = 1) -> int:
	return clampi(tier + steps, 0, NAMES.size() - 1)
