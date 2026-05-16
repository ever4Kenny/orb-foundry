extends CanvasLayer

@onready var round_label: Label = %RoundLabel
@onready var target_label: Label = %TargetLabel
@onready var score_label: Label = %ScoreLabel
@onready var shots_label: Label = %ShotsLabel
@onready var bag_label: Label = %BagLabel
@onready var elasticity_label: Label = %ElasticityLabel

func _ready() -> void:
	ScoreManager.score_changed.connect(_on_score_changed)
	RoundManager.round_started.connect(_on_round_started)
	BallBag.bag_changed.connect(_on_bag_changed)
	_refresh()

func _on_score_changed(_new_score: int, _delta: int) -> void:
	_refresh()

func _on_round_started(_round_index: int, _round_data: Dictionary) -> void:
	_refresh()

func _on_bag_changed(_available_balls: Array) -> void:
	_refresh()

func _process(_delta: float) -> void:
	shots_label.text = "发射次数: %d / %d" % [RoundManager.shots_left, RoundManager.get_round_data().get("ball_count", 0)]
	_update_elasticity_label()

func _refresh() -> void:
	var round_data := RoundManager.get_round_data()
	round_label.text = "轮次: %s" % str(round_data.get("name", "-"))
	target_label.text = "目标分: %d" % RoundManager.get_target_score()
	score_label.text = "当前分: %d" % ScoreManager.get_score()
	shots_label.text = "发射次数: %d / %d" % [RoundManager.shots_left, RoundManager.get_round_data().get("ball_count", 0)]
	bag_label.text = "球袋: %d 颗" % BallBag.get_available_ids().size()
	_update_elasticity_label()

func _update_elasticity_label() -> void:
	var boost_percent := int(round(ScoreManager.next_elasticity_boost * 100.0))
	if boost_percent > 0:
		elasticity_label.text = "弹性加成: +%d%%" % boost_percent
	else:
		elasticity_label.text = "弹性加成: 无"
