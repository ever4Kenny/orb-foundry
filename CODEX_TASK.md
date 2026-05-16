# Codex Task: ×1.5 倍率 + 第1关连续击中玩法

## 问题

### 1. 倍率过高
×2 太高，改成 ×1.5。需要将 multiplier 从 int 改为 float。

### 2. 第1关需要"连续击中"玩法
第1关独特机制：连续击中普通(normal) peg 时，连击次数越多额外加分越多。
- 每连续击中 normal peg 超过 1 个后，额外加分 = (连击数 - 1) × 5 分
- 击中 bonus 或 danger peg 时连击中断（先结算当前连击加分，再重置）
- 球死亡时结算当前连击
- 结算面板（shot_result）显示：最大连击次数 + 连击额外总分

## 实现要点

### ×1.5 修改
- `score_manager.gd`: `next_score_multiplier` 改为 `float = 1.0`
- `ball.gd`: `score_multiplier` 改为 `float = 1.0`，得分计算用 `int(10 * score_multiplier)` 等
- `slot.gd`: `next_score_multiplier = 2` → `= 1.5`
- `hud.gd`: multiplier_label 显示 "×1.5 就绪"（用 `%.1f` 格式化）
- 数值修正：25*1.5=37.5→38, 10*1.5=15

### 连续击中（Combo）
- `ball.gd`:
  - 新增 `_consecutive_normal: int = 0`
  - 新增 `_max_consecutive_normal: int = 0`
  - 新增 `_combo_bonus_total: int = 0`
  - normal peg 命中时 `_consecutive_normal += 1`，更新 max
  - bonus/danger peg 命中时先结算 combo（`combo_bonus = max(0, _consecutive_normal - 1) * 5`），再重置为 0
  - ball 死亡时（tree_exiting）结算最终 combo
- `main.gd`:
  - ball tree_exiting 时收集 combo 数据
  - 传递 combo_max 和 combo_bonus 给 shot_result
- `shot_result.gd` + `shot_result.tscn`:
  - 新增 combo 显示行："最大连击: X (连击加分: +Y)"
  - 只在 combo_max > 1 时显示

### Round 配置
- `round_config.json`: 第1轮增加 `"mechanic": "combo"` 字段
- `round_manager.gd` 或 `main.gd` 根据当前轮 mechanic 决定是否启用 combo

## 约束

- **可以改**：`scripts/ball.gd`、`scripts/main.gd`、`scripts/slot.gd`、`scripts/score_manager.gd`、`scripts/ui/hud.gd`、`scripts/ui/shot_result.gd`、`scenes/ui/shot_result.tscn`、`scenes/ui/hud.tscn`、`resources/round_config.json`
- **不要改**：其它文件不动
- combo 仅在 round_data.mechanic == "combo" 时启用
- shot_result 的 combo 行在非 combo 回合不显示

## 验收

```bash
cd /home/kenny/orb_foundry/godot
./Godot_v4.6-stable_linux.x86_64 --headless --quit 2>&1
# 无 ERROR
```
