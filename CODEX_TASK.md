# Codex Task: 弹珠肉鸽机 — 节奏与反馈优化

## 问题描述

当前 MVP 可运行，但存在三个体验问题：

### 问题 1：球速太快，节奏不可读
- 板子高度 1080px，球从顶射到底约 1.3 秒
- 发射初速 620，物理上限 800，加上重力和反弹加速，球瞬间飞过屏幕
- 用户看不清球的轨迹和碰撞，感觉像"射出去就没了"

### 问题 2：Peg 命中零反馈
- `peg.gd` 被球撞到后立即 `hide()` + 关碰撞，视觉上一瞬间消失
- 无论 normal / bonus / danger peg 都完全一样的消失方式
- 用户无法直观感知"我撞到了什么类型的 peg"
- 反馈应该偏弱但可见（纯 UI 级，不需要音效或粒子系统）

### 问题 3：球袋（Slot）零反馈
- 球落入底部 slot 后直接 `die()`，没有任何视觉信号
- 不同 slot 类型（score_bonus / elasticity_boost / ball_recovery）也没有区分
- 这是发射的结果终点，需要有较强的视觉反馈

## 约束

- **不要改的文件**：`project.godot`、所有 `.tscn` 场景文件、`round_manager.gd`、`score_manager.gd`、`ball_bag.gd`、`hud.gd`、`ball_select.gd`、`reward_select.gd`、`upgrade_select.gd`、`game_over.gd`、`shot_result.gd`
- **可以改的文件**：`scripts/ball.gd`、`scripts/peg.gd`、`scripts/slot.gd`、`scripts/board.gd`、`scripts/main.gd`、`resources/board_layouts/default.json`
- 只使用 Godot 4.6 内置能力（Tween、_draw、AnimationPlayer），不安装插件
- 不做粒子系统（GPUParticles2D 太重）
- 不做音效
- 不要在 peg 被 pierce ball 穿过时重复触发反馈

## 验收标准

1. Godot 编译检查通过：
```bash
cd /home/kenny/orb_foundry/godot
./Godot_v4.6-stable_linux.x86_64 --headless --quit 2>&1
# 输出不应包含 ERROR: 行
```

2. 球的节奏：球从顶部发射到底部，肉眼可追踪轨迹，不会"瞬移消失"

3. Peg 命中：球撞到 peg 时，能看出一个短暂的视觉变化（哪怕只是缩放闪烁），且 bonus/danger/normal 三种 peg 的反馈有视觉区分

4. Slot 命中：球落入 slot 时有明显反馈（如屏幕短暂闪色、slot 区域高亮、球被"吸收"的缩放动画等），比 peg 反馈更强
