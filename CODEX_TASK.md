# Codex Task: 密集 peg 板 + 缩小 peg/球

## 问题描述

当前 peg 板太稀疏（8行30个），导致：
1. 策略性差 — 球路径单一，没什么选择
2. 观赏性差 — 板子看起来很空
3. peg 和球尺寸偏大（peg半径12，球半径20），限制了密度

需要改为类似 Peglin / Roundguard 的密集 stagger 网格布局（pachinko 风格），缩小 peg 和球尺寸。

## 目标参数

### peg 布局
- 板子 720×1080
- peg_radius: 12 → 7
- 行数: 12行，stagger（偶数行偏移）
- 列数: 每行 8-9 个，stagger 交替（偶数行 8 个，奇数行 9 个，或反过来）
- 行间距均匀覆盖板子 y 轴（约 y=12% 到 y=75%）
- 保持 bonus/danger peg 的随机分配逻辑不变

### 球尺寸
- ball_radius: 20 → 14（所有 4 种球）
- 涉及 `resources/ball_config.json`

### 分数目标
- 当前 peg 总量约 30，目标分 80/120/160
- 新 peg 总量约 100，按比例提升目标分到 250/400/560
- 涉及 `resources/round_config.json`

## 约束

- **不要改的文件**：`project.godot`、所有 `.tscn`、所有 `.gd` 脚本文件
- **只改配置文件**：`resources/board_layouts/default.json`、`resources/ball_config.json`、`resources/round_config.json`
- peg 类型分配逻辑（bonus/danger/normal）在 board.gd 中按 round_data 的 bonus_peg_count/danger_peg_count 控制，不用动
- 保持 board_width=720, board_height=1080

## 验收标准

1. 编译通过：
```bash
cd /home/kenny/orb_foundry/godot
./Godot_v4.6-stable_linux.x86_64 --headless --quit 2>&1
# 无 ERROR 行
```

2. JSON 语法正确（可以用 python3 -m json.tool 验证）
3. peg 总数应该在 90-110 之间
4. ball_radius 全部为 14
5. 分数目标与 peg 总量成正比提升
