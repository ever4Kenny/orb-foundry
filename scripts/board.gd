extends Node2D

signal pegs_ready

const LAYOUT_PATH := "res://resources/board_layouts/default.json"
const PEG_SCRIPT := preload("res://scripts/peg.gd")
const SLOT_SCRIPT := preload("res://scripts/slot.gd")

var layout: Dictionary = {}
var peg_nodes: Array[Node] = []
var slot_nodes: Array[Node] = []
var _blood_bonus_pending: bool = false
var _blood_bonus_value: int = 0
var _blood_danger_nodes: Array[Node] = []

func _ready() -> void:
	randomize()
	layout = _load_json(LAYOUT_PATH)
	RoundManager.round_started.connect(_on_round_started)
	RoundManager.upgrade_applied.connect(_on_upgrade_applied)
	queue_redraw()
	generate_pegs()
	generate_slots()

func _draw() -> void:
	var board_width: float = layout.get("board_width", 720.0)
	var board_height: float = layout.get("board_height", 1080.0)
	var border_color := Color("#d8e3ff")
	border_color.a = 0.85
	draw_rect(Rect2(Vector2.ZERO, Vector2(board_width, board_height)), border_color, false, 4.0)

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open: " + path)
		return {}
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		return data
	return {}

func generate_pegs() -> void:
	var peg_radius: float = layout.get("peg_radius", 12.0)
	var peg_positions := _get_peg_positions()
	var round_data := RoundManager.get_round_data()
	var bonus_left: int = round_data.get("bonus_peg_count", 0)
	var danger_left: int = round_data.get("danger_peg_count", 0)
	var total_pegs := peg_positions.size()

	var special_indices: Array[int] = []
	for i in range(total_pegs):
		special_indices.append(i)
	special_indices.shuffle()

	var bonus_indices := special_indices.slice(0, min(bonus_left, special_indices.size()))
	var danger_start: int = bonus_indices.size()
	var danger_indices := special_indices.slice(danger_start, min(danger_start + danger_left, special_indices.size()))
	var peg_index := 0

	for position in peg_positions:
		var peg := StaticBody2D.new()
		peg.name = "Peg"
		peg.set_script(PEG_SCRIPT)
		peg.position = position
		var peg_type := _pick_peg_type(peg_index, bonus_indices, danger_indices)
		peg.set("peg_radius", peg_radius)
		peg.set("peg_type", peg_type)
		peg.set("peg_tags", _get_peg_tags(peg_type))
		peg.add_to_group("pegs")
		add_child(peg)
		peg_nodes.append(peg)
		peg_index += 1
	pegs_ready.emit()

func _get_peg_positions() -> Array[Vector2]:
	var patterns: Array = layout.get("patterns", [])
	if patterns.is_empty():
		return _get_grid_peg_positions()

	var positions: Array[Vector2] = []
	for pattern in patterns:
		if not pattern is Dictionary:
			continue
		match str(pattern.get("type", "")):
			"line":
				positions.append_array(_get_line_positions(pattern))
			"arc":
				positions.append_array(_get_arc_positions(pattern))
			"block":
				positions.append_array(_get_block_positions(pattern))
			"stagger":
				positions.append_array(_get_stagger_positions(pattern))
	return positions

func _get_grid_peg_positions() -> Array[Vector2]:
	var board_width: float = layout.get("board_width", 720.0)
	var board_height: float = layout.get("board_height", 1080.0)
	var row_ratios: Array = layout.get("peg_rows", [])
	var row_cols: Array = layout.get("peg_cols", [])
	var positions: Array[Vector2] = []

	for row in range(min(row_ratios.size(), row_cols.size())):
		var count := int(row_cols[row])
		var y := board_height * float(row_ratios[row])
		var spacing := board_width / float(count + 1)
		var stagger := 0.0
		if row % 2 == 1:
			stagger = spacing * 0.12

		for col in range(count):
			positions.append(Vector2(spacing * float(col + 1) + stagger, y))
	return positions

