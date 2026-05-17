# CLAUDE_TASK：v2.1 阶段 2 — 6 个 relic effect 实现 + 已激活栏 UI

## 背景

阶段 1 已完成：RelicManager 骨架、6 个 relic 配置、4+1 触发器钩子全部接入。
当前命中 relic 只打 log，**本阶段把 6 个 effect 真实跑起来，并在屏幕顶部显示一排「已激活 relic」图标**。

参考文档：`~/orb_foundry/mvp-plan-v2.1.md` 第四节。

## 目标

### A. 实现 6 个 relic effect

RelicManager 内部把 `_dispatch` 从「只打 log」改为「分发到具体 effect handler」。
保留一行 log（方便阶段 3 调试），但要真实生效。

| ID | 触发 | 当前实现要点 |
|---|---|---|
| R1 熔炉残温 | onRoundStart | 在 board 渲染完成后，从盘上随机找 1 颗 alive=true 且 peg_type=="danger" 的 peg 调 `die()`；再随机找 1 颗 alive=true 且 peg_type=="normal" 的 peg 调 `die()`。任一类型不足就跳过那一类。 |
| R2 奖励共振 | onPegHit (tag_filter=bonus) | 给当前球的得分管线追加 +15 分。最简单做法：`ScoreManager.add(15)` 直接加。 |
| R3 额外弹仓 | onRoundStart | 让本关之后所有 ball_select 的候选球数从 3 → 4。**预计算型**：暴露 `RelicManager.get_ball_draw_count() -> int`，默认 3，激活 R3 后返回 4。ball_select 调用方改用此 API（找到 ball_select 调 `BallBag.draw(3)` 或类似硬编码 3 的地方，替换）。 |
| R4 裂纹累积 | onBallLaunch | 把刚发射的球（payload.ball_node）的 `split_threshold` 改为 4。**直接修改 ball 节点属性**即可，对所有球种调都安全（非玻璃球不会用到这个值）。 |
| R5 重锤校准 | onSlotScore (tag_filter=center) | 中槽（slot_position=="center"）当前 `ScoreManager.add(50)`。R5 激活时改为 +25。**注意 mvp-plan 写的是 "+10 → +25"，但代码当前是 +50**——这是个口径冲突。**本任务按"激活时把中槽加分从 50 改成 +75（即 50+25 的 R5 增量解释）" 处理是错的**。正确做法：把 slot.gd 中槽改成读 RelicManager 的覆盖值：`var center_score = RelicManager.get_center_slot_score(50)` —— 默认返回 50，激活 R5 后返回 75（即额外 +25），保持口径"在原基础上 +25 分"。slot.gd 里这行 `ScoreManager.add(50)` 改成 `ScoreManager.add(center_score)`。其他两个槽不动。 |
| R6 磁极强化 | onBallLaunch | 把刚发射的球的 `magnet_range` ×1.5。同 R4，直接改 payload.ball_node 的属性。非磁球不受影响（只是改了一个用不到的字段）。 |

**口径说明（写进 CLAUDE_TASK 给自己看的）**：
- R3 的 ball_draw_count 是 query 型，不在 `_dispatch` 里做副作用，effect 解释器对它跳过即可
- R4 / R6 是 onBallLaunch 触发的属性 setter，要在 `_dispatch` 里识别 effect.type 并改 payload.ball_node
- R1 是 onRoundStart 触发的盘面副作用，需要在 board 已渲染完成的情况下执行；目前 `RelicManager._dispatch("onRoundStart", ...)` 是在 `start_round()` 中、`round_started.emit()` 之后立刻调用——但此时 board 可能还没渲染。**关键**：把 R1 的执行**延迟到 main.gd 渲染完 board 之后**。一个干净办法：RelicManager 不直接执行 R1，而是把"pending onRoundStart effects"挂在变量里；board 渲染完成后由 main.gd 调用 `RelicManager.apply_pending_round_start_effects()` 真正执行。如果你有更好做法也可以，但**必须保证 R1 在 board pegs 已经实例化后执行**。
- R5 用 query 接口，不在 `_dispatch` 里做副作用，handler 跳过

### B. 已激活栏 UI

需求：屏幕**顶部一排**显示当前已激活的 relic，每个 relic 一个小卡片。

样式：
- 一排横向排列，居中或居右都可（你选一个）
- 每个 relic 显示一个 emoji + 名字（emoji 自选合理的，比如 R1🔥 R2💎 R3🎒 R4🧊 R5⚖️ R6🧲）
- 悬停或点击时显示 desc 文案——**MVP 不做交互**，直接显示名字即可
- 为空时不显示该排

实现位置：
- 复用 HUD（`scripts/ui/hud.gd` + 对应场景）。在 HUD 里加一个 HBoxContainer 放 relic 卡片
- 或者新建 `scripts/ui/relic_bar.gd` 单独管理也行——你选简单的那条路
- RelicManager 加一个 signal：`relic_activated(relic: Dictionary)`，在 `activate()` 末尾 emit；UI 监听这个 signal 增量更新

### C. 阶段 1 留下的调试钩子

保留 `ORB_DEBUG_ACTIVATE_ALL=1`。这是阶段 2 自测的主要手段（因为还没接选择 UI）。

## 不要做的

- 不要做 relic 选择三选一 UI（那是阶段 3）
- 不要改 upgrade_config.json 或现有 4 个 upgrade 逻辑（那是阶段 4）
- 不要做重投按钮（阶段 5）
- 不要做 Combo 全关化（阶段 5）
- 不要改目标分（保持 600/1200/2000）
- 不要重命名现有文件
- 不要改 RelicManager autoload 名字或注册位置

## 验收

逐条自测，把结果贴进交付报告：

1. headless 启动 0 error：
   ```
   ./Godot_v4.6-stable_linux.x86_64 --headless --quit-after 5 2>&1 | grep -iE "error|script error" || echo "OK no error"
   ```

2. 正常启动（不带环境变量）—— 行为与阶段 1 完全一致：HUD 没有任何 relic 卡片，没有 [Relic] 日志。

3. 带 `ORB_DEBUG_ACTIVATE_ALL=1` 启动 30 秒 —— 应看到：
   - log 里有 6 个 relic 激活的痕迹
   - log 里 onRoundStart 触发后 R1 真实移除了 peg（用 `print` 在 R1 handler 里输出"R1: removed danger peg at (x,y), normal peg at (x,y)"）
   - HUD 顶部有 6 个 relic 卡片显示

4. JSON 仍可解析：`python3 -c "import json; json.load(open('resources/relic_config.json'))"` 退出码 0

5. `git diff --stat HEAD` 改动范围合理：RelicManager / HUD / slot.gd / 球生成相关；**不要**碰 upgrade_config.json、round_manager state 机、目标分配置。

6. 自检：headless 模式无法亲眼看 UI，所以**对 UI 改动单独输出一段说明**，描述你改了哪个场景文件、加了什么节点、节点路径是什么——小码会接手 Godot 编辑器打开验证。

## 交付

- commit message：`feat(relic): stage2 effect interpreters + active relic bar`
- 不要 push
- 报告里逐条贴上面 6 条验收结果（headless 跑不动的部分明说"待小码 GUI 验证"）
