# Codex Task: peg 形状布局 + 分数调整

## 问题描述

当前 peg 排列是均匀 stagger 网格（12行 × 8-9列），间距全等，太规整。
需要像 Peglin 那样用 peg 摆出不同形状：斜线、弧线、密集板块等。
同时分数目标需要随 peg 增多而提升。

## 目标

### 形状需求
板子上应该混合多种 peg 排列方式，不要全一样：
1. **斜线**：一条从左上方到右下方的对角斜线（约15-20个 peg）
2. **弧线**：一条弧形曲线（约15-20个 peg）
3. **板块**：一片密集矩形区域（约25-35个 peg，间距比网格更小）
4. **散点**：其余 peg 保持 stagger 网格作为填充

总数维持在 90-110 个 peg。

### 分数提升
- R1: 250 → 350
- R2: 400 → 550
- R3: 560 → 800

### 实现方式
可以扩展 `board.gd` 的 `generate_pegs()` 来支持从 config 读取多种 pattern，每种 pattern 有独立的位置定义（绝对坐标或公式）。

建议在 `default.json` 中增加一个 `patterns` 数组，board.gd 按 pattern 逐个生成 peg。
如果实现太复杂，可以用另一种方式：在 JSON 中定义具体的坐标偏移来实现形状。
具体方案由你决定，目标是产生视觉上明显不同的形状。

## 约束

- **可以改**：`scripts/board.gd`、`resources/board_layouts/default.json`、`resources/round_config.json`
- **不要改**：`project.godot`、所有 `.tscn`、`ball.gd`、`peg.gd`、`slot.gd`、`main.gd` 等其它所有 .gd
- peg 类型分配逻辑（bonus/danger/normal 的随机分配）保持不动
- 保持 board_width=720, board_height=1080, peg_radius=7

## 验收标准

1. 编译通过
2. JSON 语法正确
3. peg 板视觉上有明显不同的形状区域（不是均匀网格）
4. 总分目标提升
