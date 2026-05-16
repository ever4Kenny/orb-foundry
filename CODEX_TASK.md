# Codex Task: 第2关连锁爆炸 + 关卡入口/结算 + combo动画 + 升级调整

## Part 1: 关卡入口展示

每关开始前弹出一个半屏面板，显示：
- 关卡名（如"第1关: 精准连击"）
- 玩法详细说明（如"连续击中灰色钉子获得连击加分：连击数-1 ×5分。击中金色或红色钉子中断连击。"）
- "点击开始" 按钮

实现：
- 新建 `scripts/ui/round_entry.gd`（CanvasLayer）
- 新建 `scenes/ui/round_entry.tscn`
- `round_config.json` 增加 `"mechanic_desc"` 字段（每关一段说明文字）
- `round_manager.gd` 新增 `ROUND_ENTRY` 状态，在 `start_round()` 前先进入此状态
- `main.gd` 实例化 round_entry，连接信号，点击后继续到 BALL_SELECT

## Part 2: 第2关 — 连锁爆炸 (Chain Explosion)

### 规则
- 第2关新增爆炸 peg（颜色：橙色 #ff6600，带脉冲光晕）
- 球击中爆炸 peg → 80px 半径内所有 peg 被摧毁
- 被连锁摧毁的 peg 正常计分（normal=10, bonus=25）
- 连锁摧毁的 peg 不会再次触发爆炸（无递归）
- 视觉：爆炸 peg 触发时 → 冲击波环扩散（draw_arc 缩放）+ 周围 peg 碎裂消失

### 配置
- `round_config.json` 第2轮：`"mechanic": "chain"`, `"explosion_peg_count": 8`
- `board.gd`: 在 peg 生成时，根据 `explosion_peg_count` 随机分配一些 normal peg 变为 "explosion" 类型
- 爆炸 peg 有自己的标签 `"explosive"`，可以是一部分 normal peg 转化

### 实现
- `peg.gd`: 新增 `peg_type == "explosion"` 的绘制（橙色脉冲），新增 `explode()` 方法播放冲击波动画
- `ball.gd`: `_handle_normal_hit` 中检测 peg_type == "explosion"，调用连锁摧毁
- 连锁摧毁：遍历 `get_tree().get_nodes_in_group("pegs")`，对距离 < 80px 的 peg 调用 die() + 加分

### shockwave 动画
- peg.gd 的 `explode()`: 从半径 10 扩大到 80，tween 0.25s，draw_arc 橙色半透明 + 逐渐消失

## Part 3: combo 实时动画

在 ball.gd 的 `_record_normal_combo()` 中，当连击数 >= 2 时，显示浮动文字：
- 在球的位置上方创建一个临时 Label："连击! x3"（根据连击数）
- 文字从球位置向上浮动 + 缩放弹出 + 渐隐
- 颜色：渐变色（白→金→透明），字体稍大
- 持续约 1 秒后自动删除
- 用 Tween 实现，不新建场景文件

实现方式（选择最简）：
- `main.gd` 维护一个 `_spawn_combo_text(position, count)` 方法
- 该方法创建一个 Label，挂 Tween 上浮+缩放+淡出，1s 后 queue_free

### 实现细节
- ball.gd 需要通知 main.gd 显示 combo 文字
- 方案：ball.gd 新增信号 `combo_updated(combo_count: int)` 
- main.gd 连接信号，创建浮动文字

## Part 4: 升级调整

为第2关设计新升级选项，替换或扩充现有升级：
- 新增：`"id": "bigger_blast"`, `"name": "爆炸增强"`, `"type": "blast_radius"`, `"radius_multiplier": 1.4`, `"desc": "爆炸半径+40%"`
- 新增：`"id": "more_explosives"`, `"name": "更多炸药"`, `"type": "add_pegs"`, `"peg_type": "explosion"`, `"count": 3`, `"desc": "盘面+3个爆炸peg"`
- 保留原有 "金属镀层" 和 "危险清除"

如果 blast_radius 实现太复杂，可以先只做 more_explosives（复用现有 add_pegs 机制，peg_type="explosion" 即可）。

## Part 5: 关卡结算

每关结束（所有 ball 落地 + slot 吸收完成）后：
- 显示结算面板，内容：命中数、得分、combo数据（如有）
- 用户点击确认后，如果过关 → 进入 REWARD_SELECT 或 UPGRADE_SELECT
- 可以复用 shot_result 但改为关卡级汇总

简化方案：复用现有 shot_result，但在 round 结束时（而非每 shot 后）显示。修改 main.gd 的回调逻辑。

## 约束汇总

**可以改**：
- `scripts/ball.gd`、`scripts/peg.gd`、`scripts/board.gd`、`scripts/main.gd`、`scripts/round_manager.gd`、`scripts/score_manager.gd`
- `scripts/ui/shot_result.gd`、`scripts/ui/round_entry.gd`（新建）、`scripts/ui/hud.gd`
- `scenes/ui/round_entry.tscn`（新建）、`scenes/ui/shot_result.tscn`、`scenes/ui/upgrade_select.tscn`
- `resources/round_config.json`、`resources/upgrade_config.json`

**不要改**：`.gd` 和 `.tscn` 中未列出的文件

## 优先级

如果改动量太大，可以按此顺序降级：
1. 必须：第2关连锁爆炸机制 + 配置
2. 必须：关卡入口展示
3. 重要：combo 实时动画
4. 可选：升级调整（可以后续再做）
5. 可选：关卡结算（可以先跳过，留现有 shot_result）

## 验收

```bash
cd /home/kenny/orb_foundry/godot
./Godot_v4.6-stable_linux.x86_64 --headless --quit 2>&1
# 无 ERROR
```