func _get_line_positions(pattern: Dictionary) -> Array[Vector2]:
	var count := int(pattern.get("count", 0))
	var start := _pattern_point(pattern.get("start", [0.0, 0.0]))
	var end := _pattern_point(pattern.get("end", [0.0, 0.0]))
	var positions: Array[Vector2] = []

	if count <= 1:
		if count == 1:
			positions.append(start)
		return positions

	for i in range(count):
		positions.append(start.lerp(end, float(i) / float(count - 1)))
	return positions

func _get_arc_positions(pattern: Dictionary) -> Array[Vector2]:
	var count := int(pattern.get("count", 0))
	var center := _pattern_point(pattern.get("center", [0.5, 0.5]))
	var radius := float(pattern.get("radius", 100.0))
	var start_degrees := float(pattern.get("start_degrees", 0.0))
	var end_degrees := float(pattern.get("end_degrees", 180.0))
	var positions: Array[Vector2] = []

	if count <= 1:
		if count == 1:
			positions.append(center + Vector2.RIGHT * radius)
		return positions

	for i in range(count):
		var t := float(i) / float(count - 1)
		var radians := deg_to_rad(lerpf(start_degrees, end_degrees, t))
		positions.append(center + Vector2(cos(radians), sin(radians)) * radius)
	return positions

func _get_block_positions(pattern: Dictionary) -> Array[Vector2]:
	var rows := int(pattern.get("rows", 0))
	var cols := int(pattern.get("cols", 0))
	var start := _pattern_point(pattern.get("start", [0.0, 0.0]))
	var spacing_data: Array = pattern.get("spacing", [32.0, 32.0])
	var spacing := Vector2(float(spacing_data[0]), float(spacing_data[1]))
	var positions: Array[Vector2] = []

	for row in range(rows):
		for col in range(cols):
			positions.append(start + Vector2(spacing.x * float(col), spacing.y * float(row)))
	return positions

func _get_stagger_positions(pattern: Dictionary) -> Array[Vector2]:
	var board_width: float = layout.get("board_width", 720.0)
	var board_height: float = layout.get("board_height", 1080.0)
	var row_ratios: Array = pattern.get("rows", [])
	var row_cols: Array = pattern.get("cols", [])
	var x_min := board_width * float(pattern.get("x_min_ratio", 0.0))
	var x_max := board_width * float(pattern.get("x_max_ratio", 1.0))
	var positions: Array[Vector2] = []

	for row in range(min(row_ratios.size(), row_cols.size())):
		var count := int(row_cols[row])
		var y := board_height * float(row_ratios[row])
		var spacing := (x_max - x_min) / float(count + 1)
		var stagger := 0.0
		if row % 2 == 1:
			stagger = spacing * 0.18

		for col in range(count):
			positions.append(Vector2(x_min + spacing * float(col + 1) + stagger, y))
	return positions

func _pattern_point(point_data: Variant) -> Vector2:
	var board_width: float = layout.get("board_width", 720.0)
	var board_height: float = layout.get("board_height", 1080.0)
	if not point_data is Array or point_data.size() < 2:
		return Vector2.ZERO
	return Vector2(board_width * float(point_data[0]), board_height * float(point_data[1]))

func _create_peg(position: Vector2, peg_type: String) -> Node:
	var peg := StaticBody2D.new()
	peg.name = "Peg"
	peg.set_script(PEG_SCRIPT)
	peg.position = position
	peg.set("peg_radius", float(layout.get("peg_radius", 12.0)))
	peg.set("peg_type", peg_type)
	peg.set("peg_tags", _get_peg_tags(peg_type))
	peg.add_to_group("pegs")
	add_child(peg)
	peg_nodes.append(peg)
	return peg

func _pick_peg_type(index: int, bonus_indices: Array, danger_indices: Array) -> String:
	if index in bonus_indices:
		return "bonus"
	if index in danger_indices:
		return "danger"
	return "normal"

