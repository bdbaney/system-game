extends SceneTree
## Headless test runner. From the project folder:
##
##   godot --headless --import                          # first time only (builds class cache)
##   godot --headless --script res://tests/run_tests.gd
##
## Exits with code 1 if any test fails, so it works in CI too.

const SUITES: Array[String] = [
	"res://tests/test_content.gd",
	"res://tests/test_commands.gd",
	"res://tests/test_progression.gd",
	"res://tests/test_evolution.gd",
	"res://tests/test_modes.gd",
	"res://tests/test_state.gd",
]


func _initialize() -> void:
	var total := 0
	var failed := 0
	for path: String in SUITES:
		print("\n%s" % path.get_file())
		var script: GDScript = load(path)
		var suite: TestCase = script.new()
		for m: Dictionary in suite.get_method_list():
			var method_name: String = m["name"]
			if not method_name.begins_with("test_"):
				continue
			total += 1
			suite.reset()
			suite.call(method_name)
			if suite.failures.is_empty():
				print("  PASS  %s" % method_name)
			else:
				failed += 1
				print("  FAIL  %s" % method_name)
				for f: String in suite.failures:
					print("        - %s" % f)
	print("\n%d tests, %d passed, %d failed" % [total, total - failed, failed])
	quit(1 if failed > 0 else 0)
