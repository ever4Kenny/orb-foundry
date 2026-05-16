# Codex Task: slot 奖励重新设计

## 问题

当前 3 个 slot 奖励：
- 左(elasticity_boost): +25%弹跳 → 基本没用，低弹跳击中更多peg
- 中(score_bonus): +10分 → 102个peg每碰一个就+10，进槽也是+10，太弱
- 右(ball_recovery): +1球 → OK保持

## 新设计

| slot | 效果 | 实现 |
|------|------|------|
| 左 | **×2 下一击** | 下一次发射中所有 peg 命中得分翻倍 |
| 中 | **+50分** | 直接加50分 |
| 右 | +1球 | 不变 |

## 实现细节

### 左槽 "×2 下一击"
- ScoreManager 新增 `next_score_multiplier: int = 1`
- `reset()` 时重置为 1
- slot 触发时设为 2
- ball.gd 的 `on_peg_hit()` 中对 normal/bonus 得分乘以 `ScoreManager.next_score_multiplier`
- 发射下一球后，在 main.gd 的 `_launch_selected_ball()` 中重置 multiplier 为 1
- 显示：HUD 上如果 multiplier > 1，显示 "×2 就绪"

### 中槽 "+50分"
- 改 slot_effect 的数字从 10 到 50

### 配置文件
- `default.json`: 左 slot effect 改为 "score_multiplier"，label 改为 "×2 下一击"
- `default.json`: 中 slot label 改为 "+50分"

## 约束

- **可以改**：`scripts/slot.gd`、`scripts/score_manager.gd`、`scripts/ball.gd`、`scripts/main.gd`、`scripts/ui/hud.gd`、`scenes/ui/hud.tscn`、`resources/board_layouts/default.json`
- **不要改**：其它文件不动
- 保持 slot_effect 字符串驱动，不硬编码
- HUD 不需要大改，加一个 multiplier 提示即可

## 验收

```bash
cd /home/kenny/orb_foundry/godot
./Godot_v4.6-stable_linux.x86_64 --headless --quit 2>&1
# 无 ERROR
```
