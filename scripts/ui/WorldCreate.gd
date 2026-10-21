extends Control

var mode: int = GameState.WorldMode.GENERATED
var size_id: int = GameState.WorldSize.MEDIUM
var selected: Dictionary = {}
var seed_edit: LineEdit
var name_edit: LineEdit
var mode_btns: Dictionary = {}
var size_btns: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.offset_left = 40
	sc.offset_right = -40
	sc.offset_top = 24
	sc.offset_bottom = -24
	add_child(sc)
	var v := UiKit.vbox(14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	v.add_child(UiKit.label("CREATE WORLD", 36, UiKit.GOLD))
	v.add_child(UiKit.label("Humans are never created automatically. You introduce them.", 14, UiKit.MUTED))

	var names := UiKit.hbox(10)
	names.add_child(UiKit.label("Name", 14, UiKit.MUTED))
	name_edit = LineEdit.new()
	name_edit.text = Names.world(RandomNumberGenerator.new())
	name_edit.custom_minimum_size = Vector2(260, 32)
	names.add_child(name_edit)
	names.add_child(UiKit.label("Seed", 14, UiKit.MUTED))
	seed_edit = LineEdit.new()
	seed_edit.placeholder_text = "random"
	seed_edit.custom_minimum_size = Vector2(140, 32)
	names.add_child(seed_edit)
	v.add_child(names)

	v.add_child(UiKit.label("Starting Mode", 20, UiKit.INK))
	var modes := UiKit.hbox(12)
	v.add_child(modes)
	mode_btns[GameState.WorldMode.GENERATED] = _card(modes, "Generated World", "Procedural continents, biomes, forests, wildlife, and resources. No humans.")
	mode_btns[GameState.WorldMode.EMPTY] = _card(modes, "Empty World", "Open ocean. Raise islands, mountains, and forests yourself. Same divine powers.")
	mode_btns[GameState.WorldMode.GENERATED].pressed.connect(func() -> void: _set_mode(GameState.WorldMode.GENERATED))
	mode_btns[GameState.WorldMode.EMPTY].pressed.connect(func() -> void: _set_mode(GameState.WorldMode.EMPTY))

	v.add_child(UiKit.label("World Size", 20, UiKit.INK))
	var sizes := UiKit.hbox(12)
	v.add_child(sizes)
	size_btns[GameState.WorldSize.SMALL] = _card(sizes, "Small", "Compact disc. Fast and intimate.")
	size_btns[GameState.WorldSize.MEDIUM] = _card(sizes, "Medium", "Default living world.")
	size_btns[GameState.WorldSize.LARGE] = _card(sizes, "Large", "Wide continents. Heavier simulation.")
	size_btns[GameState.WorldSize.SMALL].pressed.connect(func() -> void: _select_world_size(GameState.WorldSize.SMALL))
	size_btns[GameState.WorldSize.MEDIUM].pressed.connect(func() -> void: _select_world_size(GameState.WorldSize.MEDIUM))
	size_btns[GameState.WorldSize.LARGE].pressed.connect(func() -> void: _select_world_size(GameState.WorldSize.LARGE))

	v.add_child(UiKit.label("Environments  (combine freely — paint over them in-game)", 20, UiKit.INK))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)
	for i in range(1, GameState.BIOME_NAMES.size()):
		var cb := CheckBox.new()
		cb.text = GameState.BIOME_NAMES[i]
		cb.add_theme_color_override("font_color", UiKit.INK)
		var on := i in [GameState.Biome.ARCTIC, GameState.Biome.TEMPERATE, GameState.Biome.GRASSLAND, GameState.Biome.TROPICAL, GameState.Biome.MOUNTAINOUS]
		cb.button_pressed = on
		selected[i] = on
		var bi := i
		cb.toggled.connect(func(val: bool) -> void: selected[bi] = val)
		grid.add_child(cb)

	var row := UiKit.hbox(12)
	var back := UiKit.button("Back", 160, 44)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))
	row.add_child(back)
	var go := UiKit.button("Create World", 260, 44)
	go.pressed.connect(_create)
	row.add_child(go)
	v.add_child(row)
	_set_mode(mode)
	_select_world_size(size_id)


func _card(parent: Control, title: String, body: String) -> Button:
	var b := Button.new()
	b.text = title + "\n" + body
	b.custom_minimum_size = Vector2(280, 90)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiKit._style_button(b)
	b.add_theme_font_size_override("font_size", 14)
	parent.add_child(b)
	return b


func _set_mode(m: int) -> void:
	mode = m
	_glow(mode_btns, m)


func _select_world_size(s: int) -> void:
	size_id = s
	_glow(size_btns, s)


func _glow(dict: Dictionary, active: int) -> void:
	for k in dict.keys():
		var b: Button = dict[k]
		if int(k) == active:
			b.add_theme_stylebox_override("normal", UiKit.flat(Color(0.28, 0.22, 0.08, 0.95), 10, UiKit.GOLD, 2))
		else:
			b.add_theme_stylebox_override("normal", UiKit.flat(Color(0.12, 0.18, 0.30, 0.95), 10, UiKit.GOLD_DIM, 2))


func _create() -> void:
	GameState.reset_run()
	GameState.world_mode = mode
	GameState.world_size = size_id
	GameState.world_name = name_edit.text.strip_edges()
	if GameState.world_name == "":
		GameState.world_name = "New World"
	var biomes: Array = []
	for k in selected.keys():
		if selected[k]:
			biomes.append(int(k))
	if biomes.is_empty():
		biomes = [GameState.Biome.GRASSLAND, GameState.Biome.TEMPERATE]
	GameState.biomes_selected = biomes
	if seed_edit.text.strip_edges() == "":
		GameState.world_seed = randi()
	else:
		if seed_edit.text.is_valid_int():
			GameState.world_seed = int(seed_edit.text)
		else:
			GameState.world_seed = seed_edit.text.hash()
	GameState.load_path = ""
	get_tree().change_scene_to_file("res://scenes/game/GameWorld.tscn")
