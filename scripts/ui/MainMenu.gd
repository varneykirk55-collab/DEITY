extends Control

var _preview: Node3D
var _yaw: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_bg()
	_build_ui()


func _build_bg() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var vp_c := SubViewportContainer.new()
	vp_c.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_c.stretch = true
	vp_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vp_c)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = Vector2i(1600, 900)
	vp_c.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.07, 0.11, 0.18)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.45, 0.55, 0.7)
	e.ambient_light_energy = 0.7
	env.environment = e
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	sun.light_energy = 1.2
	world.add_child(sun)
	_preview = Node3D.new()
	world.add_child(_preview)
	_mini_island(_preview)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 10, 18)
	cam.current = true
	world.add_child(cam)
	cam.look_at(Vector3(0, 1, 0), Vector3.UP)


func _mini_island(root: Node3D) -> void:
	var ground := MeshInstance3D.new()
	var st := SphereMesh.new()
	st.radius = 6.0
	st.height = 4.2
	st.radial_segments = 16
	st.rings = 10
	ground.mesh = st
	ground.material_override = Gfx.mat(Color(0.32, 0.58, 0.24))
	ground.position.y = -1.2
	root.add_child(ground)
	var water := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 7.2
	wm.bottom_radius = 7.2
	wm.height = 0.4
	water.mesh = wm
	water.material_override = Gfx.mat(Color(0.15, 0.45, 0.75, 0.85), 0.15, 0.2, Color(0, 0, 0), 0.0, true)
	water.position.y = 0.0
	root.add_child(water)
	for i in range(8):
		var t := MeshInstance3D.new()
		t.mesh = Gfx.cone
		t.material_override = Gfx.mat(Color(0.16, 0.42, 0.18))
		t.scale = Vector3(1.2, 2.4, 1.2)
		var a := float(i) / 8.0 * TAU
		t.position = Vector3(cos(a) * 3.2, 1.2, sin(a) * 3.2)
		root.add_child(t)
	var hut := MeshInstance3D.new()
	hut.mesh = Gfx.box
	hut.material_override = Gfx.mat(Color(0.55, 0.4, 0.22))
	hut.scale = Vector3(1.4, 1.1, 1.4)
	hut.position = Vector3(0.6, 0.9, 0.4)
	root.add_child(hut)
	var mt := MeshInstance3D.new()
	mt.mesh = Gfx.cone
	mt.material_override = Gfx.mat(Color(0.55, 0.55, 0.52))
	mt.scale = Vector3(4.5, 6.0, 4.5)
	mt.position = Vector3(-2.2, 2.4, -2.0)
	root.add_child(mt)


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := UiKit.panel(0.88)
	card.custom_minimum_size = Vector2(460, 520)
	center.add_child(card)
	var v := UiKit.vbox(12)
	card.add_child(v)
	var title := UiKit.label("DEITY", 56, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(title)
	v.add_child(UiKit.label("Create worlds. Introduce humanity.\nWatch civilizations live — or unmake them.", 15, UiKit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var nb := UiKit.button("New World")
	nb.pressed.connect(_new_world)
	v.add_child(nb)
	var lb := UiKit.button("Load World")
	lb.pressed.connect(_load_world)
	v.add_child(lb)
	var sb := UiKit.button("Settings")
	sb.pressed.connect(_settings)
	v.add_child(sb)
	var eb := UiKit.button("Exit")
	eb.pressed.connect(func() -> void: get_tree().quit())
	v.add_child(eb)
	v.add_child(UiKit.label("Godot 4.7.2  •  v%s" % GameState.VERSION, 12, Color(0.5, 0.55, 0.6), HORIZONTAL_ALIGNMENT_CENTER))


func _new_world() -> void:
	GameState.load_path = ""
	get_tree().change_scene_to_file("res://scenes/ui/WorldCreate.tscn")


func _load_world() -> void:
	var overlay := PauseMenu.new()
	# Reuse list; intercept
	add_child(overlay)
	overlay.resumed.connect(overlay.queue_free)
	overlay.quit_menu.connect(overlay.queue_free)
	overlay.save_requested.connect(func() -> void: pass)
	overlay.load_requested.connect(func() -> void:
		var fn := overlay.selected_save()
		if fn == "":
			return
		GameState.load_path = fn
		get_tree().change_scene_to_file("res://scenes/game/GameWorld.tscn")
	)


func _settings() -> void:
	var overlay := PauseMenu.new()
	add_child(overlay)
	overlay.resumed.connect(overlay.queue_free)
	overlay.quit_menu.connect(overlay.queue_free)


func _process(delta: float) -> void:
	if _preview:
		_yaw += delta * 0.18
		_preview.rotation.y = _yaw
