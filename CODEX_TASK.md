# Codex Task: 球漏缝负向反馈

## 问题描述

当前球的死亡路径有三类：
1. 进球袋 → slot 吸收动画（好）
2. 超时/卡住 → 灰色消散（中性）
3. 从 slot 之间缝隙漏下去（y > 1100，没碰到任何 slot）→ 也是灰色消散

第 3 种情况应该给负向反馈，让用户明确感知"球漏掉了"。与灰色消散区分开。

板子底部有三个 slot：left(0.15) / center(0.50) / right(0.85)，宽度各 132px。
球从缝隙漏下去时，应该看到类似"球碎掉/红色消失"的负向效果，持续 0.25-0.35 秒。

## 约束

- **不要改的文件**：`project.godot`、所有 `.tscn`、`slot.gd`、`peg.gd`、`board.gd`、`hud.gd`、`ball_select.gd`、`reward_select.gd`、`upgrade_select.gd`、`round_manager.gd`、`score_manager.gd`、`main.gd`
- **只改**：`scripts/ball.gd`
- slot 捕获路径走 `die()` 保持不动
- 超时/卡住保持现有灰色消散（`_die_naturally`）
- 漏缝（y > 1100）需要一个新的、与消散不同的负向反馈动画
- 只用 Tween + `_draw`
- 不做粒子

## 验收标准

1. 编译通过：
```bash
cd /home/kenny/orb_foundry/godot
./Godot_v4.6-stable_linux.x86_64 --headless --quit 2>&1
# 无 ERROR 行
```

2. 球从 slot 缝隙漏下去时能看到与"灰色消散"不同的负向视觉（如红色碎裂、红色闪烁消失等）
3. slot 捕获和超时/卡住的行为不受影响
