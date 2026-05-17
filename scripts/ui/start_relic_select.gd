extends CanvasLayer

signal relic_chosen(relic_id: String)

var _options: Array = []
var _buttons: Array[Button] = []

func _ready() -> void:
	_build_panel()
	visible = false

func _process(_delta: float) -> void:
	visible = RoundManager.state == RoundManager.GameState.RELIC_SELECT

func _build_panel() -> void:
	_options = _pick_random_3()

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "选择起始遗物"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(960 - 150, 260)
	title.custom_minimum_size = Vector2(300, 40)
	add_child(title)

	var container := HBoxContainer.new()
	container.name = "CardContainer"
	container.add_theme_constant_override("separation", 24)
	# 3 cards × 200 + 2 gaps × 24 = 648; center at x=960 → left edge = 960 - 324 = 636
	container.position = Vector2(636, 320)
	add_child(container)

	for i in range(_options.size()):
		var relic: Dictionary = _options[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 280)
		btn.text = "%s\n\n%s" % [
			str(relic.get("name", relic.get("id", "?"))),
			str(relic.get("desc", ""))
		]
		btn.pressed.connect(_on_card_pressed.bind(i))
		container.add_child(btn)
		_buttons.append(btn)

func _pick_random_3() -> Array:
	var pool: Array = RelicManager._pool.duplicate()
	pool.shuffle()
	return pool.slice(0, min(3, pool.size()))

func _on_card_pressed(index: int) -> void:
	if index >= _options.size():
		return
	var relic: Dictionary = _options[index]
	var relic_id := str(relic.get("id", ""))
	RelicManager.activate(relic_id)
	relic_chosen.emit(relic_id)
	RoundManager.start_after_relic_select()
	visible = false
