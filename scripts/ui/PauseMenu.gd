class_name PauseMenu
extends CanvasLayer

signal resumed
signal save_requested
signal load_requested
signal quit_menu
signal settings_changed

var panel: PanelContainer
var saves_list: ItemList
var vol: HSlider
var sens: HSlider
var full: CheckButton


func _ready() -> void:
	layer = 40
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and not e.pressed:
			pass
	)
	add_child(dim)
	panel = UiKit.panel(0.95)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -240
	panel.offset_right = 240
	panel.offset_top = -280
	panel.offset_bottom = 280
	add_child(panel)
	var v := UiKit.vbox(10)
	panel.add_child(v)
	v.add_child(UiKit.label("PAUSED", 28, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var r := UiKit.button("Resume", 360, 40)
	r.pressed.connect(func() -> void: resumed.emit())
	v.add_child(r)
	var s := UiKit.button("Save World", 360, 40)
	s.pressed.connect(func() -> void: save_requested.emit())
	v.add_child(s)
	v.add_child(UiKit.label("Load World", 14, UiKit.MUTED))
	saves_list = ItemList.new()
	saves_list.custom_minimum_size = Vector2(360, 90)
	saves_list.item_activated.connect(func(_i: int) -> void: load_requested.emit())
	v.add_child(saves_list)
	var ld := UiKit.button("Load Selected", 360, 36)
	ld.pressed.connect(func() -> void: load_requested.emit())
	v.add_child(ld)
	v.add_child(UiKit.label("Settings", 16, UiKit.GOLD))
	var row := UiKit.hbox(8)
	row.add_child(UiKit.label("Volume", 13, UiKit.MUTED))
	vol = HSlider.new()
	vol.min_value = 0
	vol.max_value = 1
	vol.step = 0.05
	vol.value = GameState.master_volume
	vol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vol.value_changed.connect(func(val: float) -> void:
		GameState.master_volume = val
		GameState.apply_display()
		GameState.save_settings()
		settings_changed.emit()
	)
	row.add_child(vol)
	v.add_child(row)
	var row2 := UiKit.hbox(8)
	row2.add_child(UiKit.label("Look sens", 13, UiKit.MUTED))
	sens = HSlider.new()
	sens.min_value = 0.3
	sens.max_value = 2.5
	sens.step = 0.05
	sens.value = GameState.mouse_sensitivity
	sens.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sens.value_changed.connect(func(val: float) -> void:
		GameState.mouse_sensitivity = val
		GameState.save_settings()
	)
	row2.add_child(sens)
	v.add_child(row2)
	full = CheckButton.new()
	full.text = "Fullscreen"
	full.button_pressed = GameState.fullscreen
	full.toggled.connect(func(on: bool) -> void:
		GameState.fullscreen = on
		GameState.apply_display()
		GameState.save_settings()
	)
	v.add_child(full)
	var q := UiKit.button("Exit to Main Menu", 360, 40)
	q.pressed.connect(func() -> void: quit_menu.emit())
	v.add_child(q)
	refresh_saves()


func refresh_saves() -> void:
	saves_list.clear()
	var sl: Array = SaveLoad.list_saves()
	for p in sl:
		saves_list.add_item(str(p))


func selected_save() -> String:
	var i := saves_list.get_selected_items()
	if i.is_empty():
		if saves_list.item_count > 0:
			return saves_list.get_item_text(0)
		return ""
	return saves_list.get_item_text(i[0])
