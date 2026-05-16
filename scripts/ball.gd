# Ball.gd
# RigidBody2D ball with 4 type behaviors

class_name Ball
extends RigidBody2D

signal split_created(child: RigidBody2D)

enum BallEffect { NONE, PIERCE, MAGNET, SPLIT }
enum DeathVisual { NATURAL, GAP }

const GRAVITY_SCALE := 0.55
const MAX_SPEED := 560.0
const NATURAL_DEATH_DURATION := 0.3
const GAP_DEATH_DURATION := 0.3

@export var ball_id: String = "iron"
@export var ball_radius: float = 20.0
@export var ball_effect: int = BallEffect.NONE
@export var ball_tags: Array[String] = []
@export var bounce_value: float = 0.6
@export var weight_value: float = 1.0
@export var split_threshold: int = 6
@export var magnet_target_tag: String = "metal"
@export var magnet_range: float = 200.0
@export var magnet_force: float = 300.0
@export var color: Color = Color.WHITE
@export var col_count: int = 0
@export var split_radius: float = 12.0
@export var score_multiplier: int = 1

var _alive: bool = true
var _dying: bool = false
var _death_progress: float = 0.0:
	set(value):
		_death_progress = value
		queue_redraw()
var _lifetime: float = 0.0
var _stuck_timer: float = 0.0
var _pierced_pegs: Array = []  # pegs already pierced (don't re-score)
var _magnet_target_pos: Vector2 = Vector2.ZERO
var _death_tween: Tween = null
var _death_visual: int = DeathVisual.NATURAL

# Cache for ball config
static var _ball_config_cache: Dictionary = {}

func _ready() -> void:
	_setup_physics()
	_setup_collision()
	_setup_visual()

func _setup_physics() -> void:
	mass = weight_value
	var mat = PhysicsMaterial.new()
	mat.bounce = bounce_value
	mat.friction = 0.0
	physics_material_override = mat
	gravity_scale = GRAVITY_SCALE

func _setup_collision() -> void:
	# Ball is on layer 1, collides with layers 2 (peg) and 3 (wall)
	collision_layer = 1
	collision_mask = 2 | 4 | 8  # peg, wall, slot

	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)
	var shape := col.shape as CircleShape2D
	if shape == null:
		shape = CircleShape2D.new()
		col.shape = shape
	shape.radius = ball_radius

func _setup_visual() -> void:
	queue_redraw()

func _draw() -> void:
	if not _alive:
		return
	if _dying and _death_visual == DeathVisual.GAP:
		_draw_gap_death()
		return
	var visual_radius := ball_radius * lerpf(1.0, 0.2, _death_progress)
	var visual_color := color.darkened(_death_progress * 0.65)
	visual_color.a *= lerpf(1.0, 0.25, _death_progress)
	draw_circle(Vector2.ZERO, visual_radius, visual_color)
	draw_arc(Vector2.ZERO, visual_radius, 0, TAU, 16, Color.BLACK, 1.0)
	
	# Show collision count for glass ball
	if not _dying and ball_effect == BallEffect.SPLIT and split_threshold < 900:
		draw_string(ThemeDB.fallback_font, Vector2(-4, 4), str(col_count), HORIZONTAL_ALIGNMENT_CENTER, -1, 8)

	if not _dying and ball_effect == BallEffect.MAGNET and _magnet_target_pos != Vector2.ZERO:
		var local_target := to_local(_magnet_target_pos)
		var target_dir := local_target.normalized()
		if target_dir != Vector2.ZERO:
			var magnet_color := color
			magnet_color.a = 0.6
			draw_line(Vector2.ZERO, target_dir * ball_radius * 2.5, magnet_color, 3.0)
			var ring_color := color
			ring_color.a = 0.3
			var ring_radius := magnet_range * 0.3
			for i in range(8):
				var start_angle := TAU * float(i) / 8.0
				var end_angle := start_angle + TAU / 16.0
				draw_arc(Vector2.ZERO, ring_radius, start_angle, end_angle, 8, ring_color, 1.5)

