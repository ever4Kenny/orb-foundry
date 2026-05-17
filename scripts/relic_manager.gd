# RelicManager.gd
# Autoload singleton — manages active relics and dispatches trigger hooks.
# Stage 1: trigger pipeline only. Effects are logged, not applied.

extends Node

const CONFIG_PATH := "res://resources/relic_config.json"

var active_relics: Array[Dictionary] = []
var _pool: Array = []

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
			return

func has(relic_id: String) -> bool:
	for relic in active_relics:
		if str(relic.get("id", "")) == relic_id:
			return true
	return false

func reset() -> void:
	active_relics.clear()

func _dispatch(trigger_name: String, payload: Dictionary) -> void:
	for relic in active_relics:
		if str(relic.get("trigger", "")) != trigger_name:
			continue
		if not _tag_filter_match(relic, payload):
			continue
		print("[Relic] %s triggered on %s, effect=%s" % [relic.get("id", ""), trigger_name, relic.get("effect", {})])

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
