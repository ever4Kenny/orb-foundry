# Codex Task: slot 移到底部，漏缝阈值跟随调整

## 问题

当前 slot y_offset=-160，slot 中心在 y=920。最后一排 peg（stagger 末行 y≈896）与 slot 顶部重叠。
需要把三个 slot 移到板子底部，漏缝死亡阈值同步调整。

## 目标

- 三个 slot 的 y_offset 从 -160 改为 **-36**（slot 中心 y=1044，贴近底部但仍在板子内可见）
- slot 宽度/高度保持 132×32 不变
- ball.gd 漏缝阈值从 980 改为 **1070**（紧贴 slot 底部以下，仍在屏幕内）

## 约束

- **只改**：`resources/board_layouts/default.json`（3 个 slot 的 y_offset）和 `scripts/ball.gd`（漏缝阈值一行）
- 其它一切不动

## 验收

```bash
cd /home/kenny/orb_foundry/godot
./Godot_v4.6-stable_linux.x86_64 --headless --quit 2>&1
# 无 ERROR
```
