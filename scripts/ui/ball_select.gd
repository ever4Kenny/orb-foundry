extends CanvasLayer

signal ball_selected(ball_id: String)

const BALL_CONFIG_PATH := "res://resources/ball_config.json"

var ball_lookup: Dictionary = {}
var option_buttons: Array[Button] = []
var drawn_entries: Array = []
var bag_label: Label
var _option_panel: Node
var _reroll_button: Button

func _ready() -> void:
	ball_lookup = _load_ball_lookup()
	_build_panel()
	visible = false
	BallBag.bag_changed.connect(_on_bag_changed)
	_refresh_bag_label(BallBag.get_available_ids())
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

func _build_panel() -> void:
	var panel := VBoxContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(1180, 440)
	panel.custom_minimum_size = Vector2(420, 360)
	add_child(panel)

	var title := Label.new()
	title.text = "选择弹珠"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	bag_label = Label.new()
	bag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(bag_label)

	# Stage 2: button count is dynamic; managed by _ensure_buttons() inside _draw_options
	_option_panel = panel

	# T6: reroll button
	var reroll_btn := Button.new()
	reroll_btn.name = "RerollBtn"
	reroll_btn.custom_minimum_size = Vector2(420, 48)
	reroll_btn.pressed.connect(_on_reroll_pressed)
	panel.add_child(reroll_btn)
	_reroll_button = reroll_btn
	_refresh_reroll_button()

func _ensure_buttons(n: int) -> void:
	# Grow
	while option_buttons.size() < n:
		var button := Button.new()
		button.custom_minimum_size = Vector2(420, 88)
		var idx := option_buttons.size()
		button.pressed.connect(_on_option_pressed.bind(idx))
		_option_panel.add_child(button)
		option_buttons.append(button)
	# Shrink: just hide extras (keep node to avoid signal reconnect)
	for i in range(option_buttons.size()):
		option_buttons[i].visible = i < n

var _was_visible: bool = false

func _refresh_visibility() -> void:
	var should_show := RoundManager.state == RoundManager.GameState.BALL_SELECT and RoundManager.has_shots_left()
	if should_show and not _was_visible:
		_draw_options()
	_was_visible = should_show
	visible = should_show

func _draw_options() -> void:
	drawn_entries = BallBag.get_all_available()
	# Stage 2: R3 额外弹仓 — query relic-modified draw count and ensure buttons exist
	var draw_count: int = RelicManager.get_ball_draw_count() if RelicManager.has_method("get_ball_draw_count") else 3
	var visible_n: int = min(draw_count, drawn_entries.size())
	_ensure_buttons(draw_count)
	for i in range(option_buttons.size()):
		var button := option_buttons[i]
		if i >= visible_n:
			button.visible = false
			continue
		button.visible = true
		var ball_id := str(drawn_entries[i].get("id", ""))
		var cfg: Dictionary = ball_lookup.get(ball_id, {})
		button.text = "%s  %s\n%s" % [
			"●",
			str(cfg.get("name", ball_id)),
			str(cfg.get("desc", ""))
		]
		button.modulate = Color.from_string(str(cfg.get("color", "#ffffff")), Color.WHITE)
		button.disabled = false

func _on_bag_changed(available_balls: Array) -> void:
	_refresh_bag_label(available_balls)
	if visible:
		_draw_options()

func _refresh_bag_label(available_balls: Array) -> void:
	if bag_label == null:
		return
	var markers: Array[String] = []
	for _id in available_balls:
		markers.append("●")
	for i in range(max(0, BallBag.get_total_count() - available_balls.size())):
		markers.append("○")
	bag_label.text = "球袋: %d 颗 %s" % [available_balls.size(), "".join(markers)]

func _on_option_pressed(index: int) -> void:
	if index >= drawn_entries.size():
		return
	var ball_id := str(drawn_entries[index].get("id", ""))
	if BallBag.use_ball(ball_id):
		RoundManager.state = RoundManager.GameState.PLAYING
		visible = false
		ball_selected.emit(ball_id)
	else:
		push_error("Failed to use ball: " + ball_id)
		_draw_options()

func _on_reroll_pressed() -> void:
	if BallBag.reroll():
		_draw_options()
		_refresh_reroll_button()

func _refresh_reroll_button() -> void:
	if _reroll_button == null:
		return
	var n := BallBag.reroll_remaining
	_reroll_button.text = "重投候选（剩余 %d 次）" % n
	_reroll_button.disabled = n <= 0
