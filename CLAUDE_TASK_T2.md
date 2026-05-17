# T2 — 6 个 Relic Effect 实现 + 已激活栏 UI（含 R1 时序修复）

## 背景
当前 `relic_manager.gd` 已有队列骨架（`_pending_round_start_effects`），但 R1 在第 1 关开局时 board 尚未 build pegs，导致 flush 时找不到 peg 节点，删除静默失效。

## 任务

### 1. R1 时序修复

**问题根因**：`main.gd` 的 `_on_round_started` 在 `round_started` 信号触发后立即调用 `apply_pending_round_start_effects(board)`，但此时 `board._on_round_started` 还没执行（或刚开始执行 `reset_pegs_for_round()`），pegs 尚未生成完毕。

**修法**：在 `board.gd` 的 `generate_pegs()` 末尾发出 `pegs_ready` 信号，`main.gd` 监听该信号后再 flush。

**改动清单**：

`godot/scripts/board.gd`：
- 在文件顶部添加 `signal pegs_ready`
- `generate_pegs()` 末尾添加 `pegs_ready.emit()`

`godot/scripts/main.gd`：
- `_ready()` 里 board 实例化后，连接 `board.pegs_ready.connect(_on_pegs_ready)`
- 删除 `_on_round_started` 里的 `RelicManager.apply_pending_round_start_effects(board)` 调用
- 新增方法：
  ```gdscript
  func _on_pegs_ready() -> void:
      RelicManager.apply_pending_round_start_effects(board)
  ```

`godot/scripts/relic_manager.gd`：
- `apply_pending_round_start_effects` 里，`_pending_round_start_effects.clear()` 前加 `consumed_rounds` 幂等保护：
  - 在 `_pending_round_start_effects` 的每个 entry 里存入 `round_index`（由 `_dispatch` 传入 payload 的 `round_index`）
  - flush 时检查 entry 的 `round_index` 是否等于 `RoundManager.current_round`，不等则跳过（防止重复消费）

### 2. 6 个 Relic Effect 实现

当前 `relic_config.json` 里已有 6 个 relic 定义（R1–R6）。需要确认并补全以下 effect 逻辑：

| ID | trigger | effect.type | 实现位置 | 状态 |
|----|---------|-------------|----------|------|
| R1 | onRoundStart | remove_pegs | relic_manager._apply_remove_pegs | 已有，修时序 |
| R2 | onPegHit (tag: bonus) | score_bonus | relic_manager._dispatch → ScoreManager.add | 已有 |
| R3 | query | ball_draw_count | relic_manager.get_ball_draw_count | 已有 |
| R4 | onBallLaunched | glass_split_threshold | relic_manager._dispatch → ball_node.split_threshold | 已有 |
| R5 | query | score_override (center slot) | relic_manager.get_center_slot_score | 已有 |
| R6 | onBallLaunched | magnet_range_mul | relic_manager._dispatch → ball_node.magnet_range | 已有 |

**检查并补全**：
- 确认 `relic_config.json` 里 R1–R6 的 trigger/effect 字段与上表一致，缺失的补上
- R3 的 `ball_draw_count` 需在 `ball_select.gd` 里调用 `RelicManager.get_ball_draw_count()` 替换硬编码的 `3`（如果还没做）
- R4/R6 的 `onBallLaunched` trigger：在 `main.gd` 的 `_launch_selected_ball` 里，ball 实例化后、`board.add_child(ball)` 前，调用：
  ```gdscript
  RelicManager._dispatch("onBallLaunched", {"ball_node": ball})
  ```
  （如果还没做）

### 3. 已激活 Relic 栏 UI

在 HUD 左侧或底部显示当前已激活的 relic 列表（图标 + 名称）。

**实现**：
- 在 `godot/scenes/ui/hud.tscn` 里添加一个 `VBoxContainer`（或 `HBoxContainer`），命名 `RelicBar`
- `hud.gd` 里：
  - `_ready()` 连接 `RelicManager.relic_activated`
  - 收到信号后，在 `RelicBar` 里 append 一个 `Label`，文字为 `relic.get("name", relic.get("id", "?"))`
- 样式：字号 14，白色，背景半透明黑色 Panel 即可，不需要图标

## 验收命令

```bash
cd /home/kenny/orb_foundry/godot
# 1. R1 时序验证（headless 跑 3 秒，检查日志有 "R1: removed" 且无报错）
ORB_DEBUG_ACTIVATE_ALL=1 ./Godot_v4.6-stable_linux.x86_64 --headless --quit-after 3 2>&1 | grep -E "R1:|ERROR|error"

# 2. 无脚本错误
./Godot_v4.6-stable_linux.x86_64 --headless --quit-after 2 2>&1 | grep -i "error\|script"
```

## 验收标准
1. `ORB_DEBUG_ACTIVATE_ALL=1` 启动后，控制台出现 `R1: removed danger peg at ... normal peg at ...`，且不是 `(none)`
2. 无 GDScript 报错
3. HUD 左侧可见已激活 relic 名称列表

## 不要改
- `round_manager.gd` 的 `start_round` 逻辑
- `board.gd` 的 peg 生成算法
- 任何场景文件的节点树结构（只允许在现有节点下 add_child）
