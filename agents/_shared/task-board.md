# Task Board

> 当前对齐：**mvp-plan-v2.1.md**（v2 已废弃，见该文件顶部说明）
> 更新时间：2026-05-17（小码认领并启动）

## In Progress

- [tech 小码] **阶段 2** In Progress：T2 Relic 6 effect + T4 起始 relic 三选一 UI（T4 提前，因 R1 验收依赖开局选 relic 入口）。
- [art 小美] A6 整体 v2.1 可读性复核 — 待 D3（等 tech 实机）

## Done — Sprint v2.1 art

- [art 小美] A1 Relic 选择卡片视觉规范 ✓ D1
- [art 小美] A4 改造选择卡片 ✓ D1
- [art 小美] A2 Relic 已激活栏 ✓ D2
- [art 小美] A3 Combo 倍率显示样式 ✓ D2（含 T8 联调字段）
- [art 小美] A5 重投按钮样式 ✓ D2（含 T6 联调字段）
## Sprint v2.1 — 小码执行映射

为减少切换成本，把看板任务按"5 个 PR 阶段"重新分组，每阶段一次 commit，按序推进：

| 阶段 | 看板任务 | 说明 | 状态 |
|---|---|---|---|
| 阶段 1 | T1 | 触发器框架 + RelicManager 骨架（6 个 relic 仅 log，不接 effect） | ✅ Done — commit 37c5d6f，已 push |
| 阶段 2 | T2 | 6 个 relic effect 实现 + 已激活栏 UI（A2 同步纳入） | 🟡 In Progress |
| 阶段 3 | T4 / T5 / T10 / T11 | 起始 relic 三选一 + 第 2 关后 relic 三选一 + 第 1 关后双选页（球+改造）+ 第 2 关后双选页（relic+改造） | ⏳ Pending |
| 阶段 4 | T3 / T9 | 改造池扩展 B3~B6 + JSON schema 升级 | ⏳ Pending |
| 阶段 5 | T6 / T7 / T8 | 重投按钮 + 删除关前弹窗（加首关 toast）+ Combo 全关化 + 倍率实时显示 | ⏳ Pending |

每阶段验收通过后立即 commit + push，由小玩做对应 G1~G5 验证。

## Sprint v2.1 — Backlog（原始任务表保留）

### tech 小码

- [x] T1 触发器框架升级（见阶段 1，commit 37c5d6f）
- [ ] T2 Relic 系统 6 effect（阶段 2 — In Progress）
- [ ] T3 改造池扩展（阶段 4）
- [ ] T4 起始 relic 三选一 UI（阶段 3，协作 art A1）
- [ ] T5 第 2 关后 relic 三选一 UI（阶段 3）
- [ ] T6 "重投"按钮 + 球袋逻辑（阶段 5，协作 art A5）
- [ ] T7 删除关前弹窗 + 首关 toast（阶段 5）
- [ ] T8 Combo UI 实时显示（阶段 5，协作 art A3）
- [ ] T9 配置 JSON schema 升级（阶段 4）
- [ ] T10 第 1 关后选择 UI 调整（球三选一 + 改造二选一）（阶段 3）
- [ ] T11 第 2 关后选择 UI（relic 三选一 + 改造二选一）（阶段 3）

**tech 小计：约 8 天**

### art 小美

- [x] A1 Relic 选择卡片视觉规范 ✓ D1（定稿于 `agents/art/mvp-visual-spec.md §2.1`）
- [x] A2 Relic 已激活栏样式 ✓ D2（定稿于 §2.2，含 6 个简称：炉/振/仓/裂/锤/磁）
- [x] A3 Combo 倍率显示样式 ✓ D2（定稿于 §2.3，含 T8 联调字段）
- [x] A4 改造选择卡片 ✓ D1（复用 A1 模板，描边蓝白区分）
- [x] A5 重投按钮样式 ✓ D2（定稿于 §2.4，含 T6 联调字段）
- [ ] A6 整体 v2.1 可读性复核（阶段 5 后，等小码实机）

**art 小计：约 3 天 → D1+D2 已完成 5/6，等 tech 落地后做 A6**

### gameplay 小玩

- [ ] G1 v2.1 测试用例清单（建议阶段 1~2 之间起草）
- [ ] G2 6 个 relic 单独录屏验证（阶段 2 完成后立刻开始）
- [ ] G3 6 个改造单独录屏验证（阶段 4 完成后）
- [ ] G4 完整流程联调试玩 ≥10 局（阶段 5 完成后）
- [ ] G5 内部试玩 3~5 人 + 重写 playtest-report（阶段 5 + G4 后）

**gameplay 小计：约 5 天**

## Waiting Review

- [default] 等 v2.1 全套阶段（1~5）落地后做 Go / Fix / No-Go 裁决。

## Done（v2 阶段）

- [tech] Godot v0.4 修复 dead upgrade：第 3 轮加入爆炸 peg。
- [tech] **阶段 1（T1）触发器框架 + RelicManager 骨架** — commit 37c5d6f，已 push。
- [gameplay] Godot v0.4 试玩报告产出。
- 弹珠肉鸽机终止并归档。
- v2 总方案完成。
- MVP v2 方案完成。
- MVP v2.1 方案完成（`mvp-plan-v2.1.md`）。
- 平台裁决完成。
- Sprint v2 拆解和 Agent 分工完成。

## Discarded（v2.1 废弃）

- [gameplay] ~~按 Godot v0.4 的 4 升级版本执行 3~5 人无解释试玩~~ → 被 G5 取代（基于 v2.1 完整流程重做）。
- [art] ~~暂停新增资产，只等待试玩后做可读性复核~~ → 被 A1~A6 取代（v2.1 新增 UI 需求）。
- [default] ~~等真人试玩报告 → Go / Fix / No-Go 裁决~~ → 推迟到 v2.1 完成后。
- 每关前玩法说明弹窗任务（如有）→ Combo 改为全局机制，弹窗本身被删除（tech T7）。
- 任何遗留 Cocos Creator 相关任务 → 技术栈已改 Godot 4.6。

## Blocked

- 无。

## Scope Guard（v2.1 版）

更新于 mvp-plan-v2.1.md §9.3：

- 不新增第 5 种球。
- 不新增第 4 种 peg 类型。
- 不新增敌人、Boss、职业、发射器模块。
- 不做稳定度、轨迹预览、元素系统。
- 不做 relic 稀有度 / 颜色 / 商店 / 升级 / 合成。
- 不做主动 relic（除"重投"外全部被动）。
- 不做美术资产（仍保持几何形状 + 颜色）。
- 不做音效。
- 不做局外成长 / 解锁。
- 不接正式产品平台（Steam/移动端）。
- 不动 v0.5 实测目标分（600/1200/2000，发球数 4/5/5）。
