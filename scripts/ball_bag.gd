# BallBag.gd
# Autoload singleton — manages ball inventory

extends Node

signal bag_changed(available_balls: Array)
signal reroll_used(remaining: int)

var _entries: Array = []  # [{id: String, used: bool}]
var reroll_remaining: int = 2

func _ready() -> void:
	_load_config()
	RoundManager.round_started.connect(_on_round_started)

func _on_round_started(_round_index: int, _round_data: Dictionary) -> void:
	for entry in _entries:
		entry.used = false
	emit_signal("bag_changed", get_available_ids())

func _load_config() -> void:
	var cfg = _load_json("res://resources/ball_config.json")
	if cfg == null:
		return
	_reset_from_config(cfg)

func _load_json(path: String):
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Cannot open: " + path)
		return null
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	return data

func _reset_from_config(cfg: Dictionary) -> void:
	_entries.clear()
	var initial: Array = cfg.get("initial_bag", [])
	for id in initial:
		_entries.append({"id": id, "used": false})

func reset() -> void:
	_load_config()
	reroll_remaining = 2

func draw(n: int = 3) -> Array:
	var avail = _entries.filter(func(e): return not e.used)
	if avail.is_empty():
		# Refill
		var cfg = _load_json("res://resources/ball_config.json")
		var refill: Array = cfg.get("refill_balls", ["iron", "iron"])
		for id in refill:
			_entries.append({"id": id, "used": false})
		avail = _entries.filter(func(e): return not e.used)
	avail.shuffle()
	var drawn = avail.slice(0, min(n, avail.size()))
	emit_signal("bag_changed", get_available_ids())
	return drawn

func get_all_available() -> Array:
	var avail = _entries.filter(func(e): return not e.used)
	if avail.is_empty():
		var cfg = _load_json("res://resources/ball_config.json")
		var refill: Array = cfg.get("refill_balls", ["iron", "iron"])
		for id in refill:
			_entries.append({"id": id, "used": false})
		avail = _entries.filter(func(e): return not e.used)
		emit_signal("bag_changed", get_available_ids())
	return avail

func use_ball(ball_id: String) -> bool:
	for entry in _entries:
		if not entry.used and entry.id == ball_id:
			entry.used = true
			emit_signal("bag_changed", get_available_ids())
			return true
	return false

func add_ball(ball_id: String) -> void:
	_entries.append({"id": ball_id, "used": false})
	emit_signal("bag_changed", get_available_ids())

func get_available_ids() -> Array:
	var ids = []
	for entry in _entries:
		if not entry.used:
			ids.append(entry.id)
	return ids

func get_available_count() -> int:
	return get_available_ids().size()

func get_total_count() -> int:
	return _entries.size()

func reroll() -> bool:
	if reroll_remaining <= 0:
		return false
	reroll_remaining -= 1
	reroll_used.emit(reroll_remaining)
	return true
