# ScoreManager.gd
# Autoload singleton — tracks score across rounds

extends Node

signal score_changed(new_score: int, delta: int)

var score: int = 0
var next_elasticity_boost: float = 0.0
var next_score_multiplier: float = 1.0
var next_round_score_multiplier: float = 1.0
var round_score_multiplier: float = 1.0
var blast_radius_multiplier: float = 1.0
var wall_elasticity: float = 0.5

func reset() -> void:
	score = 0
	next_elasticity_boost = 0.0
	next_score_multiplier = 1.0
	next_round_score_multiplier = 1.0
	round_score_multiplier = 1.0
	blast_radius_multiplier = 1.0
	wall_elasticity = 0.5
	score_changed.emit(score, 0)

func apply_round_multiplier() -> void:
	round_score_multiplier = next_round_score_multiplier
	next_round_score_multiplier = 1.0

func add(delta: int) -> void:
	var effective := int(float(delta) * round_score_multiplier)
	score += effective
	score_changed.emit(score, effective)

func get_score() -> int:
	return score
