extends CanvasLayer

@onready var round_label: Label = %RoundLabel
@onready var target_label: Label = %TargetLabel
@onready var score_label: Label = %ScoreLabel
@onready var shots_label: Label = %ShotsLabel
@onready var bag_label: Label = %BagLabel
@onready var multiplier_label: Label = %MultiplierLabel

# Stage 2: active relic bar (top-left)
var _relic_bar: HBoxContainer
const RELIC_EMOJI := {
	"R1": "🔥", "R2": "💎", "R3": "🎒", "R4": "🧊", "R5": "⚖️", "R6": "🧲"
}

func _ready() -> void:
	ScoreManager.score_changed.connect(_on_score_changed)
	RoundManager.round_started.connect(_on_round_started)
	BallBag.bag_changed.connect(_on_bag_changed)
	_build_relic_bar()
	RelicManager.relic_activated.connect(_on_relic_activated)
	_rebuild_relic_bar_from_active()
	_refresh()

func _build_relic_bar() -> void:
	_relic_bar = HBoxContainer.new()
	_relic_bar.name = "RelicBar"
	_relic_bar.position = Vector2(40, 30)
	_relic_bar.add_theme_constant_override("separation", 12)
	add_child(_relic_bar)

func _on_relic_activated(relic: Dictionary) -> void:
	_append_relic_card(relic)

func _rebuild_relic_bar_from_active() -> void:
	if _relic_bar == null:
		return
	for child in _relic_bar.get_children():
		child.queue_free()
	for relic in RelicManager.active_relics:
		_append_relic_card(relic)

func _append_relic_card(relic: Dictionary) -> void:
	if _relic_bar == null:
		return
	var rid := str(relic.get("id", ""))
	var card := PanelContainer.new()
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	card.add_child(hb)
	var icon := Label.new()
	icon.text = str(RELIC_EMOJI.get(rid, "✦"))
	icon.add_theme_font_size_override("font_size", 18)
	hb.add_child(icon)
	var name_label := Label.new()
	name_label.text = str(relic.get("name", rid))
	name_label.add_theme_font_size_override("font_size", 14)
	hb.add_child(name_label)
	_relic_bar.add_child(card)

func _on_score_changed(_new_score: int, _delta: int) -> void:
	_refresh()

func _on_round_started(_round_index: int, _round_data: Dictionary) -> void:
	_refresh()

func _on_bag_changed(_available_balls: Array) -> void:
	_refresh()

func _process(_delta: float) -> void:
	shots_label.text = "发射次数: %d / %d" % [RoundManager.shots_left, RoundManager.get_round_data().get("ball_count", 0)]
	_update_multiplier_label()

func _refresh() -> void:
	var round_data := RoundManager.get_round_data()
	round_label.text = "轮次: %s" % str(round_data.get("name", "-"))
	target_label.text = "目标分: %d" % RoundManager.get_target_score()
	score_label.text = "当前分: %d" % ScoreManager.get_score()
	shots_label.text = "发射次数: %d / %d" % [RoundManager.shots_left, RoundManager.get_round_data().get("ball_count", 0)]
	bag_label.text = "球袋: %d 颗" % BallBag.get_available_ids().size()
	_update_multiplier_label()

func _update_multiplier_label() -> void:
	if ScoreManager.next_score_multiplier > 1:
		multiplier_label.text = "×%.1f 就绪" % ScoreManager.next_score_multiplier
	else:
		multiplier_label.text = ""
