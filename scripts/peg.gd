# Peg.gd
# Attached to each peg StaticBody2D in the board

extends StaticBody2D

@export var peg_type: String = "normal"
@export var peg_tags: Array[String] = ["normal"]
@export var peg_radius: float = 12.0
@export var alive: bool = true

var _color_normal: Color = Color("#666666")
var _color_bonus: Color = Color("#ffaa00")
var _color_danger: Color = Color("#cc3333")
var _hit_feedback: float = 0.0
var _hit_scale: float = 1.0
var _remove_after_feedback: bool = false
var _hit_scale_tween: Tween
var _hit_fade_tween: Tween

func _ready() -> void:
	_setup_collision()
	_setup_visual()

func _setup_collision() -> void:
	collision_layer = 2
	collision_mask = 1

	var shape = CircleShape2D.new()
	shape.radius = peg_radius
	var col = CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	var sensor := Area2D.new()
	sensor.name = "HitSensor"
	sensor.collision_layer = 0
	sensor.collision_mask = 1
	var sensor_col := CollisionShape2D.new()
	sensor_col.shape = shape
	sensor.add_child(sensor_col)
	sensor.body_entered.connect(_on_body_entered)
	add_child(sensor)
	
func _setup_visual() -> void:
	queue_redraw()

func _draw() -> void:
	if not alive and _hit_feedback <= 0.0:
		return
	var radius := peg_radius * _hit_scale
	match peg_type:
		"normal":
			draw_circle(Vector2.ZERO, radius, _color_normal)
			draw_arc(Vector2.ZERO, radius, 0, TAU, 16, Color("#444444"), 1.0)
		"bonus":
			var pulse = sin(Time.get_ticks_msec() / 300.0) * 0.3 + 0.7
			draw_circle(Vector2.ZERO, radius, _color_bonus * pulse)
			draw_arc(Vector2.ZERO, radius, 0, TAU, 16, Color("#cc8800"), 1.5)
		"danger":
			draw_circle(Vector2.ZERO, radius, _color_danger)
			draw_arc(Vector2.ZERO, radius, 0, TAU, 16, Color("#992222"), 1.0)
	_draw_hit_feedback(radius)

func _process(_delta: float) -> void:
	if (peg_type == "bonus" and alive) or _hit_feedback > 0.0:
		queue_redraw()  # pulse animation

func _on_body_entered(body: Node) -> void:
	if not alive:
		return
	if not body.has_method("on_peg_hit"):
		return
	
	var hit_result = body.on_peg_hit(peg_type, peg_tags, self)
	if hit_result:
		if peg_type != "danger":
			alive = false
			collision_layer = 0
		_play_hit_feedback(peg_type != "danger")

func _draw_hit_feedback(radius: float) -> void:
	if _hit_feedback <= 0.0:
		return
	match peg_type:
		"bonus":
			var flash := Color("#fff2a8")
			flash.a = 0.65 * _hit_feedback
			draw_circle(Vector2.ZERO, radius * 1.15, flash)
			draw_arc(Vector2.ZERO, radius * 1.55, 0, TAU, 24, flash, 3.0)
		"danger":
			var flash := Color("#ff4444")
			flash.a = 0.8 * _hit_feedback
			draw_arc(Vector2.ZERO, radius * 1.45, 0, TAU, 24, flash, 3.0)
			var slash := radius * 0.9
			draw_line(Vector2(-slash, -slash), Vector2(slash, slash), flash, 3.0)
			draw_line(Vector2(-slash, slash), Vector2(slash, -slash), flash, 3.0)
		_:
			var flash := Color.WHITE
			flash.a = 0.5 * _hit_feedback
			draw_arc(Vector2.ZERO, radius * 1.45, 0, TAU, 24, flash, 2.0)

func _play_hit_feedback(remove_after_feedback: bool) -> void:
	_remove_after_feedback = remove_after_feedback
	_hit_feedback = 1.0
	_hit_scale = 1.0
	if is_instance_valid(_hit_scale_tween):
		_hit_scale_tween.kill()
	if is_instance_valid(_hit_fade_tween):
		_hit_fade_tween.kill()
	_hit_scale_tween = create_tween()
	_hit_scale_tween.tween_property(self, "_hit_scale", 1.35, 0.07)
	_hit_scale_tween.tween_property(self, "_hit_scale", 1.0, 0.15)
	_hit_fade_tween = create_tween()
	_hit_fade_tween.tween_property(self, "_hit_feedback", 0.0, 0.22)
	_hit_fade_tween.finished.connect(_on_hit_feedback_finished)
	queue_redraw()

func _on_hit_feedback_finished() -> void:
	_hit_feedback = 0.0
	_hit_scale = 1.0
	if _remove_after_feedback:
		hide()
	queue_redraw()

func die() -> void:
	alive = false
	hide()
	collision_layer = 0

func reset_peg() -> void:
	alive = true
	_hit_feedback = 0.0
	_hit_scale = 1.0
	_remove_after_feedback = false
	show()
	collision_layer = 2
