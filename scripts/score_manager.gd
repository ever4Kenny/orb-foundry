# ScoreManager.gd
# Autoload singleton — tracks score across rounds

extends Node

signal score_changed(new_score: int, delta: int)

var score: int = 0
var next_elasticity_boost: float = 0.0
var next_score_multiplier: int = 1

func reset() -> void:
	score = 0
	next_elasticity_boost = 0.0
	next_score_multiplier = 1
	score_changed.emit(score, 0)

func add(delta: int) -> void:
	score += delta
	score_changed.emit(score, delta)

func get_score() -> int:
	return score