func _get_peg_tags(peg_type: String) -> Array[String]:
	var peg_types: Dictionary = layout.get("peg_types", {})
	var data: Dictionary = peg_types.get(peg_type, {})
	var tags: Array[String] = []
	for tag in data.get("tags", [peg_type]):
		tags.append(str(tag))
	return tags

func generate_slots() -> void:
	var board_width: float = layout.get("board_width", 720.0)
	var board_height: float = layout.get("board_height", 1080.0)
	var slots: Array = layout.get("slots", [])

	for slot_data in slots:
		if not slot_data is Dictionary:
			continue
		var slot := Area2D.new()
		slot.name = "Slot"
		slot.set_script(SLOT_SCRIPT)
		slot.position = Vector2(
			board_width * float(slot_data.get("x_ratio", 0.5)),
			board_height + float(slot_data.get("y_offset", -28.0))
		)
		slot.collision_layer = 8
		slot.collision_mask = 1
		# Add collision shape
		var shape := RectangleShape2D.new()
		shape.size = Vector2(
			float(slot_data.get("width", 56)),
			float(slot_data.get("height", 18))
		)
		var col := CollisionShape2D.new()
		col.shape = shape
		slot.add_child(col)
		slot.set("slot_position", str(slot_data.get("position", "center")))
		slot.set("slot_effect", str(slot_data.get("effect", "score_bonus")))
		slot.set("slot_label", str(slot_data.get("label", "")))
		add_child(slot)
		slot_nodes.append(slot)

func clear_board() -> void:
	reset_pegs_for_round()

func reset_pegs_for_round() -> void:
	for peg in peg_nodes:
		if is_instance_valid(peg):
			peg.queue_free()
	peg_nodes.clear()
	generate_pegs()
	for upgrade in RoundManager.upgrades_chosen:
		_on_upgrade_applied(upgrade)

func get_peg_count() -> int:
	var count := 0
	for peg in peg_nodes:
		if is_instance_valid(peg) and peg.alive:
			count += 1
	return count

func _on_upgrade_applied(upgrade: Dictionary) -> void:
	match str(upgrade.get("type", "")):
		"add_pegs":
			_add_upgrade_pegs(upgrade)
		"remove_pegs":
			_remove_upgrade_pegs(upgrade)
		"add_pegs_pattern":
			_add_pegs_pattern(upgrade)
		"remove_pegs_pattern":
			_remove_pegs_pattern(upgrade)
		"blood_board":
			_apply_blood_board(upgrade)
		"mirror_walls":
			ScoreManager.wall_elasticity = float(upgrade.get("elasticity", 1.0))
		# other types: no peg change needed

func _on_round_started(_round_index: int, _round_data: Dictionary) -> void:
	reset_pegs_for_round()

func _add_upgrade_pegs(upgrade: Dictionary) -> void:
	var count := int(upgrade.get("count", 0))
	var peg_type := str(upgrade.get("peg_type", "bonus"))
	var board_width: float = layout.get("board_width", 720.0)
	var board_height: float = layout.get("board_height", 1080.0)
	var positions := [
		Vector2(board_width * 0.42, board_height * 0.43),
		Vector2(board_width * 0.58, board_height * 0.43),
		Vector2(board_width * 0.45, board_height * 0.50),
		Vector2(board_width * 0.55, board_height * 0.50)
	]

	for i in range(min(count, positions.size())):
		_create_peg(positions[i], peg_type)

func _remove_upgrade_pegs(upgrade: Dictionary) -> void:
	var target_type := str(upgrade.get("peg_type", "danger"))
	var also_remove_type := str(upgrade.get("also_remove", ""))
	var removed_count := _remove_pegs_by_type(target_type, -1)
	if not also_remove_type.is_empty():
		_remove_pegs_by_type(also_remove_type, removed_count)

