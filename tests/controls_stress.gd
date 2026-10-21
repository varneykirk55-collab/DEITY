extends Node
var failures := 0
var checks := 0
var world: Node
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS " if ok else "FAIL ", label)
func mouse(button: int, pressed: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = pressed
	return e
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	GameState.world_mode = GameState.WorldMode.EMPTY
	GameState.world_size = GameState.WorldSize.LARGE
	GameState.world_seed = 42
	world = load("res://scenes/game/GameWorld.tscn").instantiate()
	add_child(world)
	world.set_process(false)
	world.terrain.heights.fill(2)
	world.terrain.biomes.fill(GameState.Biome.GRASSLAND)
	GameState.paused = true
	var cam: GodCamera = world.cam
	var initial := cam.distance
	cam._unhandled_input(mouse(MOUSE_BUTTON_WHEEL_UP, true))
	check(cam.distance < initial, "wheel zoom")
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(30, 15)
	var yaw := cam.yaw
	cam._unhandled_input(mouse(MOUSE_BUTTON_RIGHT, true))
	cam._unhandled_input(motion)
	cam._unhandled_input(mouse(MOUSE_BUTTON_RIGHT, false))
	check(cam.yaw != yaw, "right mouse rotation")
	var pos := cam.position
	cam._unhandled_input(mouse(MOUSE_BUTTON_MIDDLE, true))
	cam._unhandled_input(motion)
	cam._unhandled_input(mouse(MOUSE_BUTTON_MIDDLE, false))
	check(cam.position != pos, "middle mouse pan")
	for key in [KEY_W, KEY_A, KEY_S, KEY_D]:
		pos = cam.position
		var e := InputEventKey.new()
		e.keycode = key
		e.physical_keycode = key
		e.pressed = true
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await get_tree().process_frame
		cam._process(0.1)
		var release := e.duplicate() as InputEventKey
		release.pressed = false
		Input.parse_input_event(release)
		Input.flush_buffered_events()
		check(cam.position != pos, "movement key %d" % key)
	world.hud.show_category("Life")
	world.hud.tool_buttons[GameState.ToolId.SPAWN_HUMAN_20].pressed.emit()
	check(world.tools.tool == GameState.ToolId.SPAWN_HUMAN_20, "toolbar signal selects tool")
	world.tools.hover = Vector3(0, 2, 0)
	world.tools.hover_valid = true
	world.tools._use(true)
	check(get_tree().get_nodes_in_group("humans").size() == 20, "placement tool spawns crowd")
	world.hud.time_picked.emit(8.0, false)
	check(GameState.time_scale == 8 and not GameState.paused, "8x speed signal")
	world.hud.time_picked.emit(0.0, true)
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	world._unhandled_input(space)
	check(not GameState.paused and GameState.time_scale == 8, "Space resumes selected speed")
	GameState.paused = true
	world.paint_forest(Vector3(0, 2, 0), 5)
	world.paint_vegetation(Vector3(0, 2, 0), 5)
	world.remove_vegetation(Vector3(0, 2, 0), 20)
	check(get_tree().get_nodes_in_group("resources").is_empty() and world.veg_root.get_child_count() == 0, "clear vegetation tool")
	world._spawn_resource("wood", Vector3(2, 2, 0))
	world._spawn_resource("stone", Vector3(-2, 2, 0))
	world._form_civs()
	var civ: Civilization = world.civs.values()[0]
	for h in get_tree().get_nodes_in_group("humans"):
		h.heretic = false
		h.belief = 0.7
	var before := Time.get_ticks_msec()
	for i in range(2400):
		world._tick_sim(0.05)
		if i % 200 == 0:
			await get_tree().process_frame
	check(get_tree().get_nodes_in_group("buildings").size() > 0, "autonomous gathering and construction over 120 simulated seconds")
	check(civ.tech > 0 and civ.era > 0, "autonomous era advancement")
	print("TIMING autonomous 120s simulation: ", Time.get_ticks_msec() - before, " ms")
	var h: Human = get_tree().get_nodes_in_group("humans")[0]
	h.age = h.lifespan
	h.tick(0.1, world)
	check(h.dead, "natural aging and death")
	world.spawn_humans(Vector3(40, 2, 0), 20)
	world._form_civs()
	check(world.civs.size() == 2, "separate civilization identity")
	var other: Civilization = world.civs.values()[1]
	civ.set_rel(other.id, GameState.Rel.HOSTILE)
	other.set_rel(civ.id, GameState.Rel.HOSTILE)
	world._flag_warriors(civ.id)
	var fighter: Human = get_tree().get_nodes_in_group("humans")[0]
	check(world.civ_at_war(civ.id) and world.nearest_enemy(fighter) != null, "war targets hostile civilization")
	var s: Settlement = world._civ_settlement(civ.id)
	world._spawn_building(civ, s, Building.Kind.TEMPLE, s.position)
	var members: Array = get_tree().get_nodes_in_group("humans").filter(func(n): return n.civ_id == civ.id)
	for n in members:
		n.heretic = true
	world._update_settlements()
	check(members.all(func(n): return n.state == GameState.HumanState.REBEL), "majority heresy triggers rebellion")
	members[-1].heretic = false
	members[-1].position = members[0].position
	for i in range(100):
		world._tick_heretics()
	check(members[-1].heretic, "heretic recruitment spreads")
	# Bounded stress, not a claim of unlimited population or Windows FPS.
	world.spawn_humans(Vector3(-40, 2, 0), 200)
	world._form_civs()
	before = Time.get_ticks_msec()
	GameState.paused = false
	GameState.time_scale = 8
	for i in range(120):
		world._process(1.0 / 60.0)
		if i % 10 == 0:
			await get_tree().process_frame
	check(get_tree().get_nodes_in_group("humans").size() >= 200, "200+ humans survive bounded 8x stress")
	print("TIMING 120 frames at 8x with 200+ humans: ", Time.get_ticks_msec() - before, " ms")
	world.free()
	GameState.world = null
	await get_tree().process_frame
	print("RESULT %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
