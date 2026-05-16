extends CanvasLayer

var title_label: Label
var score_label: Label

func _ready() -> void:
	_build_panel()
	visible = false
	RoundManager.game_over.connect(_on_game_over)

func _build_panel() -> void:
	var panel := VBoxContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(880, 400)
	panel.custom_minimum_size = Vector2(420, 240)
	add_child(panel)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title_label)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(score_label)

	var replay_button := Button.new()
	replay_button.custom_minimum_size = Vector2(420, 76)
	replay_button.text = "再来一局"
	replay_button.pressed.connect(_on_replay_pressed)
	panel.add_child(replay_button)

func _on_game_over(won: bool, final_score: int) -> void:
	title_label.text = "通关" if won else "失败"
	score_label.text = "最终得分: %d" % final_score
	visible = true

func _on_replay_pressed() -> void:
	get_tree().reload_current_scene()