func _remove_pegs_by_type(peg_type: String, max_count: int) -> int:
	var removed := 0
	for peg in peg_nodes:
		if max_count >= 0 and removed >= max_count:
			break
		if not is_instance_valid(peg) or not peg.alive:
			continue
		if str(peg.get("peg_type")) != peg_type:
			continue
		peg.die()
		removed += 1
	return removed

# B3: 中心漏斗 — 9 个 bonus peg 在中下部 V 形排列
func _add_pegs_pattern(upgrade: Dictionary) -> void:
	var peg_type := str(upgrade.get("peg_type", "bonus"))
	var board_width: float = layout.get("board_width", 720.0)
	var board_height: float = layout.get("board_height", 1080.0)
	var positions: Array[Vector2] = [
		Vector2(board_width * 0.30, board_height * 0.62),
		Vector2(board_width * 0.70, board_height * 0.62),
		Vector2(board_width * 0.35, board_height * 0.68),
		Vector2(board_width * 0.65, board_height * 0.68),
		Vector2(board_width * 0.40, board_height * 0.74),
		Vector2(board_width * 0.60, board_height * 0.74),
		Vector2(board_width * 0.44, board_height * 0.80),
		Vector2(board_width * 0.56, board_height * 0.80),
		Vector2(board_width * 0.50, board_height * 0.84),
	]
	for pos in positions:
		_create_peg(pos, peg_type)

# B4: 双子通道 — 移除中部垂直走廊约 6 个 peg
func _remove_pegs_pattern(upgrade: Dictionary) -> void:
	var count := int(upgrade.get("count", 6))
	var board_width: float = layout.get("board_width", 720.0)
	var board_height: float = layout.get("board_height", 1080.0)
	var cx := board_width * 0.50
	var corridor_half := board_width * 0.08
	var removed := 0
	for peg in peg_nodes:
		if removed >= count:
			break
		if not is_instance_valid(peg) or not peg.alive:
			continue
		var px: float = peg.position.x
		var py: float = peg.position.y
		if abs(px - cx) < corridor_half and py > board_height * 0.40 and py < board_height * 0.80:
			peg.die()
			removed += 1

func _process(_delta: float) -> void:
	if not _blood_bonus_pending:
		return
	for peg in _blood_danger_nodes:
		if is_instance_valid(peg) and peg.get("alive"):
			return
	_blood_bonus_pending = false
	ScoreManager.add(_blood_bonus_value)

# B6: 血色盘面 — danger peg 数量翻倍（重新生成时由 round_config 控制，此处直接在现有盘面追加）
func _apply_blood_board(upgrade: Dictionary) -> void:
	var factor := int(upgrade.get("danger_multiply", 2))
	var board_width: float = layout.get("board_width", 720.0)
	var board_height: float = layout.get("board_height", 1080.0)
	# 收集现有 danger peg 位置，在附近偏移处新增
	var danger_positions: Array[Vector2] = []
	for peg in peg_nodes:
		if is_instance_valid(peg) and peg.alive and str(peg.get("peg_type")) == "danger":
			danger_positions.append(peg.position)
	var offset_dirs: Array[Vector2] = [Vector2(28, 0), Vector2(-28, 0), Vector2(0, 28)]
	var added := 0
	var target := danger_positions.size() * (factor - 1)
	for base_pos in danger_positions:
		if added >= target:
			break
		for dir in offset_dirs:
			if added >= target:
				break
			var new_pos := base_pos + dir
			if new_pos.x > 20 and new_pos.x < board_width - 20 and new_pos.y > 20 and new_pos.y < board_height - 60:
				_create_peg(new_pos, "danger")
				added += 1
	# Register clear_bonus trigger
	_blood_danger_nodes.clear()
	for peg in peg_nodes:
		if is_instance_valid(peg) and str(peg.get("peg_type")) == "danger":
			_blood_danger_nodes.append(peg)
	_blood_bonus_value = int(upgrade.get("clear_bonus", 50))
	_blood_bonus_pending = true
