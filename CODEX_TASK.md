# Codex Task: 球自然出局负向反馈

## 问题描述

球没进球袋就死了（超时/卡住/掉出屏幕）时，目前直接 `die()` 瞬间消失，零反馈。
球袋捕获的球有吸收动画，但自然死亡的球也应该有视觉收尾。

需要给球自然死亡加一个简单的"消散"动画：球缩小变暗，持续约 0.3 秒后真正死亡。

## 约束

- **不要改的文件**：`project.godot`、所有 `.tscn`、`slot.gd`、`peg.gd`、`board.gd`、`hud.gd`、`ball_select.gd`、`reward_select.gd`、`upgrade_select.gd`、`round_manager.gd`、`score_manager.gd`
- **可以改的文件**：`scripts/ball.gd`、`scripts/main.gd`
- 球袋捕获的球走 `slot.gd` 的吸收路径（不要改），自然死亡的球才走新的消散动画
- 消散要简短（0.25-0.35 秒），不需要很强，弱于 slot 反馈
- 只用 Tween + _draw，不做粒子

## 验收标准

1. 编译通过：
```bash
cd /home/kenny/orb_foundry/godot
./Godot_v4.6-stable_linux.x86_64 --headless --quit 2>&1
# 无 ERROR 行
```

2. 球自然死亡时能看到缩小变暗再消失，不是瞬间消失
3. 球进球袋的吸收动画不受影响
