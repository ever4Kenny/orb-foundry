# Codex Task: Godot Orb Foundry MVP — Day 2 修复 + 完善

## 当前问题（必须修复）

### 1. 🔴 peg 碰撞检测失效
`scripts/peg.gd` 的 `_setup_collision()` 中缺少 `body_entered.connect(_on_body_entered)`。
没有这行，peg 永远不会收到球的碰撞信号，整个物理交互不工作。
**修复**：在 `_setup_collision()` 末尾加 `body_entered.connect(_on_body_entered)`。

### 2. 🔴 peg 碰撞层未设置
board.gd 程序化创建的 peg 没有设置 collision_layer 和 collision_mask。
ball.gd 中球的 collision_mask = 2|4|8（layer 2=peg, 4=wall, 8=slot）。
peg 必须在 layer 2，mask 为 layer 1。
**修复**：在 `peg.gd _setup_collision()` 中加：
```gdscript
collision_layer = 2
collision_mask = 1
```

### 3. 🔴 发射方向反了
`scripts/main.gd` 第 80 行：
```gdscript
var direction := drag_start - release_position
```
应该改为：
```gdscript
var direction := release_position - drag_start
```
否则向下拖拽球往上方飞。

### 4. 🔴 球分裂后子球无碰撞形状
`_split()` → `_create_split_ball()` 创建的子 RigidBody2D 没有 CollisionShape2D。
因为 `_setup_collision()` 在 `_ready()` 中调用，但 `new()` 创建后 `_ready()` 未自动触发。
**修复**：在 `_create_split_ball` 末尾显式调用 `child._setup_collision()` 并设置碰撞层。

### 5. 🟡 槽位弹性加成未实现
`scripts/slot.gd` 中 `elasticity_boost` 效果是空 `pass`。
应该在球上设置一个标记（如 `next_bounce_boost`），
main.gd 在下一颗球发射前应用。
**简化方案**：直接加一个全局变量到 ScoreManager：
`ScoreManager.next_elasticity_boost = 0.1`，
main.gd 发射前应用到球的 `bounce_value`。

### 6. 🟡 槽位球回复未实现
`scripts/slot.gd` 中 `ball_recovery` 效果是空 `pass`。
应该：`RoundManager.shots_left += 1`（但 shots_left 减到负数时不应该加）。
**简化方案**：主流程中检查，如果 shots_left <= 0 且 round 未结束，再 +1。

### 7. 🟡 球选择面板未显示球袋内容
`scripts/ui/ball_select.gd` 只显示抽到的 3 颗球，没有显示球袋剩余。
应该在标题下方加一行：`👜 剩余 N 球 ●●○...`
监听 `BallBag.bag_changed` 信号。

## Day 2 核心验证项（不改代码，仅确认）

运行后验证：
1. 铁球发射后能碰到 peg 并计分（穿透不反弹）
2. 水晶球弹性 0.9 明显比铁球 0.3 弹跳多
3. 磁球发射后能看到轨迹弯向金色 peg
4. 玻璃球撞 6 次后分裂为 2 颗小球
5. 球落中槽 +10 分，左槽下一球弹性高，右槽回复 1 球
6. 球袋初始 6 球，抽 3 选 1，用完后补 2 铁球

## 验收标准
```bash
cd /home/kenny/orb_foundry/godot
./Godot_v4.6-stable_linux.x86_64 --headless --quit 2>&1  # 零 ERROR
```

## 不要改
- JSON 配置文件
- project.godot
- .tscn 文件的 uid
- 之前已工作的逻辑（计分、轮次判定、球袋系统）
