extends CanvasLayer

signal start_requested

var _title_label: Label
var _desc_label: Label
var _start_button: Button

func _ready() -> void:
	_build_ui()
	RoundManager.round_started.connect(_on_round_started)
	_refresh()

func _process(_delta: float) -> void:
	visible = RoundManager.state == RoundManager.GameState.ROUND_ENTRY

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(620, 320)
	panel.position = Vector2(-310, -160)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 30)
	_title_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_title_label)

	_desc_label = Label.new()
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.custom_minimum_size = Vector2(540, 120)
	_desc_label.add_theme_font_size_override("font_size", 20)
	_desc_label.add_theme_color_override("font_color", Color("#d8e3ff"))
	vbox.add_child(_desc_label)

	_start_button = Button.new()
	_start_button.text = "点击开始"
	_start_button.custom_minimum_size = Vector2(220, 54)
	_start_button.pressed.connect(_on_start_pressed)
	vbox.add_child(_start_button)

func _on_round_started(_round_index: int, _round_data: Dictionary) -> void:
	_refresh()

func _refresh() -> void:
	var round_data := RoundManager.get_round_data()
	_title_label.text = str(round_data.get("name", ""))
	_desc_label.text = str(round_data.get("mechanic_desc", ""))
	visible = RoundManager.state == RoundManager.GameState.ROUND_ENTRY

func _on_start_pressed() -> void:
	start_requested.emit()
