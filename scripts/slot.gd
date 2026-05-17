# Slot.gd
# Area2D at bottom of board — catches balls

extends Area2D

const ABSORB_DURATION := 0.28

@export var slot_position: String = "center"  # left, center, right
@export var slot_effect: String = "score_bonus"  # score_bonus, score_multiplier, ball_recovery
@export var slot_label: String = "+50分"

var _feedback: float = 0.0
var _feedback_scale: float = 1.0
var _captured_balls: Array[Node] = []
var _feedback_scale_tween: Tween
var _feedback_fade_tween: Tween

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw() -> void:
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		for child in get_children():
			collision_shape = child as CollisionShape2D
			if collision_shape != null:
				break
	if collision_shape == null:
		return
	var col_shape = collision_shape.shape as RectangleShape2D
	if col_shape == null:
		return
	var half = col_shape.size * 0.5
	var rect := Rect2(-half, col_shape.size)
	var slot_color: Color
	match slot_effect:
		"score_bonus":
			slot_color = Color("#4488ff")
		"score_multiplier":
			slot_color = Color("#44dd44")
		"ball_recovery":
			slot_color = Color("#ffaa00")
		_:
			slot_color = Color("#666666")
	var fill_color := slot_color
	fill_color.a = 0.35
	draw_rect(rect, fill_color, true)
	draw_rect(rect, slot_color, false, 2.0)
	_draw_feedback(rect, slot_color)
	draw_string(ThemeDB.fallback_font, Vector2(-half.x, -4), slot_label, HORIZONTAL_ALIGNMENT_CENTER, col_shape.size.x, 14, Color.WHITE)

func _process(_delta: float) -> void:
	if _feedback > 0.0:
		queue_redraw()

func _on_body_entered(body: Node) -> void:
	if not body.has_method("is_alive"):
		return
	if not body.is_alive():
		return
	if body in _captured_balls:
		return
	_captured_balls.append(body)

	var base_score := 0
	match slot_effect:
		"score_bonus":
			base_score = RelicManager.get_center_slot_score(50) if slot_position == "center" else 50
			ScoreManager.add(base_score)
		"ball_bonus":
			ScoreManager.next_elasticity_boost += 0.10
		"score_multiplier":
			ScoreManager.next_score_multiplier = 1.5
		"ball_recovery":
			RoundManager.shots_left += 1

	RelicManager._dispatch("onSlotScore", {"slot_id": slot_position, "slot_tags": [slot_position], "base_score": base_score, "ball_node": body})

	_play_feedback()
	_absorb_ball(body)

func _draw_feedback(rect: Rect2, slot_color: Color) -> void:
	if _feedback <= 0.0:
		return
	var flash := slot_color
	flash.a = 0.22 * _feedback
	draw_rect(Rect2(rect.position - Vector2(120, 12), rect.size + Vector2(240, 24)), flash, true)
	var band := slot_color
	band.a = 0.12 * _feedback
	draw_rect(Rect2(Vector2(-450, rect.position.y - 10), Vector2(900, rect.size.y + 20)), band, true)
	var ring := slot_color.lightened(0.45)
	ring.a = 0.9 * _feedback
	var scaled_size := rect.size * _feedback_scale
	var scaled_rect := Rect2(-scaled_size * 0.5, scaled_size)
	draw_rect(scaled_rect, ring, false, 4.0)

func _play_feedback() -> void:
	_feedback = 1.0
	_feedback_scale = 1.0
	if is_instance_valid(_feedback_scale_tween):
		_feedback_scale_tween.kill()
	if is_instance_valid(_feedback_fade_tween):
		_feedback_fade_tween.kill()
	_feedback_scale_tween = create_tween()
	_feedback_scale_tween.tween_property(self, "_feedback_scale", 1.28, 0.08)
	_feedback_scale_tween.tween_property(self, "_feedback_scale", 1.0, 0.18)
	_feedback_fade_tween = create_tween()
	_feedback_fade_tween.tween_property(self, "_feedback", 0.0, ABSORB_DURATION)
	queue_redraw()

func _absorb_ball(body: Node) -> void:
	body.set_deferred("freeze", true)
	body.set_deferred("collision_layer", 0)
	body.set_deferred("collision_mask", 0)
	var tween := create_tween()
	tween.set_parallel()
	tween.tween_property(body, "global_position", global_position, ABSORB_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(body, "scale", Vector2.ZERO, ABSORB_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.finished.connect(_finish_absorb_ball.bind(body))

func _finish_absorb_ball(body: Node) -> void:
	_captured_balls.erase(body)
	if is_instance_valid(body) and body.has_method("die"):
		body.die()
