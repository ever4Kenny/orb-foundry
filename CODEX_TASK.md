# Codex Task: 修复漏缝反馈不可见

## 问题

`ball.gd` 漏缝检测用 `position.y > 1100`，但板子高度 1080。
球到 y>1100 时已在屏幕之外，`_draw_gap_death()` 的红色碎裂效果完全不可见。

Root cause: 检测阈值（1100）超出可视区域，死亡动画画了但用户看不见。

## 修复

将阈值从 1100 改为略低于板子底部但还在可见范围的数值。
Slot 底部在 y≈952（1080-160+32），所以阈值放到 y > 980 即可。
既确保球已越过 slot 区，又保证碎裂动画在屏幕内可见。

## 约束

- **只改** `scripts/ball.gd` 第 167 行的一个数字：1100 → 980
- 其它一切不动

## 验收

```bash
cd /home/kenny/orb_foundry/godot
./Godot_v4.6-stable_linux.x86_64 --headless --quit 2>&1
# 无 ERROR 行
```
