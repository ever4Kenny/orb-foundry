# Codex Task: ball_select 卡死修复

## 问题
球选择面板有 3 个按钮，但 `BallBag.draw(3)` 只随机抽 3 颗可用球。
当剩余可用球 <3 时，空按钮显示 "-" 且 disabled。
如果玩家想要的球没被抽到，无法选择 → 卡死。

## 修复（改 scripts/ui/ball_select.gd）

### 1. `_draw_options()` 改为显示所有可用球
不要随机抽 3 颗。改为：
```gdscript
func _draw_options() -> void:
    drawn_entries = BallBag.get_all_available()  # 新方法，返回所有未使用的 entry
    for i in range(option_buttons.size()):
        var button := option_buttons[i]
        if i >= drawn_entries.size():
            button.visible = false   # 多余的按钮隐藏
            continue
        button.visible = true
        var ball_id := str(drawn_entries[i].get("id", ""))
        var cfg: Dictionary = ball_lookup.get(ball_id, {})
        button.text = "%s  %s\n%s" % ["●", str(cfg.get("name", ball_id)), str(cfg.get("desc", ""))]
        button.modulate = Color(cfg.get("color", "#ffffff"))
        button.disabled = false
```

### 2. BallBag 加 `get_all_available()` 方法
在 `scripts/ball_bag.gd` 中加：
```gdscript
func get_all_available() -> Array:
    return _entries.filter(func(e): return not e.used)
```
此方法不 emit 信号，不消耗球，不洗牌。

### 3. `_on_option_pressed` 加容错
如果 `BallBag.use_ball(ball_id)` 返回 false（理论上不会，但兜底）：
打印 push_error 并重新 `_draw_options()`。不要静默卡死。

## 验收
```bash
cd /home/kenny/orb_foundry/godot
./Godot_v4.6-stable_linux.x86_64 --headless --quit 2>&1  # 零 ERROR
```

## 不要改
- 其他文件
- project.godot
- JSON 配置
