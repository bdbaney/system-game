# CLAUDE.md

Guidance for Claude (and any other AI assistant) working in this repo. Read this before writing code.

## What this project is

A Primal Hunter–style "System" game. The System is an impartial, voiceless set of rules that governs every entity in existence: it watches what entities do, and grants levels, skills, evolutions and titles based on those deeds. It has no personality and never explains itself.

- **Now (Phase 0):** the System core, pure logic, fully tested, no gameplay.
- **Next (Phase 1):** single-player 2D grid roguelike on top of the core.
- **Later:** a persistent world, then host-and-invite co-op (GodotSteam), then a 3D survival game reusing the same core.

## Engine and language

- **Godot 4.7.x**, **GDScript only**. No C#.
- **Static typing everywhere.** `untyped_declaration` is set to *error* in `project.godot`. Type every variable, parameter, return value and `for` loop variable (`for e: EntityState in ...`). Use `:=` only where the type is obvious.
- `integer_division` is also an error. Use `floori(a / float(b))` or `a / b` on floats.

### Godot 3 syntax is banned

Your training data contains a lot of Godot 3. These are all **wrong** here:

| Godot 3 (wrong) | Godot 4 (right) |
|---|---|
| `yield(obj, "signal")` | `await obj.signal` |
| `export var x` / `onready var x` / `tool` | `@export var x` / `@onready var x` / `@tool` |
| `connect("pressed", self, "_on_pressed")` | `pressed.connect(_on_pressed)` |
| `.instance()` | `.instantiate()` |
| `KinematicBody2D`, `Spatial` | `CharacterBody2D`, `Node3D` |
| `move_and_slide(velocity, Vector2.UP)` | set `velocity`, then `move_and_slide()` |
| `rand_range(a, b)` | `randf_range` / `randi_range` (but see RNG rule below) |
| `deg2rad`, `rad2deg` | `deg_to_rad`, `rad_to_deg` |
| `set_shader_param` | `set_shader_parameter` |
| `PoolStringArray` etc. | `PackedStringArray` etc. |
| `TileMap` for new work | `TileMapLayer` |

If you're unsure an API exists in 4.7, check the docs instead of guessing.

## Running things

```bash
godot --headless --import                              # once, or after adding a class_name
godot --headless --script res://tests/run_tests.gd     # run all tests (exit code 1 on failure)
```

Append `< /dev/null` when running from a script or agent. If a script fails to compile, Godot's debugger can wait on stdin and hang instead of exiting.

**Run the tests after every change to `core/`, `data/`, `modes/` or `content/`.** Never report work as done with failing tests.

## Architecture rules (do not break these)

```
core/      The System. Pure logic (RefCounted). No Nodes, no scenes, no rendering.
data/      Resource class definitions: ClassData, SkillData, EvolutionData, TitleData, Requirement.
content/   The actual game content as .tres files. Content is data, not code.
modes/     GameMode policies (what death means, who may act).
tests/     Headless tests. tests/fixtures.gd has helpers.
dev/       Demo scenarios and dev tools.
scenes/    Presentation. Reads state, sends commands. Never writes state.
```

1. **One authoritative state.** Everything that matters lives in `WorldState` (and the `EntityState`s it owns). Long-lived cross-run data lives in `MetaState`.
2. **Only commands change the world.** Every action is a `GameCommand` submitted through `SystemCore.submit()`. Validation must not mutate. Presentation code never sets fields on state directly. (Exception: `SystemCore.spawn()` is the world-authority action for creating entities.)
3. **Events are facts; the Arbiter decides consequences.** Commands and `Combat` record events (damage, kill). Only the `Arbiter` grants XP, skill progress, titles, evolutions and world firsts.
4. **No special cases for the player.** Monsters and NPCs level, earn titles and evolve under exactly the same rules. If you find yourself writing `if is_player` in progression code, stop. (The only player checks allowed: notifications, mode death handling, monsters auto-picking evolutions, codex discoveries.)
5. **Deterministic.** All randomness goes through `world.rng`. Never call the global `randf()`, `randi()` or `randomize()` in `core/`. Iterate dictionaries in a fixed order (sorted keys) when order affects results. A seed plus a command list must replay exactly. The tests enforce this.
6. **Everything serializes.** New state fields must be added to `to_dict()`/`from_dict()`. New commands need `to_dict()`, a `from_dict()`, and a line in `CommandRegistry`. The round-trip tests must still pass. This is what co-op will send over the wire.
7. **No AI at runtime.** The System is deterministic rules. AI helps *author* content offline; it never decides outcomes in-game.
8. **The System's voice is fixed.** Messages come only from `SystemNotifier` templates: terse, formal, identical every time. No flavor text, jokes or personality.

## How to add things

- **A skill, title or class:** create a `.tres` in `content/` (in the inspector, or by copying an existing file). No code changes. Run the tests; `test_content_validates` catches broken references.
- **A new behavior metric** (for requirements): record it in `Arbiter._on_damage` / `_on_kill` (or a new handler) from event data. Metrics are named counters: `"kills"`, namespaced like `"kills_tag:wolf"`, or ratios like `"a/b"`.
- **A new command:** subclass `GameCommand`, implement `type_name`, `validate`, `execute`, `to_dict`, `from_dict`, then register it in `CommandRegistry`. Add a test.
- **A new game mode:** subclass `GameMode` in `modes/`, override `on_entity_died` and `can_act`. The core should not need changes.
- **Any new rule:** add a test that drives it with real commands (see `tests/fixtures.gd`). Tests never poke state directly.

## Content design notes

- Every evolvable skill has one **baseline** evolution with no requirements, so an offer always has at least one option. Baselines have `world_first_bonus = false`.
- Requirements are hidden from the player. Unmet options appear as `[???] (Requirements not met)`.
- Choices are permanent. No respecs.
- `first_only` titles can be held by exactly one entity in existence.
