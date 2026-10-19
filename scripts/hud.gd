class_name SurvivorHUD
extends CanvasLayer

signal upgrade_chosen(index: int)
signal restart_requested

const INK := Color("e5edf6")
const MUTED := Color("9baec5")
const MINT := Color("65e4cb")
var wave_label: Label
var hp_label: Label
var stats_label: Label
var remaining_label: Label
var xp_label: Label
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var overlay: Control
var modal_title: Label
var modal_subtitle: Label
var damage_button: Button
var speed_button: Button
var restart_button: Button
var result_label: Label

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_panel(root, Rect2(24, 18, 1232, 78), Color("111e30"))
	_label(root, "FIVE WAVES", Rect2(44, 28, 190, 24), 23, MINT)
	_label(root, "五波生存", Rect2(45, 59, 180, 22), 15, MUTED)
	wave_label = _label(root, "", Rect2(252, 28, 200, 30), 24, INK)
	remaining_label = _label(root, "", Rect2(252, 61, 310, 22), 14, MUTED)
	hp_label = _label(root, "", Rect2(612, 30, 230, 24), 17, INK)
	hp_bar = _bar(root, Rect2(612, 65, 242, 7), MINT)
	stats_label = _label(root, "", Rect2(906, 28, 330, 48), 17, INK)
	_panel(root, Rect2(24, 650, 1232, 52), Color("111e30"))
	_label(root, "↑ ↓ ← →  移動   ·   自動瞄準範圍內最近敵人", Rect2(44, 664, 590, 24), 16, MUTED)
	xp_label = _label(root, "", Rect2(690, 655, 540, 22), 14, INK)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	xp_bar = _bar(root, Rect2(720, 685, 510, 5), Color("eebc70"))

	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.035, 0.06, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	_panel(overlay, Rect2(244, 182, 792, 356), Color("142237"))
	modal_title = _label(overlay, "", Rect2(284, 213, 712, 48), 34, INK)
	modal_subtitle = _label(overlay, "", Rect2(284, 272, 712, 42), 17, MUTED)
	damage_button = _button(overlay, Rect2(284, 340, 340, 126))
	speed_button = _button(overlay, Rect2(656, 340, 340, 126))
	damage_button.pressed.connect(func(): upgrade_chosen.emit(0))
	speed_button.pressed.connect(func(): upgrade_chosen.emit(1))
	restart_button = _button(overlay, Rect2(284, 429, 712, 62))
	restart_button.text = "↑  重新開始"
	restart_button.pressed.connect(func(): restart_requested.emit())
	result_label = _label(overlay, "", Rect2(284, 331, 712, 80), 20, INK)
	overlay.hide()

func update_status(wave: int, spawned: int, total: int, living: int, player: SurvivorPlayer, level: int, xp: int, goal: int) -> void:
	wave_label.text = "第 %d / 5 波" % wave
	remaining_label.text = "存活 %02d   ·   尚待出現 %02d" % [living, total - spawned]
	hp_label.text = "生命  %d / %d" % [player.hp, player.max_hp]
	hp_bar.value = float(player.hp) / player.max_hp * 100.0
	stats_label.text = "攻擊力  %d\n攻速  %.2f 發 / 秒" % [player.damage, 1.0 / player.fire_interval]
	xp_label.text = "等級 %02d   ·   擊敗敵人獲得經驗   %d / %d" % [level, xp, goal]
	xp_bar.value = float(xp) / goal * 100.0

func show_upgrade(level: int, damage: int, interval: float) -> void:
	modal_title.text = "等級 %d  /  選擇強化" % level
	modal_subtitle.text = "戰鬥已暫停。按 ← 或 → 選擇，也可以點選卡片。"
	damage_button.text = "←  攻擊力\n%d → %d\n每發子彈傷害 +8" % [damage, damage + 8]
	speed_button.text = "→  攻擊速度\n%.2f → %.2f 發 / 秒\n射擊頻率提高 20%%" % [1.0 / interval, 1.2 / interval]
	damage_button.show()
	speed_button.show()
	restart_button.hide()
	result_label.hide()
	overlay.show()

func show_result(won: bool, kills: int, seconds: float, level: int) -> void:
	modal_title.text = "五波完成，生存成功！" if won else "本次生存結束"
	modal_subtitle.text = "按 ↑ 或點選按鈕重新開始；也可以停留在此畫面。"
	result_label.text = "擊敗敵人  %d     /     等級  %d\n戰鬥時間  %02d:%02d" % [kills, level, int(seconds) / 60, int(seconds) % 60]
	result_label.show()
	damage_button.hide()
	speed_button.hide()
	restart_button.show()
	overlay.show()

func hide_modal() -> void:
	overlay.hide()

func _panel(parent: Node, rect: Rect2, color: Color) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(color))
	parent.add_child(panel)
	return panel

func _label(parent: Node, content: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = content
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _bar(parent: Node, rect: Rect2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = rect.position
	bar.size = rect.size
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _style(Color("263347")))
	bar.add_theme_stylebox_override("fill", _style(color))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)
	return bar

func _button(parent: Node, rect: Rect2) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_stylebox_override("normal", _style(Color("22364b")))
	button.add_theme_stylebox_override("hover", _style(Color("31566a")))
	button.add_theme_stylebox_override("pressed", _style(Color("376d72")))
	parent.add_child(button)
	return button

func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	return style
