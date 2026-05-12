# 《Orb Foundry》Steam/Godot MVP 技术方案

版本：v1.0
日期：2026-05-12
定位：替代第1版 Canvas 2D 原型，切换 Steam PC + Godot 4.6

---

## 一、技术栈

| 项 | 选型 | 理由 |
|---|---|---|
| 引擎 | Godot 4.6 | 最新稳定版，2D 物理成熟，免费无抽成 |
| 语言 | GDScript | 类 Python，适合快速原型 + 单人开发 |
| 物理 | 内置 2D (Box2D 分支) | RigidBody2D 原生碰撞/反弹/重力 |
| 平台 | Steam (Windows/Linux) | Godot 原生导出，无需额外运行时 |
| 分辨率 | 1920×1080 横屏 16:9 | Steam 主流比例，可降级窗口化 |
| Steam SDK | GodotSteam (GDExtension) | 社区维护，覆盖成就/统计/云存档 |
| 美术 | 纯几何 + 颜色区分（同 v1） | 零资产 MVP，后续替换 |
| 音效 | 无（MVP 不做） | — |

---

## 二、分辨率 & 布局方案

### 2.1 总布局：1920×1080 横屏

```
┌────────────────────────────────────────────────┐
│  ┌──────────────┐  ┌─────────────────────────┐  │
│  │              │  │  顶部信息栏              │  │
│  │   弹珠盘面    │  │  - 轮次 / 目标分         │  │
│  │   720×1080   │  │  - 当前分 / 剩余球        │  │
│  │   竖屏       │  │                         │  │
│  │              │  │  球袋展示                 │  │
│  │              │  │                         │  │
│  │              │  │  选择面板                 │  │
│  │              │  │  (抽3选1 / 改造2选1)      │  │
│  │              │  │                         │  │
│  │              │  │  发射提示                 │  │
│  └──────────────┘  └─────────────────────────┘  │
│   ↑ 960px 中心区      ↑ 960px 右侧 UI 面板       │
└────────────────────────────────────────────────┘
```

### 2.2 盘面区域

- 竖屏 720×1080，居中放置，左右各留 600px 边距
- peg 布局从 Canvas 原型等比放大（×2 缩放）
- 8 行 × 3~5 列交错排列，约 35 个 peg
- 底部 3 个槽位

### 2.3 右侧 UI 面板 (600×1080)

- 顶部：轮次标题 + 目标分 + 当前分 + 球数
- 中部：球袋可视化（剩余球的颜色圆点）
- 下部：交互面板（球选择 / 改造选择）
- 底部：操作提示

### 2.4 缩放方案

- 基准分辨率 1920×1080
- Stretch Mode: `canvas_items` — UI 随窗口缩放，保持比例
- 窗口模式：默认窗口化 1280×720，可全屏
- 盘面区域不做拉伸变形

---

## 三、Godot 工程结构

```
orb_foundry_godot/
├── project.godot              # 项目配置
├── export_presets.cfg         # Steam 导出预设
├── scenes/
│   ├── main.tscn              # 主场景 (布局 root)
│   ├── board.tscn              # 盘面 (Node2D)
│   ├── ball.tscn               # 弹珠 (RigidBody2D)
│   ├── peg.tscn                # 钉子 (StaticBody2D)
│   ├── slot.tscn               # 槽位 (Area2D)
│   └── ui/
│       ├── hud.tscn            # HUD 信息栏
│       ├── ball_select.tscn    # 球选择面板
│       └── upgrade_select.tscn # 改造选择面板
├── scripts/
│   ├── main.gd                 # 游戏入口 / 状态机
│   ├── board.gd                # 盘面管理 (peg 生成/清除)
│   ├── ball.gd                 # 弹珠行为 (4 种类型 + 效果)
│   ├── peg.gd                  # 钉子行为 (碰撞回调)
│   ├── slot.gd                 # 槽位行为
│   ├── ball_bag.gd             # 球袋系统
│   ├── round_manager.gd       # 轮次管理
│   ├── score_manager.gd       # 分数管理
│   └── ui/
│       ├── hud.gd
│       ├── ball_select.gd
│       └── upgrade_select.gd
├── resources/
│   ├── board_layouts/          # peg 布局 JSON
│   │   └── default.json
│   ├── ball_config.json        # 4种球参数
│   ├── round_config.json       # 3轮参数
│   └── upgrade_config.json     # 2种改造定义
├── assets/                     # (预留，MVP 用几何替代)
│   ├── textures/               # 后续替换圆为精灵图
│   └── audio/                  # 后续加音效
└── addons/
    └── godotsteam/             # Steam SDK (Day5 预留)
```

---

## 四、物理方案

### 4.1 弹珠 (RigidBody2D)

