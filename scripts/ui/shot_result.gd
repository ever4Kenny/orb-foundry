# ShotResult.gd
# 全屏反馈 — Roundguard 风格，显示本轮命中数和得分
extends CanvasLayer

signal dismissed

var _peg_hits_label: Label
var _score_label: Label
var _click_label: Label
var _timer: Timer
var _dismissed: bool = false

func _ready() -> void:
	_build_ui()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _build_ui() -> void:
	# 暗色全屏背景
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.0, 0.0, 0.0, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	bg.gui_input.connect(_on_bg_input)

	# 中心面板
	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(360, 220)
	panel.position = Vector2(-180, -110)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# 标题
	var title := Label.new()
	title.name = "Title"
	title.text = "本轮结果"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	vbox.add_child(_spacer(12))

	# 命中数
	_peg_hits_label = Label.new()
	_peg_hits_label.name = "PegHits"
	_peg_hits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_peg_hits_label.add_theme_font_size_override("font_size", 22)
	_peg_hits_label.add_theme_color_override("font_color", Color("#ffcc44"))
	vbox.add_child(_peg_hits_label)

	vbox.add_child(_spacer(4))

	# 得分
	_score_label = Label.new()
	_score_label.name = "Score"
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.add_theme_color_override("font_color", Color("#44ff44"))
	vbox.add_child(_score_label)

	vbox.add_child(_spacer(16))

	# 点击继续提示
	_click_label = Label.new()
	_click_label.name = "ClickHint"
	_click_label.text = "点击任意位置继续"
	_click_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_click_label.add_theme_font_size_override("font_size", 14)
	_click_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	vbox.add_child(_click_label)

	# 自动消失计时器
	_timer = Timer.new()
	_timer.name = "AutoDismiss"
	_timer.one_shot = true
	_timer.wait_time = 2.5
	_timer.timeout.connect(_dismiss)
	add_child(_timer)

func _spacer(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c

func show_result(peg_hits: int, score_gained: int) -> void:
	if _dismissed:
		return
	_peg_hits_label.text = "命中: %d 个钉子" % peg_hits
	_score_label.text = "得分: %+d" % score_gained
	visible = true
	_timer.start()

func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_dismiss()

func _dismiss() -> void:
	if _dismissed:
		return
	_dismissed = true
	_timer.stop()
	visible = false
	dismissed.emit()

func reset() -> void:
	_dismissed = false
