class_name HUD
extends CanvasLayer

signal tool_picked(id: int)
signal time_picked(scale: float, paused: bool)
signal pause_requested
signal biome_picked(b: int)
signal animal_picked(s: String)
signal brush_changed(size: float, strength: float)

var world: Node
var tool_buttons: Dictionary = {}
var time_lbl: Label
var pop_lbl: Label
var civ_lbl: Label
var inspect_box: PanelContainer
var inspect_text: RichTextLabel
var brush_slider: HSlider
var strength_slider: HSlider
var biome_bar: HBoxContainer
var animal_bar: HBoxContainer
var hint_lbl: Label
var cat_btns: Dictionary = {}
var tool_row: HBoxContainer
var _active_cat: String = "Terrain"


func setup(p_world: Node) -> void:
	world = p_world
	layer = 20
	_build()
	show_category("Terrain")


func _root() -> Control:
	if has_node("Root"):
		return $Root
	var r := Control.new()
	r.name = "Root"
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _build() -> void:
	var host := _root()

	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", UiKit.flat(Color(0.05, 0.08, 0.14, 0.82), 0, Color(0.55, 0.45, 0.18, 0.5), 1))
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.anchor_left = 0.0
	top.anchor_right = 1.0
	top.anchor_top = 0.0
	top.anchor_bottom = 0.0
	top.offset_left = 0.0
	top.offset_right = 0.0
	top.offset_top = 0.0
	top.offset_bottom = 50.0
	host.add_child(top)
	var th := UiKit.hbox(16)
	top.add_child(th)
	var title := UiKit.label("DEITY", 22, UiKit.GOLD)
	th.add_child(title)
	time_lbl = UiKit.label("Time  0y  1x", 16, UiKit.INK)
	th.add_child(time_lbl)
	pop_lbl = UiKit.label("Humans  0", 16, UiKit.INK)
	th.add_child(pop_lbl)
	civ_lbl = UiKit.label("Civilizations  0", 16, UiKit.INK)
	th.add_child(civ_lbl)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(spacer)
	var pause_b := UiKit.button("Menu  (Esc)", 130, 34)
	pause_b.pressed.connect(func() -> void: pause_requested.emit())
	th.add_child(pause_b)

	var bottom := PanelContainer.new()
	bottom.add_theme_stylebox_override("panel", UiKit.flat(Color(0.05, 0.08, 0.14, 0.90), 0, Color(0.55, 0.45, 0.18, 0.4), 1))
	bottom.anchor_left = 0.0
	bottom.anchor_right = 1.0
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_left = 0.0
	bottom.offset_right = 0.0
	bottom.offset_top = -138.0
	bottom.offset_bottom = 0.0
	add_child(bottom)
	var bv := UiKit.vbox(4)
	bottom.add_child(bv)

	var cats := UiKit.hbox(6)
	bv.add_child(cats)
	for c in ["Terrain", "Nature", "Life", "Civilization", "Divine Powers", "Religion", "Time"]:
		var b := Button.new()
		b.text = c
		b.custom_minimum_size = Vector2(110, 28)
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_stylebox_override("normal", UiKit.flat(Color(0.12, 0.16, 0.24, 0.9), 6, Color(0.35, 0.4, 0.5), 1))
		b.add_theme_stylebox_override("hover", UiKit.flat(Color(0.2, 0.24, 0.36), 6, UiKit.GOLD, 1))
		b.add_theme_stylebox_override("pressed", UiKit.flat(Color(0.3, 0.24, 0.1), 6, UiKit.GOLD, 2))
		b.add_theme_color_override("font_color", UiKit.INK)
		var namec: String = c
		b.pressed.connect(func() -> void: show_category(namec))
		cats.add_child(b)
		cat_btns[c] = b

	tool_row = UiKit.hbox(4)
	bv.add_child(tool_row)

	var opts := UiKit.hbox(10)
	bv.add_child(opts)
	opts.add_child(UiKit.label("Brush", 12, UiKit.MUTED))
	brush_slider = HSlider.new()
	brush_slider.min_value = 1.5
	brush_slider.max_value = 22.0
	brush_slider.value = 6.0
	brush_slider.custom_minimum_size = Vector2(140, 18)
	brush_slider.value_changed.connect(_brush)
	opts.add_child(brush_slider)
	opts.add_child(UiKit.label("Strength", 12, UiKit.MUTED))
	strength_slider = HSlider.new()
	strength_slider.min_value = 0.15
	strength_slider.max_value = 1.5
	strength_slider.value = 0.7
	strength_slider.custom_minimum_size = Vector2(120, 18)
	strength_slider.value_changed.connect(_brush)
	opts.add_child(strength_slider)
	biome_bar = UiKit.hbox(3)
	opts.add_child(biome_bar)
	for i in range(1, GameState.BIOME_NAMES.size()):
		var bb := Button.new()
		bb.custom_minimum_size = Vector2(22, 22)
		bb.tooltip_text = GameState.BIOME_NAMES[i]
		bb.add_theme_stylebox_override("normal", UiKit.flat(GameState.BIOME_COLORS[i], 4, Color(0, 0, 0, 0.4), 1))
		var bi := i
		bb.pressed.connect(func() -> void: biome_picked.emit(bi))
		biome_bar.add_child(bb)
	animal_bar = UiKit.hbox(3)
	opts.add_child(animal_bar)
	for sp in ["deer", "wolf", "bear", "polar_bear", "reindeer", "lion", "zebra", "elephant", "monkey", "boar", "bison", "goat", "bird"]:
		var ab := Button.new()
		ab.text = sp.substr(0, 3)
		ab.tooltip_text = "Spawn " + sp.replace("_", " ")
		ab.custom_minimum_size = Vector2(34, 22)
		ab.add_theme_font_size_override("font_size", 10)
		var s: String = sp
		ab.pressed.connect(func() -> void: animal_picked.emit(s))
		animal_bar.add_child(ab)

	hint_lbl = UiKit.label("WASD move  •  Wheel zoom  •  RMB rotate  •  MMB pan  •  LMB use tool  •  Esc menu", 12, UiKit.MUTED)
	bv.add_child(hint_lbl)

	inspect_box = UiKit.panel(0.9)
	inspect_box.anchor_left = 1.0
	inspect_box.anchor_right = 1.0
	inspect_box.anchor_top = 0.0
	inspect_box.anchor_bottom = 0.0
	inspect_box.offset_left = -330
	inspect_box.offset_top = 58
	inspect_box.offset_right = -12
	inspect_box.offset_bottom = 310
	inspect_box.visible = false
	host.add_child(inspect_box)
	inspect_text = RichTextLabel.new()
	inspect_text.bbcode_enabled = true
	inspect_text.fit_content = true
	inspect_text.scroll_active = true
	inspect_text.custom_minimum_size = Vector2(280, 220)
	inspect_text.add_theme_font_size_override("normal_font_size", 14)
	inspect_box.add_child(inspect_text)


