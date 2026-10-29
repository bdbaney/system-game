class_name BehaviorProfile
extends RefCounted
## Everything the System has observed about one entity, reduced to named counters.
## Requirements on skills, titles and evolutions are predicates over these metrics.
##
## Metric names:
##   "kills", "melee_hits", "flawless_kills", ...   plain counters
##   "kills_tag:wolf", "skill_uses:power_strike"    namespaced counters
##   "skill_uses:power_strike/melee_hits"            ratio of two metrics (denominator min 1)

var counters: Dictionary[String, float] = {}


func add(metric: String, amount: float = 1.0) -> void:
	counters[metric] = float(counters.get(metric, 0.0)) + amount


func set_max(metric: String, value: float) -> void:
	if not counters.has(metric) or value > float(counters[metric]):
		counters[metric] = value


func get_metric(metric: String) -> float:
	if "/" in metric:
		var parts := metric.split("/", false, 1)
		if parts.size() != 2:
			push_error("BehaviorProfile: malformed ratio metric '%s'" % metric)
			return 0.0
		return get_metric(parts[0]) / maxf(get_metric(parts[1]), 1.0)
	return float(counters.get(metric, 0.0))


func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for k: String in counters:
		out[k] = counters[k]
	return out


static func from_dict(d: Dictionary) -> BehaviorProfile:
	var p := BehaviorProfile.new()
	for k: Variant in d:
		p.counters[str(k)] = float(d[k])
	return p
