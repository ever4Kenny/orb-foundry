extends CanvasLayer

const BALL_CONFIG_PATH := "res://resources/ball_config.json"
const UPGRADE_CONFIG_PATH := "res://resources/upgrade_config.json"

var reward_balls: Array = []
var ball_lookup: Dictionary = {}
var option_buttons: Array[Button] = []

func _ready() -> void:
	ball_lookup = _load_ball_lookup()
	reward_balls = _load_reward_balls()
	_build_panel()
	visible = false
	_refresh_visibility()

func _process(_delta: float) -> void:
	_refresh_visibility()

func _load_ball_lookup() -> Dictionary:
	var file := FileAccess.open(BALL_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open: " + BALL_CONFIG_PATH)
		return {}
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	var lookup := {}
	if data is Dictionary:
		for ball in data.get("balls", []):
			if ball is Dictionary:
				lookup[str(ball.get("id", ""))] = ball
	return lookup

func _load_reward_balls() -> Array:
	var file := FileAccess.open(UPGRADE_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open: " + UPGRADE_CONFIG_PATH)
		return []
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		return data.get("reward_balls", [])
	return []

func _build_panel() -> void:
	var panel := VBoxContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(750, 540)
	panel.custom_minimum_size = Vector2(420, 320)
	add_child(panel)

	var title := Label.new()
	title.text = "扩充球袋 — 选一颗加入球袋"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	for i in range(reward_balls.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(420, 86)
		button.pressed.connect(_on_option_pressed.bind(i))
		panel.add_child(button)
		option_buttons.append(button)
		_set_button_text(button, str(reward_balls[i]))

func _set_button_text(button: Button, ball_id: String) -> void:
	var cfg: Dictionary = ball_lookup.get(ball_id, {})
	button.text = "%s  %s\n%s" % [
		"●",
		str(cfg.get("name", ball_id)),
		str(cfg.get("desc", ""))
	]
	button.modulate = Color.from_string(str(cfg.get("color", "#ffffff")), Color.WHITE)

func _refresh_visibility() -> void:
	visible = RoundManager.state == RoundManager.GameState.REWARD_SELECT

func _on_option_pressed(index: int) -> void:
	if index >= reward_balls.size():
		return
	BallBag.add_ball(str(reward_balls[index]))
	RoundManager.next_round()
	visible = false