func _draw_gap_death() -> void:
	var fade := 1.0 - _death_progress
	var core_radius := ball_radius * lerpf(1.0, 0.15, _death_progress)
	var core_color := Color(1.0, 0.12, 0.08, 0.9 * fade)
	draw_circle(Vector2.ZERO, core_radius, core_color)
	
	var flash_color := Color(1.0, 0.35, 0.1, 0.55 * fade)
	draw_arc(Vector2.ZERO, ball_radius * lerpf(1.1, 1.9, _death_progress), 0, TAU, 20, flash_color, 2.0)
	
	for i in range(7):
		var angle := TAU * float(i) / 7.0 + 0.25
		var dir := Vector2(cos(angle), sin(angle))
		var side := Vector2(-dir.y, dir.x)
		var center := dir * ball_radius * lerpf(0.25, 1.55, _death_progress)
		var shard_size := ball_radius * lerpf(0.35, 0.12, _death_progress)
		var shard_color := Color(1.0, 0.05 + float(i % 2) * 0.12, 0.04, 0.8 * fade)
		draw_polygon([
			center + dir * shard_size,
			center - dir * shard_size * 0.55 + side * shard_size * 0.45,
			center - dir * shard_size * 0.45 - side * shard_size * 0.35,
		], [shard_color])

func _physics_process(delta: float) -> void:
	if not _alive or _dying:
		return
	
	_lifetime += delta
	
	# Magnet effect
	if ball_effect == BallEffect.MAGNET:
		_apply_magnetic_force(delta)
	
	# Speed cap
	var sp = linear_velocity.length()
	if sp > MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED
	
	# General stuck detection: nearly stopped for > 1.5s anywhere
	if sp < 10.0:
		_stuck_timer += delta
		if _stuck_timer > 1.5:
			_die_naturally()
			return
	else:
		_stuck_timer = 0.0
	
	# Stuck prevention: slow & near bottom
	if sp < 20.0 and position.y > 900 and _lifetime > 2.0:
		_die_naturally()
		return
	
	# Fallen below slots — gap death (slots end at y≈1060, threshold before viewport bottom)
	if position.y > 1070:
		_die_through_gap()
		return
	
	# Board edge bounce (board is 720×1080, ball in board-local coords)
	if position.x - ball_radius < 0:
		position.x = ball_radius
		linear_velocity.x = abs(linear_velocity.x) * 0.5
	if position.x + ball_radius > 720:
		position.x = 720 - ball_radius
		linear_velocity.x = -abs(linear_velocity.x) * 0.5
	if position.y - ball_radius < 30:
		position.y = 30 + ball_radius
		linear_velocity.y = abs(linear_velocity.y) * 0.5

func on_peg_hit(peg_type: String, peg_tags: Array, peg_node: Node) -> bool:
	if not _alive:
		return false
	
	match ball_effect:
		BallEffect.PIERCE:
			return _handle_pierce(peg_type, peg_tags, peg_node)
		_:
			return _handle_normal_hit(peg_type, peg_tags)

func _handle_pierce(peg_type: String, peg_tags: Array, peg_node: Node) -> bool:
	# Don't re-score already pierced pegs
	if peg_node in _pierced_pegs:
		return false
	_pierced_pegs.append(peg_node)
	
	match peg_type:
		"bonus":
			ScoreManager.add(25 * score_multiplier)
		"normal":
			ScoreManager.add(10 * score_multiplier)
		"danger":
			ScoreManager.add(-5)
			linear_velocity *= 0.7
	
	col_count += 1
	return true

func _handle_normal_hit(peg_type: String, peg_tags: Array) -> bool:
	col_count += 1
	
	match peg_type:
		"bonus":
			ScoreManager.add(25 * score_multiplier)
		"normal":
			ScoreManager.add(10 * score_multiplier)
		"danger":
			ScoreManager.add(-5)
			linear_velocity *= 0.8
	
	# Glass split
	if ball_effect == BallEffect.SPLIT and col_count >= split_threshold and ball_radius > 10:
		_split()
		return false
	
	return true

