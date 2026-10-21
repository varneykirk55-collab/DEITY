extends Node3D
## Living miniature world. The player is omnipotent; civilizations act on their own.

var terrain: TerrainWorld
var cam: GodCamera
var weather: WeatherFx
var fx: DivineFX
var hud: HUD
var tools: ToolController
var pause_ui: PauseMenu
var pause_open: bool = false
var _paused_before_menu: bool = false

var civs: Dictionary = {} # id -> Civilization
var rng := RandomNumberGenerator.new()
var effects: Array = [] # tornado/meteor nodes
var floaters: Array = []
var veg_root: Node3D
var entity_root: Node3D
var sim_acc: float = 0.0
var form_acc: float = 0.0
var war_acc: float = 0.0
var plague_acc: float = 0.0
var repro_acc: float = 0.0
var env_node: WorldEnvironment
var sun: DirectionalLight3D


func _ready() -> void:
	GameState.world = self
	rng.seed = GameState.world_seed if GameState.world_seed != 0 else randi()
	_setup_env()
	cam = GodCamera.new()
	add_child(cam)
	cam.configure(GameState.radius())
	terrain = TerrainWorld.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.setup(GameState.radius(), GameState.grid())
	veg_root = Node3D.new()
	veg_root.name = "Vegetation"
	add_child(veg_root)
	entity_root = Node3D.new()
	entity_root.name = "Entities"
	add_child(entity_root)
	weather = WeatherFx.new()
	add_child(weather)
	weather.setup(GameState.radius())
	fx = DivineFX.new()
	add_child(fx)
	if GameState.load_path != "":
		_load_from(GameState.load_path)
	else:
		WorldGen.generate(terrain, {
			"mode": GameState.world_mode,
			"biomes": GameState.biomes_selected
		}, rng)
		if GameState.world_mode == GameState.WorldMode.GENERATED:
			_populate_nature()
	_setup_hud()
	_setup_tools()
	_ambient_weather()


func _setup_env() -> void:
	env_node = WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.32, 0.58, 0.92)
	sm.sky_horizon_color = Color(0.78, 0.86, 0.95)
	sm.ground_bottom_color = Color(0.10, 0.12, 0.18)
	sm.ground_horizon_color = Color(0.62, 0.72, 0.82)
	sm.sun_angle_max = 30.0
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.65
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.12
	e.fog_enabled = true
	e.fog_light_color = Color(0.70, 0.82, 0.95)
	e.fog_density = 0.0009
	e.glow_enabled = true
	e.glow_intensity = 0.25
	e.ssao_enabled = false
	env_node.environment = e
	add_child(env_node)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 40, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.97, 0.90)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 260.0
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -130, 0)
	fill.light_energy = 0.22
	fill.light_color = Color(0.55, 0.65, 0.9)
	fill.shadow_enabled = false
	add_child(fill)


func _setup_hud() -> void:
	hud = HUD.new()
	add_child(hud)
	hud.setup(self)
	hud.tool_picked.connect(func(id: int) -> void: tools.set_tool(id))
	hud.time_picked.connect(func(sc: float, ps: bool) -> void:
		GameState.paused = ps
		if not ps:
			GameState.time_scale = max(sc, 0.01)
		# Keep the selected speed while paused, so Space can resume.
	)
	hud.pause_requested.connect(_toggle_pause)
	hud.biome_picked.connect(func(b: int) -> void: tools.paint_biome = b)
	hud.animal_picked.connect(func(s: String) -> void: tools.animal_species = s)
	hud.brush_changed.connect(func(sz: float, st: float) -> void:
		tools.brush_size = sz
		tools.brush_strength = st
	)


