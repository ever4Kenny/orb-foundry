# post_round1_select.gd
# 第 1 关后：球三选一 → 改造二选一（顺序双选）
extends CanvasLayer

enum Phase { BALL, UPGRADE, DONE }

const BALL_CONFIG_PATH := "res://resources/ball_config.json"
const UPGRADE_CONFIG_PATH := "res://resources/upgrade_config.json"

var _phase: Phase = Phase.BALL
var _ball_options: Array = []
var _upgrade_options: Array = []
var _ball_lookup: Dictionary = {}
var _all_upgrades: Array = []

var _title_label: Label
var _container: VBoxContainer
var _bg: ColorRect

func _ready() -> void:
	_ball_lookup = _load_ball_lookup()
	_all_upgrades = _load_upgrades()
	_build_ui()
	visible = false

func _process(_delta: float) -> void:
	var should_show := RoundManager.state == RoundManager.GameState.POST_ROUND1_SELECT
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
	_phase = Phase.BALL
	_show_ball_phase()

func _show_ball_phase() -> void:
	_title_label.text = "扩充球袋 — 选一颗加入球袋"
	_clear_container()
	var cfg = _load_json(BALL_CONFIG_PATH)
	var reward_balls: Array = []
	if cfg is Dictionary:
		var ucfg = _load_json(UPGRADE_CONFIG_PATH)
		if ucfg is Dictionary:
			reward_balls = ucfg.get("reward_balls", [])
	# 随机 3 个不重复
	var pool: Array = reward_balls.duplicate()
	pool.shuffle()
	_ball_options = pool.slice(0, min(3, pool.size()))

	for i in range(_ball_options.size()):
		var ball_id: String = str(_ball_options[i])
		var cfg_ball: Dictionary = _ball_lookup.get(ball_id, {})
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(420, 80)
		btn.text = "%s  %s\n%s" % ["●", str(cfg_ball.get("name", ball_id)), str(cfg_ball.get("desc", ""))]
		btn.modulate = Color.from_string(str(cfg_ball.get("color", "#ffffff")), Color.WHITE)
		btn.pressed.connect(_on_ball_pressed.bind(i))
		_container.add_child(btn)

func _show_upgrade_phase() -> void:
	_title_label.text = "选择盘面改造"
	_clear_container()
	# 随机 2 个不重复
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

func _on_ball_pressed(index: int) -> void:
	if index >= _ball_options.size():
		return
	BallBag.add_ball(str(_ball_options[index]))
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

func _load_ball_lookup() -> Dictionary:
	var file := FileAccess.open(BALL_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	var lookup := {}
	if data is Dictionary:
		for ball in data.get("balls", []):
			if ball is Dictionary:
				lookup[str(ball.get("id", ""))] = ball
	return lookup

func _load_upgrades() -> Array:
	var cfg = _load_json(UPGRADE_CONFIG_PATH)
	if cfg is Dictionary:
		return cfg.get("upgrades", [])
	return []

func _load_json(path: String):
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	return data
