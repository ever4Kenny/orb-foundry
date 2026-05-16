extends Node2D

const BOARD_SCENE := preload("res://scenes/board.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const BALL_SELECT_SCENE := preload("res://scenes/ui/ball_select.tscn")
const REWARD_SELECT_SCENE := preload("res://scenes/ui/reward_select.tscn")
const UPGRADE_SELECT_SCENE := preload("res://scenes/ui/upgrade_select.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/game_over.tscn")
const SHOT_RESULT_SCENE := preload("res://scenes/ui/shot_result.tscn")
const BALL_SCENE := preload("res://scenes/ball.tscn")
const BALL_CONFIG_PATH := "res://resources/ball_config.json"
const LAUNCH_SPEED := 420.0

var board: Node2D
var selected_ball_id := ""
var drag_start := Vector2.ZERO
var ball_lookup: Dictionary = {}

# Shot tracking (includes split children)
var _shot_balls: Array[Node] = []
var _shot_score_start: int = 0
var _shot_peg_hits: int = 0
var _shot_feedback_showing: bool = false
var _shot_result: CanvasLayer = null

func _ready() -> void:
	ball_lookup = _load_ball_lookup()
	RoundManager.reset()
	board = BOARD_SCENE.instantiate()
	board.position = Vector2(120, 0)
	add_child(board)

	var hud := HUD_SCENE.instantiate()
	add_child(hud)

	var ball_select := BALL_SELECT_SCENE.instantiate()
	ball_select.ball_selected.connect(_on_ball_selected)
	add_child(ball_select)

	var reward_select := REWARD_SELECT_SCENE.instantiate()
	add_child(reward_select)

	var upgrade_select := UPGRADE_SELECT_SCENE.instantiate()
	add_child(upgrade_select)

	var game_over := GAME_OVER_SCENE.instantiate()
	add_child(game_over)

	_shot_result = SHOT_RESULT_SCENE.instantiate()
	_shot_result.dismissed.connect(_on_shot_feedback_dismissed)
	add_child(_shot_result)

func _unhandled_input(event: InputEvent) -> void:
	if _shot_feedback_showing:
		return
	if selected_ball_id.is_empty():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.position.y < 260:
			drag_start = event.position
		elif not event.pressed and drag_start != Vector2.ZERO:
			_launch_selected_ball(event.position)
			drag_start = Vector2.ZERO

func _process(_delta: float) -> void:
	# Keep only alive balls
	var alive_balls: Array[Node] = []
	for ball in _shot_balls:
		if is_instance_valid(ball) and ball.has_method("is_alive") and ball.is_alive():
			alive_balls.append(ball)
	_shot_balls = alive_balls

	if _shot_feedback_showing:
		return

	# Wait for all balls (including split children) to settle
	if not _shot_balls.is_empty():
		return

	if RoundManager.state == RoundManager.GameState.PLAYING:
		if not selected_ball_id.is_empty():
			return  # ball selected but not launched yet — wait
		# All balls from this shot settled — show feedback
		_show_shot_feedback()

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

func _on_ball_selected(ball_id: String) -> void:
	selected_ball_id = ball_id

func _launch_selected_ball(release_position: Vector2) -> void:
	var cfg: Dictionary = ball_lookup.get(selected_ball_id, {})
	if cfg.is_empty():
		selected_ball_id = ""
		RoundManager.state = RoundManager.GameState.BALL_SELECT
		return

	# Reset per-shot tracking
	_shot_score_start = ScoreManager.get_score()
	_shot_peg_hits = 0
	_shot_balls.clear()
	_shot_feedback_showing = false

	var ball := BALL_SCENE.instantiate()
	_apply_ball_config(ball, cfg)
	if ScoreManager.next_elasticity_boost > 0.0:
		ball.bounce_value += ScoreManager.next_elasticity_boost
		ScoreManager.next_elasticity_boost = 0.0
	ball.position = board.to_local(drag_start)

	# Track split children and accumulate peg hits on death
	ball.split_created.connect(_on_split_created)
	ball.tree_exiting.connect(_on_ball_exiting.bind(ball))
	_shot_balls.append(ball)

	board.add_child(ball)

	var direction := release_position - drag_start
	if direction.length() < 20.0:
		direction = Vector2(0, 1)
	ball.launch(direction.normalized() * LAUNCH_SPEED)
	RoundManager.use_shot()
	selected_ball_id = ""
	RoundManager.state = RoundManager.GameState.PLAYING

func _on_split_created(child: RigidBody2D) -> void:
	child.split_created.connect(_on_split_created)  # chain in case of nested splits
	child.tree_exiting.connect(_on_ball_exiting.bind(child))
	_shot_balls.append(child)

func _on_ball_exiting(ball: Node) -> void:
	_shot_peg_hits += ball.col_count

func _show_shot_feedback() -> void:
	_shot_feedback_showing = true
	var score_gained := ScoreManager.get_score() - _shot_score_start
	_shot_result.show_result(_shot_peg_hits, score_gained)

func _on_shot_feedback_dismissed() -> void:
	_shot_feedback_showing = false
	_shot_result.reset()

	# Continue round logic
	if RoundManager.state == RoundManager.GameState.PLAYING and RoundManager.check_round_end():
		RoundManager.end_round()
	elif RoundManager.state == RoundManager.GameState.PLAYING and RoundManager.has_shots_left():
		RoundManager.state = RoundManager.GameState.BALL_SELECT

func _apply_ball_config(ball: Node, cfg: Dictionary) -> void:
	ball.ball_id = str(cfg.get("id", "iron"))
	ball.ball_radius = float(cfg.get("radius", 20.0))
	ball.bounce_value = float(cfg.get("bounce", 0.6))
	ball.weight_value = float(cfg.get("weight", 1.0))
	# Godot 4.x: JSON Array -> Array[String]
	var raw_tags: Array = cfg.get("tags", [])
	var typed_tags: Array[String] = []
	for tag in raw_tags:
		typed_tags.append(str(tag))
	ball.ball_tags = typed_tags
	ball.color = Color.from_string(str(cfg.get("color", "#666666")), Color.GRAY)

	match str(cfg.get("effect", "none")):
		"pierce":
			ball.ball_effect = ball.BallEffect.PIERCE
		"magnet":
			ball.ball_effect = ball.BallEffect.MAGNET
			ball.magnet_target_tag = str(cfg.get("magnet_target_tag", "metal"))
			ball.magnet_range = float(cfg.get("magnet_range", 200.0))
			ball.magnet_force = float(cfg.get("magnet_force", 300.0))
		"split":
			ball.ball_effect = ball.BallEffect.SPLIT
			ball.split_threshold = int(cfg.get("split_threshold", 6))
			ball.split_radius = float(cfg.get("split_radius", 12.0))
		_:
			ball.ball_effect = ball.BallEffect.NONE
