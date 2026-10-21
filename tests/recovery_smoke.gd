extends Node

var failures := 0
var checks := 0
var world: Node

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("PASS " if ok else "FAIL ", label)

func nodes(group: String) -> Array[Node]:
	return get_tree().get_nodes_in_group(group)

func fresh(mode: int, size_id: int = 0) -> void:
	if is_instance_valid(world):
		world.free()
	GameState.reset_run()
	GameState.load_path = ""
	GameState.world_mode = mode
	GameState.world_size = size_id
	GameState.world_seed = 123456
	world = load("res://scenes/game/GameWorld.tscn").instantiate()
	add_child(world)
	world.set_process(false)
	GameState.paused = true

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var menu: Node = load("res://scenes/ui/MainMenu.tscn").instantiate()
	add_child(menu)
	check(menu.get_child_count() > 0, "main menu instantiates")
	menu.free()
	var config: Node = load("res://scenes/ui/WorldCreate.tscn").instantiate()
	add_child(config)
	for mode in [0, 1]:
		config._set_mode(mode)
		check(config.mode == mode, "configuration mode %d" % mode)
	for size_id in range(3):
		config._select_world_size(size_id)
		check(config.size_id == size_id, "configuration size %d" % size_id)
	config.free()
	for size_id in range(3):
		fresh(GameState.WorldMode.GENERATED, size_id)
		check(world.terrain.grid == GameState.grid(), "generated grid size %d" % size_id)
		check(nodes("humans").is_empty(), "generated world has no humans %d" % size_id)
		check(not nodes("resources").is_empty() and not nodes("animals").is_empty(), "generated nature %d" % size_id)
		var distinct := {}
		for b in world.terrain.biomes:
			distinct[b] = true
		check(distinct.size() > 2, "combined biomes %d" % size_id)
		check(world.terrain.raycast(Vector3(0, 250, 0), Vector3.DOWN).is_finite(), "distant terrain ray %d" % size_id)
	fresh(GameState.WorldMode.EMPTY)
	check(nodes("animals").is_empty() and nodes("resources").is_empty(), "empty world has no nature")
	check(world.terrain.heights[world.terrain.idx(48, 48)] < 0, "empty world starts underwater")
	# A controlled island isolates behavior from random geography.
	world.terrain.heights.fill(2.0)
	world.terrain.biomes.fill(GameState.Biome.GRASSLAND)
	world.terrain.rebuild_all()
	var surface: Array = world.terrain.chunks[Vector2i(2, 2)].mesh.surface_get_arrays(0)
	check(surface[Mesh.ARRAY_NORMAL][0].y > 0.9, "terrain normals face up")
	var water_surface: Array = world.terrain.water.mesh.surface_get_arrays(0)
	check(water_surface[Mesh.ARRAY_NORMAL][3].y > 0.9, "water normals face up")
	var p := Vector3(0, 2, 0)
	var h: float = world.terrain.get_height(0, 0)
	world.terrain.brush(0, 0, 8, 1, "raise")
	check(world.terrain.get_height(0, 0) > h, "raise terrain")
	h = world.terrain.get_height(0, 0)
	world.terrain.brush(0, 0, 8, 1, "lower")
	check(world.terrain.get_height(0, 0) < h, "lower terrain")
	for mode in ["mountain", "valley", "island", "lake", "volcano"]:
		var before: PackedFloat32Array = world.terrain.heights.duplicate()
		world.terrain.brush(0, 0, 8, 2, mode)
		check(before != world.terrain.heights, "terrain brush " + mode)
	world.terrain.brush(0, 0, 8, 1, "paint", GameState.Biome.DESERT)
	check(world.terrain.get_biome(0, 0) == GameState.Biome.DESERT, "paint biome")
	world.terrain.dirty.clear()
	world.terrain._mark(16, 16)
	check(world.terrain.dirty.size() == 4, "chunk corner dirties all four neighbors")
	world.terrain.heights.fill(2)
	world.terrain.biomes.fill(GameState.Biome.GRASSLAND)
	world.paint_forest(p, 6)
	world.paint_vegetation(p, 6)
	world._spawn_resource("stone", p + Vector3(3, 0, 0))
	check(nodes("resources").size() > 1 and world.veg_root.get_child_count() > 0, "forest and vegetation")
	var resource: Node = nodes("resources")[0]
	var resource_count := nodes("resources").size()
	resource.gather()
	check(nodes("resources").size() == resource_count and resource.is_inside_tree(), "gather preserves source")
	world.spawn_humans(p, 5)
	world._form_civs()
	check(nodes("humans").size() == 5 and world.civs.size() == 1, "humans form civilization")
	var c: Civilization = world.civs.values()[0]
	var s: Settlement = nodes("settlements")[0]
	var human: Human = nodes("humans")[0]
	var old_pos := human.position
	human._move_towards(p + Vector3(8, 0, 0), 0.1, world)
	check(human.position != old_pos and human.position.y > 0, "human land movement")
	var wood_before := c.wood
	human.target_node = resource
	human.state = GameState.HumanState.GATHER
	human.action_cd = 0
	human._arrive(world)
	check(c.wood == wood_before + 1, "human resource delivery")
	c.wood = 30
	c.stone = 30
	s.next_kind = Building.Kind.HUT
	for i in range(3):
		world.contribute_build(c.id, p)
	check(nodes("buildings").size() == 1, "construction completes")
	c.food = 30
	world._tick_repro()
	check(nodes("humans").size() == 6 and nodes("humans")[-1].age <= 4, "human birth has child age")
	for era in range(7):
		c.tech = GameState.ERA_TECH[era]
		world._tick_sim(0.01)
		check(c.era == era and nodes("buildings")[0].era == era, "era progression %d" % era)
	world.cast_plague(p, 100)
	human.infect_t = 8
	world.cast_plague(p, 100)
	check(human.infect_t == 8, "repeated plague does not reset infection")
	world.cast_cure(p, 100)
	check(nodes("humans").all(func(n): return not n.infected), "cure stops infection")
	world.cast_miracle(p)
	check(human.belief > 0.1, "miracle raises belief")
	s.belief_avg = 0.9
	check(world._desired_building(c, s, world._civ_buildings(c.id)) == Building.Kind.TEMPLE, "belief encourages temple")
	world._spawn_building(c, s, Building.Kind.TEMPLE, p)
	var temple: Building = nodes("temples")[0]
	human.heretic = true
	human.state = GameState.HumanState.REBEL
	human.target_node = temple
	human.action_cd = 0
	human._arrive(world)
	check(temple.burning, "rebel burns temple")
	world._update_settlements()
	check(not s.has_temple, "burning temple no longer counts as active")
	world.spawn_animal("deer", p)
	world.spawn_animal("deer", p + Vector3(1, 0, 0))
	for animal in nodes("animals"):
		animal.age = 3
		animal.mate_cd = 0
	world._tick_animal_repro()
	check(nodes("animals").size() == 3, "animal reproduction")
	for animal in nodes("animals"):
		animal.kill()
	world._tick_animal_repro()
	check(nodes("animals").is_empty(), "extinction does not respawn animals")
	world.spawn_animal("deer", p)
	check(nodes("animals").size() == 1, "manual reintroduction")
	human.target_node = nodes("animals")[0]
	human.action_cd = 0
	human.state = GameState.HumanState.HUNT
	var food_before := c.food
	human._arrive(world)
	check(nodes("animals").is_empty() and c.food > food_before, "hunting delivers food")
	# Save through real JSON, then load from a different starting map size.
	GameState.world_name = "__recovery_smoke__"
	human.infect()
	human.infect_t = 7.5
	s.build_progress = 1.5
	world.spawn_animal("goat", p)
	world.add_volcano_visual(p)
	var saved_terrain: PackedFloat32Array = world.terrain.heights.duplicate()
	var saved_vegetation: int = world.veg_root.get_child_count()
	world._save()
	var data := SaveLoad.read_save("__recovery_smoke__.deity.json")
	check(not data.is_empty(), "save writes readable JSON")
	world.free()
	GameState.world_size = GameState.WorldSize.LARGE
	GameState.load_path = "__recovery_smoke__.deity.json"
	world = load("res://scenes/game/GameWorld.tscn").instantiate()
	add_child(world)
	world.set_process(false)
	check(world.terrain.grid == 96 and world.terrain.chunks.size() == 36, "load rebuilds correct size geometry")
	check(world.terrain.heights == saved_terrain, "terrain round trip")
	check(nodes("humans")[0].infect_t == 7.5, "infection progress round trip")
	check(nodes("settlements")[0].build_progress == 1.5, "construction progress round trip")
	check(nodes("temples")[0].burning, "burning building round trip")
	check(world.veg_root.get_child_count() == saved_vegetation, "vegetation round trip")
	check(nodes("animals").size() == 1 and nodes("resources").size() == resource_count, "wildlife and resources round trip")
	check(world.civs.values()[0].era == GameState.Era.MODERN, "civilization round trip")
	GameState.paused = false
	world._toggle_pause()
	check(GameState.paused, "pause menu pauses")
	world._toggle_pause()
	check(not GameState.paused, "resume restores running state")
	GameState.paused = true
	for kind in ["rain", "storm", "snow"]:
		world.weather.summon(kind)
		check(world.weather.local_override == kind, "weather power " + kind)
	world.cast_lightning(Vector3(30, 2, 30))
	world.cast_erupt(Vector3(30, 2, 30))
	world.cast_tornado(Vector3(30, 2, 30))
	world.cast_meteor(Vector3(30, 2, 30))
	check(world.effects.size() == 2, "meteor and tornado created")
	for i in range(210):
		world._tick_effects(0.05)
	check(world.effects.is_empty(), "temporary powers expire")
	world.cast_plague(p, 1000)
	for i in range(2400):
		world._tick_sim(0.05)
	check(nodes("humans").is_empty(), "plague can extinguish civilization")
	# Corpses must clean up after leaving the live-human group.
	for n in world.entity_root.get_children():
		if n is Human:
			n.tick(3, world)
	await get_tree().process_frame
	check(world.entity_root.get_children().filter(func(n): return n is Human).is_empty(), "dead-human cleanup")
	world.free()
	GameState.world = null
	DirAccess.remove_absolute(SaveLoad.path_for("__recovery_smoke__"))
	await get_tree().process_frame
	print("RESULT %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
