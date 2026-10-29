extends Control
## Phase 0 debug view. Runs DemoScenario and prints the System's messages.
## No gameplay here yet. Phase 1 replaces this with the grid roguelike.

var _log: RichTextLabel


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("0d0f14")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_log = RichTextLabel.new()
	_log.set_anchors_preset(Control.PRESET_FULL_RECT)
	_log.offset_left = 24
	_log.offset_top = 24
	_log.offset_right = -24
	_log.offset_bottom = -24
	_log.scroll_following = true
	_log.add_theme_color_override("default_color", Color("9fd3ff"))
	add_child(_log)

	_run(1337)


func _unhandled_input(event: InputEvent) -> void:
	# Press R to replay with a new seed.
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_R:
		_run(randi())


func _run(world_seed: int) -> void:
	_log.clear()
	for line: String in DemoScenario.run(world_seed):
		_log.add_text(line + "\n")
	_log.add_text("\n[Press R to run again with a new seed]\n")
