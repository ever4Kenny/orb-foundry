# RelicManager.gd
# Autoload singleton — manages active relics and dispatches trigger hooks.

extends Node

const CONFIG_PATH := "res://resources/relic_config.json"

signal relic_activated(relic: Dictionary)

var active_relics: Array[Dictionary] = []
var _pool: Array = []
var _pending_round_start_effects: Array[Dictionary] = []

func _ready() -> void:
	_load_pool()
	if OS.get_environment("ORB_DEBUG_ACTIVATE_ALL") == "1":
		for relic in _pool:
			activate(str(relic.get("id", "")))

func _load_pool() -> void:
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_error("RelicManager: cannot open " + CONFIG_PATH)
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		var relics = data.get("relics", [])
		if relics is Array:
			_pool = relics

func activate(relic_id: String) -> void:
	if relic_id.is_empty():
		return
	if has(relic_id):
		return
	for relic in _pool:
		if str(relic.get("id", "")) == relic_id:
			active_relics.append(relic)
			relic_activated.emit(relic)
			return

func has(relic_id: String) -> bool:
	for relic in active_relics:
		if str(relic.get("id", "")) == relic_id:
			return true
	return false

func reset() -> void:
	active_relics.clear()

# Query API for R3
func get_ball_draw_count() -> int:
	for relic in active_relics:
		var effect: Dictionary = relic.get("effect", {})
		if str(effect.get("type", "")) == "ball_draw_count":
			return 3 + int(effect.get("delta", 0))
	return 3

# Query API for R5
func get_center_slot_score(base: int) -> int:
	for relic in active_relics:
		var effect: Dictionary = relic.get("effect", {})
		if str(effect.get("type", "")) == "score_override":
			return base + int(effect.get("value", 0))
	return base

func _dispatch(trigger_name: String, payload: Dictionary) -> void:
	for relic in active_relics:
		if str(relic.get("trigger", "")) != trigger_name:
			continue
		if not _tag_filter_match(relic, payload):
			continue
		var effect: Dictionary = relic.get("effect", {})
		print("[Relic] %s triggered on %s, effect=%s" % [relic.get("id", ""), trigger_name, effect])
		var effect_type := str(effect.get("type", ""))
		match effect_type:
			"remove_pegs":
				# Defer to apply_pending_round_start_effects — store for later
				_pending_round_start_effects.append({
					"relic": relic,
					"payload": payload,
					"round_index": payload.get("round_index", -1)
				})
			"score_bonus":
				ScoreManager.add(int(effect.get("value", 0)))
			"glass_split_threshold":
				var ball_node = payload.get("ball_node")
				if is_instance_valid(ball_node):
					ball_node.split_threshold = int(effect.get("value", 4))
			"magnet_range_mul":
				var ball_node = payload.get("ball_node")
				if is_instance_valid(ball_node):
					ball_node.magnet_range *= float(effect.get("value", 1.5))
			# ball_draw_count and score_override are query-type, handled via get_* APIs
			_:
				pass

func apply_pending_round_start_effects(board: Node) -> void:
	var current_round := RoundManager.current_round
	var remaining: Array[Dictionary] = []
	for entry in _pending_round_start_effects:
		var entry_round: int = entry.get("round_index", -1)
		if entry_round != current_round:
			remaining.append(entry)
			continue
		var relic: Dictionary = entry.get("relic", {})
		var effect: Dictionary = relic.get("effect", {})
		if str(effect.get("type", "")) == "remove_pegs":
			_apply_remove_pegs(relic, board)
	_pending_round_start_effects = remaining

func _apply_remove_pegs(relic: Dictionary, board: Node) -> void:
	var effect: Dictionary = relic.get("effect", {})
	var by_type: Dictionary = effect.get("by_type", {})
	var removed_danger := _remove_random_peg_by_type(board, "danger")
	var removed_normal := _remove_random_peg_by_type(board, "normal")
	print("R1: removed danger peg at %s, normal peg at %s" % [removed_danger, removed_normal])

func _remove_random_peg_by_type(board: Node, peg_type: String) -> String:
	var candidates: Array[Node] = []
	for peg in board.get_tree().get_nodes_in_group("pegs"):
		if not is_instance_valid(peg):
			continue
		if not peg.get("alive"):
			continue
		if str(peg.get("peg_type")) == peg_type:
			candidates.append(peg)
	if candidates.is_empty():
		return "(none)"
	var chosen: Node = candidates[randi() % candidates.size()]
	var pos: Vector2 = chosen.position
	chosen.die()
	return str(pos)

func _tag_filter_match(relic: Dictionary, payload: Dictionary) -> bool:
	if not relic.has("tag_filter"):
		return true
	var filter = relic.get("tag_filter", [])
	if not filter is Array or filter.is_empty():
		return true
	var payload_tags = payload.get("peg_tags", payload.get("slot_tags", []))
	if not payload_tags is Array:
		return false
	for tag in filter:
		if tag in payload_tags:
			return true
	return false
