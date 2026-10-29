# System Game

A Primal Hunter–style roguelike where an impartial **System** governs everything in existence. It watches what every entity does, and levels, skills, evolutions and titles follow from those deeds. Nothing is hand-picked and nothing is improvised. Two entities that do the same things get the same results.

**Status: Phase 0, the System core.** It's pure logic with tests and a text demo. There's no gameplay yet.

## Quick start

Requires [Godot 4.7](https://godotengine.org/download) (standard build, not .NET).

1. Open Godot, **Import**, and select this folder's `project.godot`.
2. Press **F5**. The debug scene runs a scripted Warrior run and prints the System's messages. Press **R** to replay with a new seed.

Run the tests from a terminal in this folder:

```bash
godot --headless --import                           # first time only
godot --headless --script res://tests/run_tests.gd
```

(`godot` is the path to your Godot executable.)

## What the System does today

- **One authoritative state.** `WorldState` holds everything. Only `GameCommand`s submitted through `SystemCore.submit()` change it.
- **Commands:** attack (with an optional active skill), move, wait, rest, choose evolution. All of them serialize to dictionaries for saves, replays and future co-op.
- **Behavior profiles.** Every hit, kill and near-death moment is counted per entity.
- **Skills grow from use** and **evolve at a level threshold**. The offer depends on how you played, and unmet options show as `[???]`.
- **Titles** are granted automatically when hidden requirements are met. `first_only` titles can be held by exactly one entity in existence.
- **World firsts.** The first entity to take a given evolution gets +1 rarity, and everyone else sees an announcement.
- **Same rules for monsters.** Wolves level, earn titles and evolve (choosing automatically).
- **Game modes as policies.** Permadeath runs come first. When the player dies, the run ends and only the codex (`MetaState`) carries over. Other modes can be added later without touching the core.
- **Deterministic and saveable.** The same seed and commands give the same world. Save/load preserves the RNG state.

## Content

| | |
|---|---|
| Classes | Warrior, Tank, Archer, Rogue, Healer, Mage. **Warrior, Archer, Mage** are available, and **Warrior** is fully built for testing. Monster classes: Beast, Critter. |
| Warrior skills | Basic Weapon Mastery → 5 evolutions, Power Strike → 3 evolutions |
| Titles | First Blood, Giant Slayer, Unbroken, Wolfbane, Progenitor Slayer (first-only) |

All content is `.tres` data in `content/`. Edit it in the Godot inspector.

## Layout

```
core/      The System (pure logic): state, commands, combat, arbiter, notifier
data/      Resource definitions for content
content/   Classes, skills, titles (.tres)
modes/     Game modes (PermadeathRunMode)
tests/     Headless tests
dev/       Demo scenario
scenes/    Debug view (Phase 1 replaces this with the game)
```

See `CLAUDE.md` for the architecture rules and how to add things.

## Roadmap

- **Phase 0, System core:** done in this commit.
- **Phase 1, playable slice:** grid map with `TileMapLayer`, turn manager, monster AI as commands, a Warrior with a full skill set, pixel art.
- **Phase 2, a living world:** off-screen simulation, multiple zones, records, a persistent-world game mode.
- **Phase 3, co-op:** GodotSteam lobbies. The host owns the state and clients send commands.
- **Phase 4, 3D survival:** a new presentation layer on the same core.
