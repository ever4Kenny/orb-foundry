# post_round2_select.gd
# 第 2 关后：relic 三选一 → 改造二选一（顺序双选）
extends CanvasLayer

enum Phase { RELIC, UPGRADE, DONE }

const UPGRADE_CONFIG_PATH := "res://resources/upgrade_config.json"

var _phase: Phase = Phase.RELIC
var _relic_options: Array = []
var _upgrade_options: Array = []
var _all_upgrades: Array = []

var _title_label: Label
var _container: VBoxContainer
var _bg: ColorRect

func _ready() -> void:
	_all_upgrades = _load_upgrades()
	_build_ui()
	visible = false

func _process(_delta: float) -> void:
	var should_show := RoundManager.state == RoundManager.GameState.POST_ROUND2_SELECT
	if should_show and not visible:
		_start_selection()
	visible = should_show and _phase != Phase.DONE

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.75)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.position = Vector2(960 - 200, 240)
	_title_label.custom_minimum_size = Vector2(400, 40)
	add_child(_title_label)

	_container = VBoxContainer.new()
	_container.name = "Options"
	_container.position = Vector2(960 - 210, 300)
	_container.custom_minimum_size = Vector2(420, 400)
	_container.add_theme_constant_override("separation", 12)
	add_child(_container)

func _start_selection() -> void:
	_phase = Phase.RELIC
	_show_relic_phase()

func _show_relic_phase() -> void:
	_title_label.text = "选择遗物"
	_clear_container()
	# 从 pool 中排除已拥有的，随机 3 个
	var pool: Array = []
	for relic in RelicManager._pool:
		if not RelicManager.has(str(relic.get("id", ""))):
			pool.append(relic)
	pool.shuffle()
	_relic_options = pool.slice(0, min(3, pool.size()))

	for i in range(_relic_options.size()):
		var relic: Dictionary = _relic_options[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(420, 80)
		btn.text = "%s\n%s" % [str(relic.get("name", relic.get("id", "?"))), str(relic.get("desc", ""))]
		btn.pressed.connect(_on_relic_pressed.bind(i))
		_container.add_child(btn)

func _show_upgrade_phase() -> void:
	_title_label.text = "选择盘面改造"
	_clear_container()
	var pool: Array = _all_upgrades.duplicate()
	pool.shuffle()
	_upgrade_options = pool.slice(0, min(2, pool.size()))

	for i in range(_upgrade_options.size()):
		var upgrade: Dictionary = _upgrade_options[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(420, 80)
		btn.text = "%s\n%s" % [str(upgrade.get("name", "")), str(upgrade.get("desc", ""))]
		btn.pressed.connect(_on_upgrade_pressed.bind(i))
		_container.add_child(btn)

func _on_relic_pressed(index: int) -> void:
	if index >= _relic_options.size():
		return
	var relic: Dictionary = _relic_options[index]
	RelicManager.activate(str(relic.get("id", "")))
	_phase = Phase.UPGRADE
	_show_upgrade_phase()

func _on_upgrade_pressed(index: int) -> void:
	if index >= _upgrade_options.size():
		return
	RoundManager.apply_upgrade(_upgrade_options[index])
	_phase = Phase.DONE
	RoundManager.next_round()

func _clear_container() -> void:
	for child in _container.get_children():
		child.queue_free()

func _load_upgrades() -> Array:
	var f = FileAccess.open(UPGRADE_CONFIG_PATH, FileAccess.READ)
	if f == null:
		return []
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		return data.get("upgrades", [])
	return []