```gdscript
# ball.gd 核心逻辑
extends RigidBody2D

enum BallType { IRON, CRYSTAL, MAGNET, GLASS }

@export var ball_type: BallType
@export var weight: float = 1.0
@export var bounce: float = 0.6
@export var col_count: int = 0
@export var split_threshold: int = 6
@export var magnet_range: float = 50.0

func _ready():
    # 基于 physics_material_override 设置弹性
    var mat = PhysicsMaterial.new()
    mat.bounce = bounce
    physics_material_override = mat
    # 重量由 mass 控制
    mass = weight

func on_peg_hit(peg_type: String, peg_tags: Array):
    # 碰撞回调（由 peg 触发或通过 Area2D 检测）
    match ball_type:
        BallType.IRON:
            # 穿透：不反弹，直接穿过并计分
            _pierce_peg(peg_type, peg_tags)
        BallType.MAGNET:
            # 磁力：朝最近 metal tag peg 施加力
            _apply_magnetic_force()
        BallType.GLASS:
            col_count += 1
            if col_count >= split_threshold:
                _split()

func _pierce_peg(peg_type, peg_tags):
    # 穿透逻辑：取 Canvas 原型中的计分规则
    match peg_type:
        "bonus": score += 25
        "normal": score += 10
        "danger": score = max(0, score - 5); _slow_down()
```

### 4.2 钉子 (StaticBody2D)

- StaticBody2D + CollisionShape2D (圆形)
- 通过 `body_entered` 信号检测碰撞
- 属性：类型(normal/bonus/danger)、标签(tags)、存活状态

### 4.3 碰撞层设计

| Layer | 用途 |
|-------|------|
| 1 | 弹珠 |
| 2 | 钉子 |
| 3 | 墙壁 |
| 4 | 槽位 |

- 弹珠 mask: 钉子 + 墙壁
- 钉子 mask: 弹珠
- 槽位 mask: 弹珠

### 4.4 与 Canvas 原型的差异

| 项目 | Canvas 2D (v1) | Godot (v2) |
|------|---------------|------------|
| 碰撞检测 | 手动圆-圆距离检测 | 引擎自动 |
| 物理积分 | 手动欧拉积分 | 引擎内置 |
| 重力 | 全局变量 GR=500 | `ProjectSettings.gravity` |
| 墙壁 | 手动 if 判断 | StaticBody2D 矩形 |
| 槽位 | 手动距离判断 | Area2D + body_entered |
| 穿透 | 手动 pierced Set | `set_collision_layer_value` 临时禁用碰撞 |

---

## 五、MVP 实施计划（5天）

### Day 1：Godot 工程 + 物理底盘
- 创建 Godot 4.6 项目
- 搭建 1920×1080 主场景布局
- 实现盘面：StaticBody2D peg 生成（从 JSON 加载布局）
- 实现弹珠发射：RigidBody2D + 初始速度
- 碰撞检测 + 反弹（physics_material_override.bounce）
- 底部 3 个槽位 Area2D
- 分数累加显示
- **产出**：1 颗铁球可发射、碰撞 peg、落入槽位、显示分数

### Day 2：4 种球 + 球袋
- 实现 4 种球的 RigidBody2D 子类行为
- 穿透球：碰撞时临时禁用碰撞层
- 磁球：_physics_process 中向最近奖励 peg 施加力
- 玻璃球：碰撞计数 + 分裂（实例化 2 个新 RigidBody2D）
- 球袋系统：抽 3 选 1 UI 面板
- 发球数限制
- **产出**：可抽球、选球、4 种球行为可区分

### Day 3：3 轮循环 + 盘面改造
- 3 轮连续流程 + 目标分变化
- peg 重新生成逻辑
- 轮间球三选一 UI
- 盘面改造二选一 UI + 生效逻辑
- 通过/失败结果展示
- **产出**：3 轮完整可玩

### Day 4：手感调优 + PC 适配
- 窗口/全屏切换
- 分辨率缩放测试
- 物理参数调优（弹性/重力/磁力）
- 边界修复（球飞出、卡住、无限弹）
- "再来一局"按钮
- **产出**：可内部试玩的完整原型

### Day 5：交付 + Steam 预留
- Windows/Linux 导出
- 15 秒录屏
- GodotSteam addon 安装（仅预留，不接入功能）
- 试玩反馈回收
- **产出**：可执行文件 + 录屏

---

## 六、不做（本版）

- Steam SDK 实际接入（仅预留 addon）
- 音效、音乐
- 美术精灵图（纯几何 CircleShape2D + modulate 着色）
- 粒子特效
- 本地存档
- 多语言
- 敌人/Boss/遗物/职业/商店

---

## 七、风险 & 缓解

| 风险 | 概率 | 缓解 |
|------|------|------|
| Godot 2D 物理行为与 Canvas 手写差异大 | 中 | Day1 先做铁球单球测试，对比 Canvas 原型手感 |
| 穿透球在 Godot 中实现复杂 | 中 | 用 collision_layer 临时禁用替代 pierced Set |
| GodotSteam 兼容性 | 低 | Day5 仅安装不做接入，不阻塞交付 |
| 1920×1080 盘面太大，peg 间距难把握 | 低 | 先做 720×1080 盘面区域，peg 半径 24px |
| Windows 初次导出配置问题 | 中 | Day5 留半天排查导出模板/rcedit |

---

## 八、Canvas 原型保留价值

`/home/kenny/orb_foundry/archive/orb-foundry-mvp.html`

- 核心逻辑参考：4 种球行为、球袋算法、轮次判定
- JSON 配置格式：ball_config / round_config / peg_layout
- 物理参数初始值：重量/弹性/磁力范围
- 可用浏览器直接对比验证 Godot 版本行为