func show_category(cat: String) -> void:
	_active_cat = cat
	for c in tool_row.get_children():
		c.queue_free()
	tool_buttons.clear()
	var tools: Array = []
	match cat:
		"Terrain":
			tools = [
				[GameState.ToolId.RAISE, "Raise", "raise"],
				[GameState.ToolId.LOWER, "Lower", "lower"],
				[GameState.ToolId.MOUNTAIN, "Mountain", "mountain"],
				[GameState.ToolId.VALLEY, "Valley", "valley"],
				[GameState.ToolId.ISLAND, "Island", "island"],
				[GameState.ToolId.LAKE, "Lake", "lake"],
				[GameState.ToolId.RIVER, "River", "river"],
				[GameState.ToolId.PAINT, "Biome", "paint"],
				[GameState.ToolId.FOREST, "Forest", "forest"],
				[GameState.ToolId.VEGETATION, "Plants", "veg"],
				[GameState.ToolId.VOLCANO, "Volcano", "volcano"]
			]
		"Nature":
			tools = [
				[GameState.ToolId.SPAWN_TREE, "Tree", "tree"],
				[GameState.ToolId.SPAWN_ANIMAL, "Animal", "animal"],
				[GameState.ToolId.FOREST, "Forest", "forest"],
				[GameState.ToolId.VEGETATION, "Plants", "veg"],
				[GameState.ToolId.REMOVE_VEGETATION, "Clear Plants", "kill"]
			]
		"Life":
			tools = [
				[GameState.ToolId.SPAWN_HUMAN_1, "One", "human"],
				[GameState.ToolId.SPAWN_HUMAN_5, "Group", "group"],
				[GameState.ToolId.SPAWN_HUMAN_20, "Crowd", "group"],
				[GameState.ToolId.INSPECT, "Inspect", "inspect"]
			]
		"Civilization":
			tools = [
				[GameState.ToolId.INSPECT, "Inspect", "inspect"],
				[GameState.ToolId.BOOST_TECH, "Boost Tech", "tech"],
				[GameState.ToolId.ENCOURAGE, "Encourage", "boost"]
			]
		"Divine Powers":
			tools = [
				[GameState.ToolId.LIGHTNING, "Lightning", "lightning"],
				[GameState.ToolId.TORNADO, "Tornado", "tornado"],
				[GameState.ToolId.METEOR, "Meteor", "meteor"],
				[GameState.ToolId.ERUPT, "Erupt", "volcano"],
				[GameState.ToolId.KILL, "Smite", "kill"],
				[GameState.ToolId.KILL_GROUP, "Smite Area", "kill"],
				[GameState.ToolId.RAIN, "Rain", "rain"],
				[GameState.ToolId.STORM, "Storm", "storm"],
				[GameState.ToolId.SNOW, "Snow", "snow"]
			]
		"Religion":
			tools = [
				[GameState.ToolId.MIRACLE, "Miracle", "miracle"],
				[GameState.ToolId.PLAGUE, "Plague", "plague"],
				[GameState.ToolId.CURE, "Cure", "cure"],
				[GameState.ToolId.INSPECT, "Inspect", "inspect"]
			]
		"Time":
			tools = []
			_add_time_buttons()
	for t in tools:
		_add_tool(int(t[0]), str(t[1]), str(t[2]))
	biome_bar.visible = cat == "Terrain"
	animal_bar.visible = cat == "Nature"


