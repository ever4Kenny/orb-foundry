# RoundManager.gd
# Autoload singleton — manages round progression

extends Node

signal round_started(round_index: int, round_data: Dictionary)
signal round_ended(round_index: int, passed: bool)
signal upgrade_applied(upgrade: Dictionary)
signal game_over(won: bool, final_score: int)

enum GameState { IDLE, RELIC_SELECT, ROUND_ENTRY, PLAYING, BALL_SELECT, REWARD_SELECT, UPGRADE_SELECT, GAME_OVER }

var current_round: int = 0
var shots_left: int = 0
var upgrade_chosen = null  # upgrade config dict
var state: GameState = GameState.IDLE
var _rounds_data: Array = []

func _ready() -> void:
	_load_config()

func _load_config() -> void:
	var cfg = _load_json("res://resources/round_config.json")
	if cfg:
		_rounds_data = cfg.get("rounds", [])

func _load_json(path: String):
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	return data

func reset() -> void:
	current_round = 0
	upgrade_chosen = null
	ScoreManager.reset()
	BallBag.reset()
	RelicManager.reset()
	_load_config()
	state = GameState.RELIC_SELECT

func start_after_relic_select() -> void:
	start_round(0)

func start_round(ri: int) -> void:
	if ri >= _rounds_data.size():
		state = GameState.GAME_OVER
		game_over.emit(true, ScoreManager.get_score())
		return
	current_round = ri
	var rd = _rounds_data[ri]
	shots_left = rd.get("ball_count", 4)
	state = GameState.BALL_SELECT
	# Dispatch onRoundStart first (fills pending effects list);
	# main.gd's _on_round_started handler will apply them after board is rebuilt.
	RelicManager._dispatch("onRoundStart", {"round_index": ri, "round_data": rd})
	round_started.emit(ri, rd)

func enter_ball_select() -> void:
	if state == GameState.ROUND_ENTRY:
		state = GameState.BALL_SELECT

func use_shot() -> void:
	shots_left -= 1

func has_shots_left() -> bool:
	return shots_left > 0

func check_round_end() -> bool:
	if shots_left > 0:
		return false
	# Wait for all balls to settle — caller checks active balls
	return true

func get_target_score() -> int:
	if current_round < _rounds_data.size():
		return _rounds_data[current_round].get("target_score", 0)
	return 0

func get_round_data() -> Dictionary:
	if current_round < _rounds_data.size():
		return _rounds_data[current_round]
	return {}

func end_round() -> void:
	var passed = ScoreManager.get_score() >= get_target_score()
	round_ended.emit(current_round, passed)
	if not passed:
		state = GameState.GAME_OVER
		game_over.emit(false, ScoreManager.get_score())
		return
	if current_round == 0:
		state = GameState.REWARD_SELECT
	elif current_round == 1:
		state = GameState.UPGRADE_SELECT
	else:
		state = GameState.GAME_OVER
		game_over.emit(true, ScoreManager.get_score())

func apply_upgrade(upgrade: Dictionary) -> void:
	upgrade_chosen = upgrade
	if str(upgrade.get("type", "")) == "blast_radius":
		ScoreManager.blast_radius_multiplier = float(upgrade.get("radius_multiplier", 1.0))
	upgrade_applied.emit(upgrade)

func next_round() -> void:
	current_round += 1
	start_round(current_round)
