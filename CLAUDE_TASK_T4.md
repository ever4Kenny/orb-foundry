# T4 — 起始 Relic 三选一 UI

## 背景
流程改为开局即选 relic（第 1 关前出现三选一界面）。没有这个入口，R1 修复无法端到端验收。

## 当前流程
```
main._ready() → RoundManager.reset() → start_round(0) → ROUND_ENTRY → 玩家点击 → BALL_SELECT → ...
```

## 目标流程
```
main._ready() → 显示 StartRelicSelect（三选一）→ 玩家选中 → RelicManager.activate(id) → RoundManager.reset() → start_round(0) �� ...
```

## 任务

### 1. 新增 GameState

`godot/scripts/round_manager.gd`：
- `GameState` 枚举新增 `RELIC_SELECT`（放在 `IDLE` 后面）
- `reset()` 里不再直接调 `start_round(0)`，改为：
  ```gdscript
  state = GameState.RELIC_SELECT
  ```
- 新增方法：
  ```gdscript
  func start_after_relic_select() -> void:
      start_round(0)
  ```

### 2. 新增 StartRelicSelect 场景

新建 `godot/scenes/ui/start_relic_select.tscn`（CanvasLayer）+ `godot/scripts/ui/start_relic_select.gd`

**逻辑**：
- 从 `RelicManager._pool` 中无重复随机抽 3 个（pool 有 6 个，不会不够）
- 全屏覆盖，3 张卡片横排居中（每张卡 200×280，间距 24）
- 每张卡显示：relic name + desc
- 点击任一卡片 → `RelicManager.activate(relic_id)` → 发出 `relic_chosen` 信号 → 隐藏自身

**参考 `reward_select.gd` 的模式**：
- `_ready()` 构建 UI，`visible = false`
- `_process()` 里 `_refresh_visibility()`：当 `RoundManager.state == GameState.RELIC_SELECT` 时 visible
- 选中后调用 `RoundManager.start_after_relic_select()`

**脚本骨架**：
```gdscript
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
    var container := HBoxContainer.new()
    container.name = "CardContainer"
    container.alignment = BoxContainer.ALIGNMENT_CENTER
    # 居中定位
    container.anchors_preset = Control.PRESET_CENTER
    container.position = Vector2(540 - 324, 400)  # 粗略居中 (3*200 + 2*24)/2
    add_child(container)

    var title := Label.new()
    title.text = "选择起始遗物"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.position = Vector2(540 - 100, 300)
    add_child(title)

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
```

### 3. main.gd 集成

`godot/scripts/main.gd`：
- 顶部新增 `const START_RELIC_SELECT_SCENE := preload("res://scenes/ui/start_relic_select.tscn")`
- `_ready()` 里实例化并 add_child（放在 round_entry 之前）
- **关键**：把 `RoundManager.reset()` 的调用时机保持不变（它现在只设 state=RELIC_SELECT，不再自动 start_round）

### 4. 确保 board 在 RELIC_SELECT 阶段不生成 pegs

当前 `RoundManager.reset()` 不再调 `start_round(0)`，所以 `round_started` 信号不会触发，board 不会 `reset_pegs_for_round()`。但 `board._ready()` 里的 `generate_pegs()` 仍会执行（用 round 0 的数据）。

这没问题——board 初始化时就生成 pegs，等玩家选完 relic 后 `start_round(0)` 触发 `round_started` → board `reset_pegs_for_round()` 重新生成 → `pegs_ready` → flush R1 pending ops。流程自洽。

## 验收命令

```bash
cd /home/kenny/orb_foundry/godot

# 1. 启动无报错
./Godot_v4.6-stable_linux.x86_64 --headless --quit-after 3 2>&1 | grep -iE "error|script"

# 2. R1 端到端（开局选中 R1 → 第 1 关 board 少 peg）
# 手动测试：启动游戏 → 三选一界面出现 → 选含 R1 的卡 → 进入第 1 关 → 控制台输出 "R1: removed"
```

## 验收标准
1. 游戏启动后首先出现三选一界面（3 张卡横排），不直接进入 Round Entry
2. 点选任一卡片后，HUD 的 RelicBar 显示该 relic 名称
3. 选中 R1 后进入第 1 关，控制台输出 `R1: removed danger peg at ... normal peg at ...`（非 `(none)`）
4. 无 GDScript 报错

## 不要改
- `relic_config.json` 的内容
- `board.gd` 的 peg 生成算法
- `reward_select.gd`（关后奖励选择，阶段 3 再改）
- `upgrade_select.gd`
