class_name ToolController
extends Node

signal tool_changed(id: int)
signal inspect_human(h: Human)
signal inspect_settlement(s: Settlement)

var tool: int = GameState.ToolId.INSPECT
var brush_size: float = 6.0
var brush_strength: float = 0.7
var paint_biome: int = GameState.Biome.GRASSLAND
var animal_species: String = "deer"
var dragging: bool = false
var river_last: Vector3 = Vector3(INF, INF, INF)
var world: Node = null
var hover: Vector3 = Vector3.ZERO
var hover_valid: bool = false


func set_tool(id: int) -> void:
	tool = id
	river_last = Vector3(INF, INF, INF)
	tool_changed.emit(id)


func _unhandled_input(event: InputEvent) -> void:
	if world == null or GameState.world == null:
		return
	if world.pause_open:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				dragging = true
				_use(true)
			else:
				dragging = false
				river_last = Vector3(INF, INF, INF)
	elif event is InputEventMouseMotion and dragging:
		_use(false)


func _process(_delta: float) -> void:
	if world == null:
		return
	_update_hover()
	if world.terrain:
		world.terrain.set_cursor(hover, brush_size, hover_valid and _is_brush_tool())


func _update_hover() -> void:
	var cam: Camera3D = world.cam.camera()
	var mouse := world.get_viewport().get_mouse_position()
	var origin := cam.project_ray_origin(mouse)
	var dir := cam.project_ray_normal(mouse)
	var hit: Vector3 = world.terrain.raycast(origin, dir)
	if hit.x < 100000.0:
		hover = hit
		hover_valid = true
	else:
		hover_valid = false


func _is_brush_tool() -> bool:
	return tool in [
		GameState.ToolId.RAISE, GameState.ToolId.LOWER, GameState.ToolId.MOUNTAIN,
		GameState.ToolId.VALLEY, GameState.ToolId.ISLAND, GameState.ToolId.LAKE,
		GameState.ToolId.RIVER, GameState.ToolId.PAINT, GameState.ToolId.FOREST,
		GameState.ToolId.VEGETATION, GameState.ToolId.VOLCANO, GameState.ToolId.KILL_GROUP,
		GameState.ToolId.PLAGUE, GameState.ToolId.CURE, GameState.ToolId.REMOVE_VEGETATION
	]


func _use(first: bool) -> void:
	if not hover_valid:
		return
	var p := hover
	match tool:
		GameState.ToolId.RAISE:
			world.terrain.brush(p.x, p.z, brush_size, brush_strength, "raise", paint_biome)
		GameState.ToolId.LOWER:
			world.terrain.brush(p.x, p.z, brush_size, brush_strength, "lower")
		GameState.ToolId.MOUNTAIN:
			world.terrain.brush(p.x, p.z, brush_size * 1.2, brush_strength, "mountain")
		GameState.ToolId.VALLEY:
			world.terrain.brush(p.x, p.z, brush_size, brush_strength, "valley")
		GameState.ToolId.ISLAND:
			world.terrain.brush(p.x, p.z, brush_size * 1.4, brush_strength, "island", paint_biome)
		GameState.ToolId.LAKE:
			world.terrain.brush(p.x, p.z, brush_size, brush_strength, "lake")
		GameState.ToolId.RIVER:
			if river_last.x < 100000.0:
				world.terrain.carve_river(river_last, p, max(brush_size * 0.35, 1.2), brush_strength)
			else:
				world.terrain.brush(p.x, p.z, max(brush_size * 0.35, 1.2), brush_strength, "lower")
			river_last = p
		GameState.ToolId.PAINT:
			world.terrain.brush(p.x, p.z, brush_size, 1.0, "paint", paint_biome)
		GameState.ToolId.FOREST:
			if first:
				world.paint_forest(p, brush_size)
		GameState.ToolId.VEGETATION:
			if first:
				world.paint_vegetation(p, brush_size)
		GameState.ToolId.VOLCANO:
			if first:
				world.terrain.brush(p.x, p.z, max(brush_size, 8.0), 1.0, "volcano")
				world.add_volcano_visual(p)
		GameState.ToolId.REMOVE_VEGETATION:
			world.remove_vegetation(p, brush_size)
		GameState.ToolId.SPAWN_TREE:
			if first:
				world.spawn_tree_at(p)
		GameState.ToolId.SPAWN_ANIMAL:
			if first:
				world.spawn_animal(animal_species, p)
		GameState.ToolId.SPAWN_HUMAN_1:
			if first:
				world.spawn_humans(p, 1)
		GameState.ToolId.SPAWN_HUMAN_5:
			if first:
				world.spawn_humans(p, 5)
		GameState.ToolId.SPAWN_HUMAN_20:
			if first:
				world.spawn_humans(p, 20)
		GameState.ToolId.INSPECT:
			if first:
				_inspect(p)
		GameState.ToolId.BOOST_TECH:
			if first:
				world.boost_tech_at(p, 40.0)
		GameState.ToolId.ENCOURAGE:
			if first:
				world.encourage_at(p)
		GameState.ToolId.LIGHTNING:
			if first:
				world.cast_lightning(p)
		GameState.ToolId.TORNADO:
			if first:
				world.cast_tornado(p)
		GameState.ToolId.METEOR:
			if first:
				world.cast_meteor(p)
		GameState.ToolId.ERUPT:
			if first:
				world.cast_erupt(p)
		GameState.ToolId.KILL:
			if first:
				world.kill_at(p, 1.6)
		GameState.ToolId.KILL_GROUP:
			world.kill_at(p, brush_size)
		GameState.ToolId.RAIN:
			if first:
				world.weather.summon("rain")
		GameState.ToolId.STORM:
			if first:
				world.weather.summon("storm")
		GameState.ToolId.SNOW:
			if first:
				world.weather.summon("snow")
		GameState.ToolId.MIRACLE:
			if first:
				world.cast_miracle(p)
		GameState.ToolId.PLAGUE:
			if first:
				world.cast_plague(p, brush_size)
		GameState.ToolId.CURE:
			world.cast_cure(p, brush_size)


func _inspect(p: Vector3) -> void:
	var best_h: Human = null
	var best_d := 3.5
	for n in world.get_tree().get_nodes_in_group("humans"):
		var d: float = n.global_position.distance_to(p)
		if d < best_d:
			best_d = d
			best_h = n
	if best_h:
		inspect_human.emit(best_h)
		return
	var best_s: Settlement = null
	best_d = 8.0
	for n in world.get_tree().get_nodes_in_group("settlements"):
		var d: float = n.global_position.distance_to(p)
		if d < best_d:
			best_d = d
			best_s = n
	if best_s:
		inspect_settlement.emit(best_s)
