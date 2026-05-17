# Gameplay Status

当前任务：按 Godot v0.4 的 4 升级版本做真人无解释试玩。

已完成：
- ✅ Godot 工程 headless 检查（零 ERROR）
- ✅ Canvas 原型自动化测试（结论：太简单，不再作为验证对象）
- ✅ Godot 代码完整审查
- ✅ 初版玩法验证报告输出：`agents/gameplay/playtest-report.md`
- ✅ dead upgrade 方向已由小码修复：第 3 轮加入爆炸 peg，使爆炸类升级可生效

下一步：
- 使用当前 Godot v0.4，不回退 2 选 1。
- 测 3~5 人。
- 每个玩家必须记录：选择升级、选择理由、第 3 轮打法是否变化、是否感到升级有效、是否愿意再开。
- 试玩后更新 `agents/gameplay/playtest-report.md` 给总监裁决。

重点验证：
- 5 秒内是否看懂目标。
- 第 2 轮 chain / 爆炸 peg 是否形成明显爽点。
- 4 个升级是否都能被理解。
- 升级后第 3 轮打法是否变化。
- 是否愿意再开一局。

本 Sprint 不做：
- 不新增球/peg 类型
- 不设计完整版数值体系
- 不做竞品拆解
- 不提新系统、新美术资产、新平台需求