func _add_tool(id: int, text: String, icon: String) -> void:
	var b := UiKit.tool_button(text, Gfx.icon(icon, UiKit.GOLD))
	b.pressed.connect(func() -> void: tool_picked.emit(id); _highlight(id))
	tool_row.add_child(b)
	tool_buttons[id] = b


func _add_time_buttons() -> void:
	var specs := [
		["Pause", 0.0, true, "pause"],
		["1x", 1.0, false, "play"],
		["3x", 3.0, false, "fast"],
		["8x", 8.0, false, "veryfast"]
	]
	for s in specs:
		var b := UiKit.tool_button(str(s[0]), Gfx.icon(str(s[3]), UiKit.GOLD))
		var sc := float(s[1])
		var ps := bool(s[2])
		b.pressed.connect(func() -> void: time_picked.emit(sc, ps))
		tool_row.add_child(b)


func _highlight(id: int) -> void:
	for k in tool_buttons.keys():
		var b: Button = tool_buttons[k]
		if int(k) == id:
			b.add_theme_stylebox_override("normal", UiKit.flat(Color(0.36, 0.28, 0.10, 0.96), 8, UiKit.GOLD, 2))
		else:
			b.add_theme_stylebox_override("normal", UiKit.flat(Color(0.10, 0.14, 0.22, 0.92), 8, Color(0.35, 0.40, 0.50), 1))


func _brush(_v: float) -> void:
	brush_changed.emit(brush_slider.value, strength_slider.value)


func update_stats(sim_time: float, scale: float, paused: bool, humans: int, civs: int) -> void:
	var years := sim_time * 0.055
	var ts := "PAUSE" if paused else ("%.0fx" % scale)
	time_lbl.text = "Year  %.1f    %s" % [years, ts]
	pop_lbl.text = "Humans  %d" % humans
	civ_lbl.text = "Civilizations  %d" % civs


func show_human(h: Human, civ_name: String, era_name: String) -> void:
	inspect_box.visible = true
	var inf := "yes" if h.infected else "no"
	var her := "yes" if h.heretic else "no"
	inspect_text.text = "[b]%s[/b]\nCivilization: %s\nEra: %s\nAge: %.0f\nBelief: %.0f%%\nHeretic: %s\nInfected: %s\nState: %s\n\n[i]Powers are never limited by belief.[/i]" % [
		h.human_name, civ_name, era_name, h.age, h.belief * 100.0, her, inf, str(h.state)
	]


func show_settlement(s: Settlement, civ: Civilization) -> void:
	inspect_box.visible = true
	inspect_text.text = "[b]%s[/b]\nCivilization: %s\nEra: %s\nPopulation: %d\nFood %d   Wood %d\nStone %d   Ore %d\nTech: %.0f\nFaith: %.0f%%\nTemple: %s" % [
		s.settle_name, civ.civ_name, GameState.ERA_NAMES[civ.era], s.population,
		civ.food, civ.wood, civ.stone, civ.ore, civ.tech, civ.faith * 100.0,
		"yes" if s.has_temple else "no"
	]


func hide_inspect() -> void:
	inspect_box.visible = false
