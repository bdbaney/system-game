class_name Requirement
extends Resource
## One hidden predicate checked against an entity's BehaviorProfile.
## Players never see these. They only see the results.

## A BehaviorProfile metric, e.g. "kills", "kills_tag:wolf",
## or a ratio such as "skill_uses:power_strike/melee_hits".
@export var metric: String = ""
@export_enum(">=", ">", "<=", "<", "==") var op: String = ">="
@export var value: float = 0.0


static func create(p_metric: String, p_op: String, p_value: float) -> Requirement:
	var r := Requirement.new()
	r.metric = p_metric
	r.op = p_op
	r.value = p_value
	return r


func is_met(profile: BehaviorProfile) -> bool:
	var actual := profile.get_metric(metric)
	match op:
		">=":
			return actual >= value
		">":
			return actual > value
		"<=":
			return actual <= value
		"<":
			return actual < value
		"==":
			return is_equal_approx(actual, value)
	push_error("Requirement: unknown op '%s'" % op)
	return false


static func all_met(reqs: Array[Requirement], profile: BehaviorProfile) -> bool:
	for r: Requirement in reqs:
		if not r.is_met(profile):
			return false
	return true
