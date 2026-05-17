# Tech Status

> 当前对齐：`mvp-plan-v2.1.md`
> 更新：2026-05-17

## 阶段进度

| 阶段 | 涉及看板任务 | 状态 | Commit |
|---|---|---|---|
| 阶段 1：触发器框架 + RelicManager 骨架 | T1 | ✅ Done & Pushed | 37c5d6f |
| 阶段 2：6 个 relic effect + 已激活栏 UI | T2（含 art A2 emoji 占位） | 🟡 In Progress | — |
| 阶段 3：4 个选择 UI（起始/第1关后/第2关后） | T4 / T5 / T10 / T11 | ⏳ Pending | — |
| 阶段 4：改造池扩展 + JSON schema | T3 / T9 | ⏳ Pending | — |
| 阶段 5：重投 + Combo 全局 + 关前弹窗→toast | T6 / T7 / T8 | ⏳ Pending | — |

## 执行模式

- 本项目所有代码由本地 Claude Code 实现，小码负责任务卡、审查 diff、跑 headless 验收、补 commit/push。
- 工作流：`CLAUDE_TASK.md` →
  `cd godot && HOME=/home/kenny claude -p --dangerously-skip-permissions "<提示>" < /dev/null > /tmp/claude.log 2>&1`
  → 审查 → commit → push。
- 重要：必须 `< /dev/null`，否则 claude 在管道环境会触发 401 Invalid bearer token。

## 不做（本项目 v2.1 边界）

- 不新增球/peg/敌人/Boss/职业/稳定度/轨迹预览/元素系统
- 不做 relic 稀有度/商店/升级/合成
- 不做美术资产、音效
- 不接 Steam/移动端
- 不动目标分 600/1200/2000（v0.5 实测口径）

## 风险

- ⚠️ **R1 时序 BUG（必修）**：流程已改为开局选 relic，第 1 关起 R1 就可能生效。R1 的 `onRoundStart` 触发时 board 可能尚未 connect，导致删 peg 静默失败。
  - **修法**：用 `apply_pending_round_start_effects` 模式——R1 触发时入队，board 的 `_ready()` / connect 回调里 flush 队列，而不是直接操作 board。
  - **验收**：第 1 关开局持有 R1 → 盘面少 1 红 + 1 灰 peg（必须可见）。
- Claude Code 偶发 401，处理方式：短 prompt 探活 → 重试
- 阶段 3/4 涉及多场景 .tscn 改动，headless 无法验证 UI，需小玩在 GUI 验证

## 产出目录

- 代码：`~/orb_foundry/godot/`
- 任务卡（一次性指令书，不入 git）：`~/orb_foundry/godot/CLAUDE_TASK.md`
- 配置：`~/orb_foundry/godot/resources/`
- GitHub：https://github.com/ever4Kenny/orb-foundry
