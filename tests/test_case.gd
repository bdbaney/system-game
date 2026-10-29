class_name TestCase
extends RefCounted
## Minimal test base class. Any method starting with "test_" is run by tests/run_tests.gd.

var failures: Array[String] = []


func reset() -> void:
	failures.clear()


func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("%s (got %s, expected %s)" % [message, str(actual), str(expected)])