func _apply_magnetic_force(delta: float) -> void:
	var nearest_peg = null
	var nearest_dist = magnet_range
	
	var pegs = get_tree().get_nodes_in_group("pegs")
	for peg in pegs:
		if not peg.alive:
			continue
		if not magnet_target_tag in peg.peg_tags:
			continue
		var dist = position.distance_to(peg.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_peg = peg
	
	if nearest_peg:
		_magnet_target_pos = nearest_peg.global_position
		var dir = (nearest_peg.position - position).normalized()
		apply_central_force(dir * magnet_force * delta * 60.0)
	else:
		_magnet_target_pos = Vector2.ZERO
	queue_redraw()

func _split() -> void:
	var sp = linear_velocity.length() * 0.8
	var angle = randf() * TAU
	for i in range(2):
		var child_ball = _create_split_ball(angle + i * PI, sp)
		split_created.emit(child_ball)
		get_parent().add_child(child_ball)
	die()

func _create_split_ball(angle: float, speed: float) -> RigidBody2D:
	var child = (load("res://scripts/ball.gd") as Script).new()
	child.ball_id = "glass"
	child.ball_radius = split_radius
	child.ball_effect = BallEffect.NONE
	child.bounce_value = bounce_value
	child.weight_value = weight_value
	child.color = color
	child.score_multiplier = score_multiplier
	child.split_threshold = 999  # don't split again
	child.col_count = 0
	child.position = position
	child.linear_velocity = Vector2(cos(angle), sin(angle)) * speed
	child._setup_collision()
	return child

func die() -> void:
	if is_instance_valid(_death_tween):
		_death_tween.kill()
	_alive = false
	# Signal parent to remove
	if has_signal("tree_exiting"):
		queue_free()
	else:
		hide()
		set_collision_layer_value(1, false)

func _die_naturally() -> void:
	_start_death_animation(NATURAL_DEATH_DURATION, DeathVisual.NATURAL)

func _die_through_gap() -> void:
	_start_death_animation(GAP_DEATH_DURATION, DeathVisual.GAP)

func _start_death_animation(duration: float, death_visual: int) -> void:
	if _dying:
		return
	_dying = true
	_death_visual = death_visual
	_death_progress = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	freeze = true
	collision_layer = 0
	collision_mask = 0
	_death_tween = create_tween()
	_death_tween.tween_property(self, "_death_progress", 1.0, duration)
	_death_tween.finished.connect(die)

func launch(velocity: Vector2) -> void:
	linear_velocity = velocity
	_alive = true
	_dying = false
	_death_progress = 0.0

func is_alive() -> bool:
	return _alive

# Static helper to create ball from config
static func create_from_config(config: Dictionary) -> RigidBody2D:
	var ball = (load("res://scripts/ball.gd") as Script).new()
	ball.ball_id = config.get("id", "iron")
	ball.ball_radius = config.get("radius", 20.0)
	ball.bounce_value = config.get("bounce", 0.6)
	ball.weight_value = config.get("weight", 1.0)
	var raw_tags: Array = config.get("tags", [])
	var typed_tags: Array[String] = []
	for tag in raw_tags:
		typed_tags.append(str(tag))
	ball.ball_tags = typed_tags
	ball.color = Color.from_string(str(config.get("color", "#666666")), Color.GRAY)
	
	var effect = config.get("effect", "none")
	match effect:
		"pierce":
			ball.ball_effect = BallEffect.PIERCE
		"magnet":
			ball.ball_effect = BallEffect.MAGNET
			ball.magnet_target_tag = config.get("magnet_target_tag", "metal")
			ball.magnet_range = config.get("magnet_range", 200.0)
			ball.magnet_force = config.get("magnet_force", 300.0)
		"split":
			ball.ball_effect = BallEffect.SPLIT
			ball.split_threshold = config.get("split_threshold", 6)
			ball.split_radius = config.get("split_radius", 12)
	
	return ball
