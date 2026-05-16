extends CanvasLayer

const UPGRADE_CONFIG_PATH := "res://resources/upgrade_config.json"

var upgrades: Array = []

func _ready() -> void:
	upgrades = _load_upgrades()
	_build_panel()
	visible = false
	_refresh_visibility()

func _process(_delta: float) -> void:
	_refresh_visibility()

func _load_upgrades() -> Array:
	var file := FileAccess.open(UPGRADE_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open: " + UPGRADE_CONFIG_PATH)
		return []
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		return data.get("upgrades", [])
	return []

func _build_panel() -> void:
	var panel := VBoxContainer.new()
	panel.position = Vector2(880, 240)
	panel.custom_minimum_size = Vector2(420, 260)
	add_child(panel)

	var title := Label.new()
	title.text = "选择盘面改造"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	for i in range(upgrades.size()):
		var upgrade: Dictionary = upgrades[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(420, 86)
		button.text = "%s\n%s" % [str(upgrade.get("name", "")), str(upgrade.get("desc", ""))]
		button.pressed.connect(_on_upgrade_pressed.bind(i))
		panel.add_child(button)

func _refresh_visibility() -> void:
	visible = RoundManager.state == RoundManager.GameState.UPGRADE_SELECT

func _on_upgrade_pressed(index: int) -> void:
	if index >= upgrades.size():
		return
	var upgrade: Dictionary = upgrades[index]
	RoundManager.apply_upgrade(upgrade)
	RoundManager.next_round()
	visible = false
