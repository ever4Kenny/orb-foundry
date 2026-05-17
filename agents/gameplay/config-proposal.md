# Orb Foundry v2.1 数值配置提案｜小玩

日期：2026-05-17
版本：v2.1

---

## 一、关卡目标分

| 关卡 | 单关目标 | 累计目标 | 发球数 |
|---|---|---|---|
| 第1关 | 600 | 600  | 4 |
| 第2关 | 800 | 1400 | 5 |
| 第3关 | 1000 | 2400 | 5 |

---

## 二、Peg 分值

| 类型 | 单次得分 | 备注 |
|---|---|---|
| normal（普通） | +10 | 基础分 |
| bonus（奖励）  | +30 | R2激活后额外+15 = +45 |
| danger（危险） | -20 | R1每关开始随机移除1个 |

---

## 三、槽位分值

| 槽位 | 效果 | 备注 |
|---|---|---|
| left（左） | 弹性+10%（下一颗球restitution×1.1） | 物理加成 |
| center（中） | +10分 | R5激活后变+25 |
| right（右） | 回复1颗球（从已用球中随机补回球袋） | 续命机制 |

---

## 四、Combo 倍率

- 公式：每次命中分 × (1 + 0.1 × combo_count)
- 上限：×2.0（第10次命中后锁定）
- 重置条件：落槽 或 球停止

---

## 五、Relic 效果参数（R1~R6）

| ID | 名称 | 关键参数 |
|---|---|---|
| R1 | 熔炉残温 | trigger: onRoundStart；remove danger×1 + normal×1（random） |
| R2 | 奖励共振 | trigger: onPegHit(bonus)；score_bonus: +15 |
| R3 | 额外弹仓 | draw_per_turn: 3→4 |
| R4 | 裂纹累积 | glass.effect_threshold.hit_count: 6→4 |
| R5 | 重锤校准 | center_slot.score: 10→25 |
| R6 | 磁极强化 | magnet.effect_threshold.attract_radius: ×1.5 |

抽取规则：6选3（开局三选一 + 第2关后三选一），无放回。

---

## 六、盘面改造效果参数（B1~B6）

| ID | 名称 | 关键参数 |
|---|---|---|
| B1 | 金属镀层 | add bonus peg ×4，region: center |
| B2 | 危险清除 | remove all danger pegs + 等量normal pegs |
| B3 | 中心漏斗 | add bonus peg ×9，pattern: funnel，region: center_bottom |
| B4 | 双子通道 | remove peg ×6，pattern: vertical_corridor，region: center |
| B5 | 镜面边墙 | add_wall edges，reflectivity: 1.0 |
| B6 | 血色盘面 | danger peg ×2；onAllDangerCleared → +50分 |

抽取规则：6选2（第1关后二选一 + 第2关后二选一），无放回。

---

## 七、主动技能：重投

- 充能次数：2次/局
- 效果：丢弃当前3颗候选球，从球袋重新抽3颗
- 不补充新球，不消耗球袋总量

---

## P0 调参建议（≤5条）

1. **danger peg 分值**：当前-20，若内测发现玩家主动规避导致盘面无聊，可调至-15。
2. **bonus peg 分值**：当前+30，若第1关通过率<40%，可调至+35。
3. **center槽基础分**：当前+10，R5后+25；若R5被选率<20%，可将基础值提至+15。
4. **glass分裂阈值**：当前6次，R4后4次；若玻璃球被选率<15%，基础值可降至5。
5. **combo上限**：当前×2.0（10次），若玩家反馈combo感不强，可降至8次触发上限。