func _setup_tools() -> void:
	tools = ToolController.new()
	tools.world = self
	add_child(tools)
	tools.inspect_human.connect(func(h: Human) -> void:
		var cn := "—"
		var en := GameState.ERA_NAMES[0]
		if civs.has(h.civ_id):
			cn = civs[h.civ_id].civ_name
			en = GameState.ERA_NAMES[civs[h.civ_id].era]
		hud.show_human(h, cn, en)
	)
	tools.inspect_settlement.connect(func(s: Settlement) -> void:
		if civs.has(s.civ_id):
			hud.show_settlement(s, civs[s.civ_id])
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not pause_open:
		match event.keycode:
			KEY_SPACE:
				GameState.paused = not GameState.paused
			KEY_1:
				GameState.paused = false
				GameState.time_scale = 1.0
			KEY_2:
				GameState.paused = false
				GameState.time_scale = 3.0
			KEY_3:
				GameState.paused = false
				GameState.time_scale = 8.0


func _toggle_pause() -> void:
	pause_open = not pause_open
	if pause_open:
		_paused_before_menu = GameState.paused
		GameState.paused = true
		tools.dragging = false
		pause_ui = PauseMenu.new()
		add_child(pause_ui)
		pause_ui.resumed.connect(_toggle_pause)
		pause_ui.save_requested.connect(_save)
		pause_ui.load_requested.connect(func() -> void:
			var fn := pause_ui.selected_save()
			if fn == "":
				return
			GameState.paused = false
			GameState.load_path = fn
			get_tree().reload_current_scene()
		)
		pause_ui.quit_menu.connect(func() -> void:
			GameState.reset_run()
			get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
		)
	else:
		GameState.paused = _paused_before_menu
		if pause_ui:
			pause_ui.queue_free()
			pause_ui = null


func _process(delta: float) -> void:
	var sd := GameState.sim_delta(minf(delta, 0.25))
	GameState.sim_time += sd
	if sd > 0.0:
		var steps := maxi(1, int(ceil(sd / 0.05)))
		for _step in range(steps):
			_tick_sim(sd / steps)
			_tick_effects(sd / steps)
	_tick_floaters(delta)
	if hud:
		hud.update_stats(GameState.sim_time, GameState.time_scale, GameState.paused, get_tree().get_nodes_in_group("humans").size(), _alive_civs())
	_ambient_weather()


func _tick_sim(sd: float) -> void:
	for h in get_tree().get_nodes_in_group("humans"):
		if h is Human:
			h.tick(sd, self)
			if civs.has(h.civ_id):
				h.apply_civ_visual(civs[h.civ_id].color, civs[h.civ_id].era)
	for a in get_tree().get_nodes_in_group("animals"):
		if a is Animal:
			a.tick(sd, self)
	form_acc += sd
	if form_acc > 1.2:
		form_acc = 0.0
		_form_civs()
		_update_settlements()
	war_acc += sd
	if war_acc > 2.5:
		war_acc = 0.0
		_tick_war()
	plague_acc += sd
	if plague_acc > 0.6:
		plague_acc = 0.0
		_tick_plague()
		_tick_heretics()
	repro_acc += sd
	if repro_acc > 6.0:
		repro_acc = 0.0
		_tick_repro()
		_tick_animal_repro()
	for c in civs.values():
		if not c.alive:
			continue
		var pop := _civ_pop(c.id)
		if pop <= 0:
			c.alive = false
			continue
		c.tech += sd * (0.12 * float(pop) + 0.05)
		var new_era := GameState.era_from_tech(c.tech)
		if new_era != c.era:
			c.era = new_era
			_restyle_civ(c)
		c.faith = lerpf(c.faith, _civ_belief(c.id), 0.05)


func _populate_nature() -> void:
	var trees := 90 if GameState.world_size == GameState.WorldSize.SMALL else (160 if GameState.world_size == GameState.WorldSize.MEDIUM else 240)
	for i in range(trees):
		var p := terrain.random_land_point(rng)
		if p.y < 0.2:
			continue
		var b := terrain.get_biome(p.x, p.z)
		if not GameState.biome_supports_trees(b) and rng.randf() > 0.15:
			continue
		spawn_tree_at(p)
	for i in range(28):
		var p := terrain.random_land_point(rng)
		_spawn_resource("stone", p)
	for i in range(16):
		var p := terrain.random_land_point(rng)
		_spawn_resource("ore", p)
	var animals := 18 if GameState.world_size != GameState.WorldSize.LARGE else 28
	for i in range(animals):
		var p := terrain.random_land_point(rng)
		var b := terrain.get_biome(p.x, p.z)
		var species := Animal.pick_for_biome(b, rng)
		if species != "":
			spawn_animal(species, p)


func spawn_tree_at(p: Vector3) -> void:
	if not terrain.is_land(p.x, p.z):
		return
	var b := terrain.get_biome(p.x, p.z)
	var n := ResourceNode.new()
	entity_root.add_child(n)
	n.setup(GameState.next_id(), "wood", Vector3(p.x, terrain.get_height(p.x, p.z), p.z), ResourceNode.tree_for_biome(b))


func _spawn_resource(kind: String, p: Vector3) -> void:
	if not terrain.is_land(p.x, p.z):
		return
	var n := ResourceNode.new()
	entity_root.add_child(n)
	n.setup(GameState.next_id(), kind, Vector3(p.x, terrain.get_height(p.x, p.z), p.z))


func paint_forest(p: Vector3, radius: float) -> void:
	var n := int(radius * 0.9)
	for i in range(n):
		var a := rng.randf() * TAU
		var r := rng.randf() * radius
		var q := Vector3(p.x + cos(a) * r, 0, p.z + sin(a) * r)
		q.y = terrain.get_height(q.x, q.z)
		if q.y > 0.2:
			spawn_tree_at(q)


func paint_vegetation(p: Vector3, radius: float) -> void:
	for i in range(int(radius * 1.4)):
		var a := rng.randf() * TAU
		var r := rng.randf() * radius
		var q := Vector3(p.x + cos(a) * r, 0, p.z + sin(a) * r)
		q.y = terrain.get_height(q.x, q.z)
		if q.y < 0.15:
			continue
		var bush := MeshInstance3D.new()
		bush.mesh = Gfx.sphere
		bush.material_override = Gfx.mat(Color(0.22, 0.5, 0.18))
		bush.position = q
		bush.scale = Vector3(rng.randf_range(0.4, 0.9), rng.randf_range(0.3, 0.6), rng.randf_range(0.4, 0.9))
		veg_root.add_child(bush)


func add_volcano_visual(p: Vector3) -> void:
	var v := Node3D.new()
	v.position = Vector3(p.x, terrain.get_height(p.x, p.z), p.z)
	Gfx.part(v, Gfx.cone, Gfx.lava_material(), Vector3(0, 0.4, 0), Vector3(1.2, 0.6, 1.2), "Glow")
	entity_root.add_child(v)
	v.add_to_group("volcanoes")


func spawn_humans(p: Vector3, count: int) -> void:
	if not terrain.is_land(p.x, p.z):
		return
	var tribe := GameState.next_id()
	var near := _nearest_civ_at(p, 16.0)
	for i in range(count):
		var off := Vector3(rng.randf_range(-2.2, 2.2), 0, rng.randf_range(-2.2, 2.2))
		var q := p + off
		q.y = terrain.get_height(q.x, q.z)
		if q.y < 0.05:
			q = Vector3(p.x, terrain.get_height(p.x, p.z), p.z)
		var h := Human.new()
		entity_root.add_child(h)
		h.setup(GameState.next_id(), q, tribe, rng)
		if near != -1:
			h.civ_id = near
			h.home = p
			if civs.has(near):
				h.apply_civ_visual(civs[near].color, civs[near].era)
	float_text(p + Vector3(0, 2, 0), "life", Color(0.95, 0.85, 0.4))


func spawn_animal(species: String, p: Vector3) -> void:
	if not terrain.is_land(p.x, p.z):
		return
	var q := p
	q.y = terrain.get_height(p.x, p.z)
	var a := Animal.new()
	entity_root.add_child(a)
	a.setup(GameState.next_id(), species, q)


func species_count(sp: String) -> int:
	var n := 0
	for a in get_tree().get_nodes_in_group("animals"):
		if a.species == sp:
			n += 1
	return n


func add_resource(civ_id: int, kind: String, n: int) -> void:
	if civs.has(civ_id):
		civs[civ_id].add_res(kind, n)
	elif civ_id < 0:
		# unaligned tribe still banks locally by forming soon
		pass


func nearest_resource(pos: Vector3, radius: float, civ_id: int = -1) -> Node:
	var best: Node = null
	var bd := radius
	var needed := ""
	if civs.has(civ_id):
		var c: Civilization = civs[civ_id]
		needed = "stone" if c.stone < 3 else ("wood" if c.wood < 9 else "")
	var resources := get_tree().get_nodes_in_group("resources")
	var candidates := resources.filter(func(r: Node) -> bool: return r.kind == needed and pos.distance_to(r.global_position) < radius)
	if candidates.is_empty():
		candidates = resources
	for r in candidates:
		var d: float = pos.distance_to(r.global_position)
		if d < bd:
			bd = d
			best = r
	return best


func nearest_animal(pos: Vector3, radius: float) -> Node:
	var best: Node = null
	var bd := radius
	for a in get_tree().get_nodes_in_group("animals"):
		var d: float = pos.distance_to(a.global_position)
		if d < bd:
			bd = d
			best = a
	return best


func nearest_enemy(h: Human) -> Human:
	if not civs.has(h.civ_id):
		return null
	var best: Human = null
	var bd := 80.0
	for o in get_tree().get_nodes_in_group("humans"):
		if o.civ_id == h.civ_id or o.civ_id < 0:
			continue
		if civs.has(h.civ_id) and civs[h.civ_id].rel_with(o.civ_id) != GameState.Rel.HOSTILE:
			continue
		var d: float = h.global_position.distance_to(o.global_position)
		if d < bd:
			bd = d
			best = o
	return best


func nearest_temple(pos: Vector3, civ_id: int) -> Node:
	var best: Node = null
	var bd := 80.0
	for t in get_tree().get_nodes_in_group("temples"):
		if t.civ_id != civ_id:
			continue
		var d: float = pos.distance_to(t.global_position)
		if d < bd:
			bd = d
			best = t
	return best


func settlement_has_temple(civ_id: int) -> bool:
	for s in get_tree().get_nodes_in_group("settlements"):
		if s.civ_id == civ_id and s.has_temple:
			return true
	return false


func civ_at_war(civ_id: int) -> bool:
	if not civs.has(civ_id):
		return false
	var c: Civilization = civs[civ_id]
	for k in c.relations.keys():
		if int(c.relations[k]) == GameState.Rel.HOSTILE:
			return true
	return false


func civ_needs_food(civ_id: int) -> bool:
	if not civs.has(civ_id):
		return true
	return civs[civ_id].food < 12


func civ_can_build(civ_id: int) -> bool:
	if not civs.has(civ_id):
		return false
	var c: Civilization = civs[civ_id]
	return c.wood >= 4 and c.stone >= 2


func next_build_site(civ_id: int, from: Vector3) -> Vector3:
	var settle: Settlement = _civ_settlement(civ_id)
	if settle == null:
		return Vector3(0, -9999, 0)
	var buildings := _civ_buildings(civ_id)
	var want := _desired_building(civs[civ_id], settle, buildings)
	if want < 0:
		return Vector3(0, -9999, 0)
	settle.next_kind = want
	var ang := rng.randf() * TAU
	var r := rng.randf_range(2.5, settle.radius)
	var p := settle.global_position + Vector3(cos(ang) * r, 0, sin(ang) * r)
	p.y = terrain.get_height(p.x, p.z)
	if not terrain.is_land(p.x, p.z):
		return Vector3(0, -9999, 0)
	return p


func contribute_build(civ_id: int, pos: Vector3) -> void:
	if not civs.has(civ_id):
		return
	var c: Civilization = civs[civ_id]
	var s := _civ_settlement(civ_id)
	if s == null:
		return
	if not c.spend(3, 1, 0, 0):
		return
	s.build_progress += 1.0
	if s.build_progress >= 3.0:
		s.build_progress = 0.0
		_spawn_building(c, s, s.next_kind, pos)


func _desired_building(c: Civilization, s: Settlement, buildings: Array) -> int:
	var houses := 0
	var temples := 0
	var halls := 0
	var castles := 0
	for b in buildings:
		match b.kind:
			Building.Kind.HUT, Building.Kind.HOUSE:
				houses += 1
			Building.Kind.TEMPLE, Building.Kind.SHRINE:
				temples += 1
			Building.Kind.HALL, Building.Kind.WORKSHOP:
				halls += 1
			Building.Kind.CASTLE, Building.Kind.TOWER:
				castles += 1
	var pop := _civ_pop(c.id)
	if temples == 0 and s.belief_avg > 0.42 and c.wood >= 6:
		return Building.Kind.SHRINE if c.era <= GameState.Era.BRONZE else Building.Kind.TEMPLE
	if houses < max(1, pop / 3):
		return Building.Kind.HUT if c.era == GameState.Era.STONE else Building.Kind.HOUSE
	if halls == 0 and pop >= 8 and c.era >= GameState.Era.BRONZE:
		return Building.Kind.HALL
	if castles == 0 and c.era >= GameState.Era.IRON and pop >= 12:
		return Building.Kind.CASTLE if c.era >= GameState.Era.MEDIEVAL else Building.Kind.TOWER
	if houses < pop / 2:
		return Building.Kind.HOUSE
	return -1


func _spawn_building(c: Civilization, s: Settlement, kind: int, pos: Vector3) -> void:
	var b := Building.new()
	entity_root.add_child(b)
	var p := pos
	p.y = terrain.get_height(pos.x, pos.z)
	b.setup(GameState.next_id(), c.id, kind, c.era, p, c.color)
	if kind == Building.Kind.TEMPLE or kind == Building.Kind.SHRINE:
		s.has_temple = true
	float_text(p + Vector3(0, 2.5, 0), "built", Color(0.9, 0.8, 0.4))


func _form_civs() -> void:
	var unaligned: Array = []
	for h in get_tree().get_nodes_in_group("humans"):
		if h.civ_id < 0:
			unaligned.append(h)
	var used: Dictionary = {}
	for h in unaligned:
		if used.has(h.id):
			continue
		var cluster: Array = [h]
		for o in unaligned:
			if o == h or used.has(o.id):
				continue
			if h.global_position.distance_to(o.global_position) < 14.0 or o.tribe_seed == h.tribe_seed:
				cluster.append(o)
		if cluster.size() >= 3:
			var civ := Civilization.new(GameState.next_id(), Names.civ(rng), GameState.next_civ_color())
			civs[civ.id] = civ
			var acc := Vector3.ZERO
			for o in cluster:
				o.civ_id = civ.id
				o.home = h.global_position
				o.apply_civ_visual(civ.color, civ.era)
				used[o.id] = true
				acc += o.global_position
			var center := acc / float(cluster.size())
			center.y = terrain.get_height(center.x, center.z)
			var st := Settlement.new()
			entity_root.add_child(st)
			st.setup(GameState.next_id(), civ.id, civ.civ_name, center, civ.color)
			civ.settlement_ids.append(st.id)
			float_text(center + Vector3(0, 3, 0), civ.civ_name, civ.color)


func _update_settlements() -> void:
	for s in get_tree().get_nodes_in_group("settlements"):
		if not civs.has(s.civ_id):
			continue
		var c: Civilization = civs[s.civ_id]
		var pop := 0
		var bel := 0.0
		var her := 0
		for h in get_tree().get_nodes_in_group("humans"):
			if h.civ_id == c.id:
				pop += 1
				bel += h.belief
				if h.heretic:
					her += 1
		s.belief_avg = bel / float(max(pop, 1))
		s.heretic_count = her
		s.has_temple = not get_tree().get_nodes_in_group("temples").filter(func(t: Node) -> bool: return t.civ_id == c.id and not t.burning).is_empty()
		s.refresh_label(pop, GameState.ERA_NAMES[c.era])
		if her > pop * 0.55 and pop > 4 and s.has_temple:
			# heretical takeover: flag nearby heretics to rebel
			for h in get_tree().get_nodes_in_group("humans"):
				if h.civ_id == c.id and h.heretic:
					h.state = GameState.HumanState.REBEL


func _tick_war() -> void:
	var ids: Array = civs.keys()
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var a: Civilization = civs[ids[i]]
			var b: Civilization = civs[ids[j]]
			if not a.alive or not b.alive:
				continue
			var sa := _civ_settlement(a.id)
			var sb := _civ_settlement(b.id)
			if sa == null or sb == null:
				continue
			var d: float = sa.global_position.distance_to(sb.global_position)
			if d < 55.0 and a.rel_with(b.id) == GameState.Rel.NEUTRAL and rng.randf() < 0.18:
				a.set_rel(b.id, GameState.Rel.HOSTILE)
				b.set_rel(a.id, GameState.Rel.HOSTILE)
				_flag_warriors(a.id)
				_flag_warriors(b.id)
				float_text(sa.global_position + Vector3(0, 5, 0), "war!", Color(0.9, 0.2, 0.15))
			if a.rel_with(b.id) == GameState.Rel.HOSTILE:
				_try_conquer(a, b, sa, sb)


func _flag_warriors(civ_id: int) -> void:
	var n := 0
	for h in get_tree().get_nodes_in_group("humans"):
		if h.civ_id == civ_id:
			if n % 2 == 0:
				h.warrior = true
				h.weapon.visible = true
			n += 1


func _try_conquer(a: Civilization, b: Civilization, sa: Settlement, sb: Settlement) -> void:
	var pa := _civ_pop(a.id)
	var pb := _civ_pop(b.id)
	if pb <= 0 and pa > 0:
		sb.civ_id = a.id
		a.settlement_ids.append(sb.id)
		float_text(sb.global_position + Vector3(0, 4, 0), "conquered", a.color)
		b.alive = false


func _tick_plague() -> void:
	var humans := get_tree().get_nodes_in_group("humans")
	var infected: Array = []
	for h in humans:
		if h.infected:
			infected.append(h)
	for h in infected:
		for o in humans:
			if o == h or o.infected or o.dead:
				continue
			if h.global_position.distance_to(o.global_position) < 5.5 and rng.randf() < 0.28:
				o.infect()


func _tick_heretics() -> void:
	var humans := get_tree().get_nodes_in_group("humans")
	for h in humans:
		if not h.heretic:
			continue
		for o in humans:
			if o == h or o.heretic:
				continue
			if h.global_position.distance_to(o.global_position) < 4.5 and rng.randf() < 0.08:
				o.heretic = true
				o.belief = 0.0
				o.apply_civ_visual(Color(0.12, 0.1, 0.14), 0)


func _tick_repro() -> void:
	for c in civs.values():
		if not c.alive:
			continue
		var pop := _civ_pop(c.id)
		if pop >= 2 and pop < 80 and c.food >= 5:
			var s := _civ_settlement(c.id)
			if s == null:
				continue
			c.food -= 3
			var before := GameState._id_seq
			spawn_humans(s.global_position + Vector3(rng.randf() - 0.5, 0, rng.randf() - 0.5) * 3.0, 1)
			# join civ immediately
			for h in get_tree().get_nodes_in_group("humans"):
				if h.id > before and h.global_position.distance_to(s.global_position) < 8.0:
					h.civ_id = c.id
					h.home = s.global_position
					h.age = rng.randf_range(0.2, 4.0)
					h.apply_civ_visual(c.color, c.era)


func _tick_animal_repro() -> void:
	var animals := get_tree().get_nodes_in_group("animals")
	for a in animals:
		if a is Animal:
			a.try_reproduce(self, animals)


func _restyle_civ(c: Civilization) -> void:
	for b in get_tree().get_nodes_in_group("buildings"):
		if b.civ_id == c.id:
			b.restyle(c.era, c.color)
	for h in get_tree().get_nodes_in_group("humans"):
		if h.civ_id == c.id:
			h.apply_civ_visual(c.color, c.era)
	var st := _civ_settlement(c.id)
	if st:
		float_text(st.global_position + Vector3(0, 6, 0), GameState.ERA_NAMES[c.era], c.color)


func boost_tech_at(p: Vector3, amt: float) -> void:
	var s := _settlement_near(p, 18.0)
	if s and civs.has(s.civ_id):
		civs[s.civ_id].tech += amt
		float_text(p + Vector3(0, 3, 0), "+tech", Color(0.6, 0.8, 1.0))
		fx.miracle_burst(p)


func encourage_at(p: Vector3) -> void:
	var s := _settlement_near(p, 18.0)
	if s and civs.has(s.civ_id):
		civs[s.civ_id].food += 8
		civs[s.civ_id].wood += 8
		civs[s.civ_id].stone += 6
		float_text(p + Vector3(0, 3, 0), "flourish", Color(0.6, 1.0, 0.5))


func cast_lightning(p: Vector3) -> void:
	fx.lightning(p)
	cam.shake(0.35)
	kill_at(p, 3.2)
	terrain.scorch(p.x, p.z, 2.2)
	_belief_burst(p, 0.18)
	# lightning does not require faith — omnipotent


func cast_tornado(p: Vector3) -> void:
	var n := fx.tornado(p)
	effects.append(n)


func cast_meteor(p: Vector3) -> void:
	var n := fx.meteor(p)
	effects.append(n)


func cast_erupt(p: Vector3) -> void:
	fx.erupt(p)
	cam.shake(0.7)
	kill_at(p, 8.0)
	terrain.brush(p.x, p.z, 7.0, 1.0, "volcano")
	_destroy_buildings(p, 8.0)


func kill_at(p: Vector3, radius: float) -> void:
	for h in get_tree().get_nodes_in_group("humans"):
		if h.global_position.distance_to(p) <= radius:
			h.die("divine")
	for a in get_tree().get_nodes_in_group("animals"):
		if a.global_position.distance_to(p) <= radius:
			a.kill()


func cast_miracle(p: Vector3) -> void:
	fx.miracle_burst(p)
	_belief_burst(p, 0.28)
	for h in get_tree().get_nodes_in_group("humans"):
		if h.global_position.distance_to(p) < 10.0:
			if h.infected:
				h.cure()
			if not h.heretic:
				h.belief = clampf(h.belief + 0.28, 0.0, 1.0)


func cast_plague(p: Vector3, radius: float) -> void:
	fx.plague_burst(p)
	for h in get_tree().get_nodes_in_group("humans"):
		if h.global_position.distance_to(p) <= radius:
			h.infect()


func cast_cure(p: Vector3, radius: float) -> void:
	for h in get_tree().get_nodes_in_group("humans"):
		if h.global_position.distance_to(p) <= radius:
			h.cure()
	float_text(p + Vector3(0, 2, 0), "cured", Color(0.5, 0.9, 1.0))


func _belief_burst(p: Vector3, amt: float) -> void:
	for h in get_tree().get_nodes_in_group("humans"):
		if h.global_position.distance_to(p) < 16.0 and not h.heretic:
			h.belief = clampf(h.belief + amt, 0.0, 1.0)


func _destroy_buildings(p: Vector3, radius: float) -> void:
	for b in get_tree().get_nodes_in_group("buildings"):
		if b.global_position.distance_to(p) <= radius:
			b.burn()


func _tick_effects(sd: float) -> void:
	var keep: Array = []
	for n in effects:
		if not is_instance_valid(n):
			continue
		var kind := str(n.get_meta("kind", ""))
		var life := float(n.get_meta("life", 0.0)) - sd
		n.set_meta("life", life)
		if kind == "tornado":
			n.position += Vector3(sin(GameState.sim_time) * 2.0, 0, cos(GameState.sim_time * 0.7) * 2.0) * sd
			n.position.y = terrain.get_height(n.position.x, n.position.z)
			kill_at(n.global_position, 4.5)
			_destroy_buildings(n.global_position, 4.5)
		elif kind == "meteor":
			var dest: Vector3 = n.get_meta("dest")
			n.global_position = n.global_position.lerp(dest, clampf(sd * 2.2, 0.0, 1.0))
			if n.global_position.distance_to(dest) < 1.2:
				fx.erupt(dest)
				cam.shake(0.9)
				kill_at(dest, 7.0)
				terrain.crater(dest.x, dest.z, 5.0)
				_destroy_buildings(dest, 7.0)
				n.queue_free()
				life = -1.0
		if life > 0.0 and is_instance_valid(n):
			keep.append(n)
		elif is_instance_valid(n):
			n.queue_free()
	effects = keep


func float_text(pos: Vector3, text: String, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 48
	l.modulate = color
	l.outline_size = 10
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos
	add_child(l)
	floaters.append({"n": l, "t": 0.0})


func _tick_floaters(delta: float) -> void:
	var keep: Array = []
	for f in floaters:
		if not is_instance_valid(f["n"]):
			continue
		f["t"] += delta
		f["n"].position.y += delta * 1.4
		f["n"].modulate.a = 1.0 - f["t"] / 1.4
		if f["t"] < 1.4:
			keep.append(f)
		else:
			f["n"].queue_free()
	floaters = keep


func _ambient_weather() -> void:
	var p := cam.global_position
	var b := terrain.get_biome(p.x, p.z)
	weather.set_biome_weather(GameState.weather_for_biome(b))


func _civ_pop(id: int) -> int:
	var n := 0
	for h in get_tree().get_nodes_in_group("humans"):
		if h.civ_id == id:
			n += 1
	return n


func _civ_belief(id: int) -> float:
	var s := 0.0
	var n := 0
	for h in get_tree().get_nodes_in_group("humans"):
		if h.civ_id == id:
			s += h.belief
			n += 1
	return s / float(max(n, 1))


func _civ_settlement(id: int) -> Settlement:
	for s in get_tree().get_nodes_in_group("settlements"):
		if s.civ_id == id:
			return s
	return null


func _civ_buildings(id: int) -> Array:
	var out: Array = []
	for b in get_tree().get_nodes_in_group("buildings"):
		if b.civ_id == id:
			out.append(b)
	return out


func _settlement_near(p: Vector3, r: float) -> Settlement:
	var best: Settlement = null
	var bd := r
	for s in get_tree().get_nodes_in_group("settlements"):
		var d: float = s.global_position.distance_to(p)
		if d < bd:
			bd = d
			best = s
	return best


func _nearest_civ_at(p: Vector3, r: float) -> int:
	var s := _settlement_near(p, r)
	return s.civ_id if s else -1


func _alive_civs() -> int:
	var n := 0
	for c in civs.values():
		if c.alive:
			n += 1
	return n


func _save() -> void:
	var humans: Array = []
	for h in get_tree().get_nodes_in_group("humans"):
		humans.append(h.serialize())
	var animals: Array = []
	for a in get_tree().get_nodes_in_group("animals"):
		animals.append(a.serialize())
	var buildings: Array = []
	for b in get_tree().get_nodes_in_group("buildings"):
		buildings.append(b.serialize())
	var settlements: Array = []
	for s in get_tree().get_nodes_in_group("settlements"):
		settlements.append(s.serialize())
	var resources: Array = []
	for r in get_tree().get_nodes_in_group("resources"):
		resources.append(r.serialize())
	var civ_arr: Array = []
	for c in civs.values():
		civ_arr.append(c.serialize())
	var data := {
		"version": 1,
		"name": GameState.world_name,
		"mode": GameState.world_mode,
		"size": GameState.world_size,
		"seed": GameState.world_seed,
		"biomes": GameState.biomes_selected,
		"sim_time": GameState.sim_time,
		"id_seq": GameState._id_seq,
		"color_index": GameState._civ_color_idx,
		"rng_state": str(rng.state),
		"vegetation": _serialize_vegetation(),
		"terrain": terrain.serialize(),
		"humans": humans,
		"animals": animals,
		"buildings": buildings,
		"settlements": settlements,
		"resources": resources,
		"civs": civ_arr
	}
	var path := SaveLoad.write_save(data, GameState.world_name)
	float_text(cam.global_position + Vector3(0, 2, 0), "saved" if path != "" else "save failed", UiKit.GOLD)
	if pause_ui:
		pause_ui.refresh_saves()


func _load_from(filename: String) -> void:
	var d := SaveLoad.read_save(filename)
	if d.is_empty():
		WorldGen.generate(terrain, {"mode": GameState.world_mode, "biomes": GameState.biomes_selected}, rng)
		return
	GameState.world_name = str(d.get("name", "Loaded World"))
	GameState.world_mode = int(d.get("mode", 0))
	GameState.world_size = int(d.get("size", 1))
	GameState.world_seed = int(d.get("seed", 0))
	GameState.biomes_selected = d.get("biomes", [])
	GameState.sim_time = float(d.get("sim_time", 0))
	GameState.reset_ids(int(d.get("id_seq", 100)))
	if d.has("terrain"):
		terrain.deserialize(d["terrain"])
	cam.configure(terrain.radius)
	weather.queue_free()
	weather = WeatherFx.new()
	add_child(weather)
	weather.setup(terrain.radius)
	GameState._civ_color_idx = int(d.get("color_index", d.get("civs", []).size()))
	rng.seed = GameState.world_seed
	if d.has("rng_state"):
		rng.state = int(d["rng_state"])
	for vd in d.get("vegetation", []):
		var bush := MeshInstance3D.new()
		bush.mesh = Gfx.sphere
		bush.material_override = Gfx.mat(Color(0.22, 0.5, 0.18))
		bush.position = Vector3(vd.x, vd.y, vd.z)
		bush.scale = Vector3(vd.sx, vd.sy, vd.sz)
		veg_root.add_child(bush)
	for vd in terrain.volcanoes:
		add_volcano_visual(Vector3(vd.x, 0, vd.z))
	civs.clear()
	for cd in d.get("civs", []):
		var c := Civilization.from_dict(cd)
		civs[c.id] = c
	for rd in d.get("resources", []):
		var n := ResourceNode.new()
		entity_root.add_child(n)
		n.setup(int(rd.get("id", 0)), str(rd.get("kind", "wood")), Vector3(rd.get("x", 0), rd.get("y", 0), rd.get("z", 0)), str(rd.get("type", "oak")))
	for sd in d.get("settlements", []):
		var st := Settlement.new()
		entity_root.add_child(st)
		var cid := int(sd.get("civ", -1))
		var col := Color.WHITE
		if civs.has(cid):
			col = civs[cid].color
		st.setup(int(sd.get("id", 0)), cid, str(sd.get("name", "Camp")), Vector3(sd.get("x", 0), sd.get("y", 0), sd.get("z", 0)), col)
		st.has_temple = bool(sd.get("has_temple", false))
		st.build_progress = float(sd.get("build", 0))
		st.next_kind = int(sd.get("next", 0))
		st.radius = float(sd.get("radius", 10))
	for bd in d.get("buildings", []):
		var b := Building.new()
		entity_root.add_child(b)
		var cid := int(bd.get("civ", -1))
		var col := Color.WHITE
		if civs.has(cid):
			col = civs[cid].color
		b.setup(int(bd.get("id", 0)), cid, int(bd.get("kind", 0)), int(bd.get("era", 0)), Vector3(bd.get("x", 0), bd.get("y", 0), bd.get("z", 0)), col)
		b.hp = float(bd.get("hp", 10))
		b.burn_t = float(bd.get("burn_t", 0))
		if bool(bd.get("burning", false)):
			b.burn()
	for hd in d.get("humans", []):
		var h := Human.new()
		entity_root.add_child(h)
		h.setup(int(hd.get("id", 0)), Vector3(hd.get("x", 0), hd.get("y", 0), hd.get("z", 0)), int(hd.get("tribe", 0)), rng)
		h.human_name = str(hd.get("name", h.human_name))
		h.civ_id = int(hd.get("civ", -1))
		h.age = float(hd.get("age", 16))
		h.lifespan = float(hd.get("life", 62))
		h.belief = float(hd.get("belief", 0.1))
		h.heretic = bool(hd.get("heretic", false))
		h.gender = int(hd.get("gender", h.gender))
		h.warrior = bool(hd.get("warrior", false))
		h.home = Vector3(hd.get("home_x", 0), hd.get("home_y", 0), hd.get("home_z", 0))
		if bool(hd.get("infected", false)):
			h.infect()
			h.infect_t = float(hd.get("infect_t", 0))
		h.weapon.visible = h.warrior
		if civs.has(h.civ_id):
			h.apply_civ_visual(civs[h.civ_id].color, civs[h.civ_id].era)
	for ad in d.get("animals", []):
		var a := Animal.new()
		entity_root.add_child(a)
		a.setup(int(ad.get("id", 0)), str(ad.get("species", "deer")), Vector3(ad.get("x", 0), ad.get("y", 0), ad.get("z", 0)))
		a.age = float(ad.get("age", 1))
		a.mate_cd = float(ad.get("mate", 0))


func _serialize_vegetation() -> Array:
	var result: Array = []
	for n in veg_root.get_children():
		result.append({"x": n.position.x, "y": n.position.y, "z": n.position.z, "sx": n.scale.x, "sy": n.scale.y, "sz": n.scale.z})
	return result


func remove_vegetation(p: Vector3, brush_radius: float) -> void:
	for n in get_tree().get_nodes_in_group("resources"):
		if n.kind == "wood" and n.global_position.distance_to(p) <= brush_radius:
			n.remove_from_group("resources")
			n.queue_free()
	for n in veg_root.get_children():
		if n.global_position.distance_to(p) <= brush_radius:
			veg_root.remove_child(n)
			n.queue_free()
