class_name TerrainWorld
extends Node3D
## Circular heightmap world with chunked rebuilds and biome vertex colors.

const CHUNK := 16
const WATER_LEVEL := 0.0
const BEACH := 0.55

var radius: float = 118.0
var grid: int = 128
var cell: float = 1.85
var heights: PackedFloat32Array = PackedFloat32Array()
var biomes: PackedByteArray = PackedByteArray()
var chunks: Dictionary = {} # Vector2i -> MeshInstance3D
var dirty: Dictionary = {}
var water: MeshInstance3D
var underside: MeshInstance3D
var rim: MeshInstance3D
var cursor: MeshInstance3D
var volcanoes: Array = [] # Dictionary {x,z,id}

var _terrain_mat: ShaderMaterial
var _rebuild_budget: int = 4


func setup(p_radius: float, p_grid: int) -> void:
	radius = p_radius
	grid = p_grid
	cell = (radius * 2.0) / float(grid - 1)
	var n: int = grid * grid
	heights.resize(n)
	biomes.resize(n)
	heights.fill(-2.4)
	biomes.fill(GameState.Biome.OCEAN)
	_terrain_mat = Gfx.terrain_material()
	_build_chunks()
	_build_water()
	_build_underside()
	_build_cursor()


func idx(x: int, z: int) -> int:
	return z * grid + x


func in_b(x: int, z: int) -> bool:
	return x >= 0 and z >= 0 and x < grid and z < grid


func world_to_grid(wx: float, wz: float) -> Vector2i:
	var gx := int(round((wx + radius) / cell))
	var gz := int(round((wz + radius) / cell))
	return Vector2i(clampi(gx, 0, grid - 1), clampi(gz, 0, grid - 1))


func grid_to_world(x: int, z: int) -> Vector2:
	return Vector2(-radius + float(x) * cell, -radius + float(z) * cell)


func radial(x: int, z: int) -> float:
	var w := grid_to_world(x, z)
	return w.length()


func get_height(wx: float, wz: float) -> float:
	var fx := (wx + radius) / cell
	var fz := (wz + radius) / cell
	var x0 := clampi(int(floor(fx)), 0, grid - 2)
	var z0 := clampi(int(floor(fz)), 0, grid - 2)
	var tx := clampf(fx - float(x0), 0.0, 1.0)
	var tz := clampf(fz - float(z0), 0.0, 1.0)
	var h00 := heights[idx(x0, z0)]
	var h10 := heights[idx(x0 + 1, z0)]
	var h01 := heights[idx(x0, z0 + 1)]
	var h11 := heights[idx(x0 + 1, z0 + 1)]
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


func get_biome(wx: float, wz: float) -> int:
	var g := world_to_grid(wx, wz)
	return int(biomes[idx(g.x, g.y)])


func set_height_i(x: int, z: int, h: float) -> void:
	if not in_b(x, z):
		return
	if radial(x, z) > radius * 0.98:
		return
	heights[idx(x, z)] = h
	_mark(x, z)


func add_height_i(x: int, z: int, dh: float) -> void:
	if not in_b(x, z):
		return
	if radial(x, z) > radius * 0.98:
		return
	heights[idx(x, z)] = clampf(heights[idx(x, z)] + dh, -8.0, 22.0)
	_mark(x, z)


func set_biome_i(x: int, z: int, b: int) -> void:
	if not in_b(x, z):
		return
	biomes[idx(x, z)] = b
	_mark(x, z)


func _mark(x: int, z: int) -> void:
	var cx := x / CHUNK
	var cz := z / CHUNK
	dirty[Vector2i(cx, cz)] = true
	if x % CHUNK == 0 and cx > 0:
		dirty[Vector2i(cx - 1, cz)] = true
	if z % CHUNK == 0 and cz > 0:
		dirty[Vector2i(cx, cz - 1)] = true
	if x % CHUNK == 0 and z % CHUNK == 0 and cx > 0 and cz > 0:
		dirty[Vector2i(cx - 1, cz - 1)] = true


func brush(wx: float, wz: float, size: float, strength: float, mode: String, biome: int = GameState.Biome.GRASSLAND) -> void:
	var g := world_to_grid(wx, wz)
	var r := int(ceil(size / cell)) + 1
	for z in range(g.y - r, g.y + r + 1):
		for x in range(g.x - r, g.x + r + 1):
			if not in_b(x, z):
				continue
			var w := grid_to_world(x, z)
			var d := Vector2(w.x - wx, w.y - wz).length()
			if d > size:
				continue
			var fall := pow(1.0 - d / max(size, 0.001), 1.4)
			match mode:
				"raise":
					add_height_i(x, z, strength * fall * 0.55)
					if heights[idx(x, z)] > 0.15 and biomes[idx(x, z)] == GameState.Biome.OCEAN:
						set_biome_i(x, z, biome)
				"lower":
					add_height_i(x, z, -strength * fall * 0.55)
				"mountain":
					add_height_i(x, z, strength * fall * fall * 1.35)
					if heights[idx(x, z)] > 0.2 and biomes[idx(x, z)] == GameState.Biome.OCEAN:
						set_biome_i(x, z, GameState.Biome.MOUNTAINOUS)
				"valley":
					add_height_i(x, z, -strength * fall * 0.9)
				"island":
					var target := 1.2 * fall * strength * 4.0
					var h := heights[idx(x, z)]
					if target > h:
						set_height_i(x, z, lerpf(h, target, 0.35))
					if heights[idx(x, z)] > 0.15:
						set_biome_i(x, z, biome)
				"lake":
					var target_l := -0.7 * fall
					if heights[idx(x, z)] > target_l:
						add_height_i(x, z, -strength * fall * 0.8)
				"paint":
					if heights[idx(x, z)] > -0.1:
						set_biome_i(x, z, biome)
				"volcano":
					var cone: float = (1.0 - d / max(size, 0.001))
					var hgt: float = cone * strength * 7.0
					if d < size * 0.18:
						hgt *= 0.45
					if hgt > heights[idx(x, z)]:
						set_height_i(x, z, lerpf(heights[idx(x, z)], hgt, 0.5))
					set_biome_i(x, z, GameState.Biome.VOLCANIC)
	if mode == "volcano":
		volcanoes.append({"x": wx, "z": wz, "id": GameState.next_id()})


func carve_river(a: Vector3, b: Vector3, width: float, strength: float) -> void:
	var steps := int(a.distance_to(b) / (cell * 0.6)) + 1
	for i in range(steps + 1):
		var t := float(i) / float(max(steps, 1))
		var p := a.lerp(b, t)
		brush(p.x, p.z, width, strength, "lower")


func scorch(wx: float, wz: float, size: float) -> void:
	brush(wx, wz, size, 0.4, "paint", GameState.Biome.VOLCANIC)
	brush(wx, wz, size * 0.6, 0.5, "lower")


func crater(wx: float, wz: float, size: float) -> void:
	brush(wx, wz, size, 1.2, "lower")
	brush(wx, wz, size * 0.5, 0.6, "paint", GameState.Biome.VOLCANIC)


func is_land(wx: float, wz: float) -> bool:
	if Vector2(wx, wz).length() > radius * 0.96:
		return false
	return get_height(wx, wz) > 0.12


func random_land_point(rng: RandomNumberGenerator) -> Vector3:
	for _i in range(40):
		var ang := rng.randf() * TAU
		var r := sqrt(rng.randf()) * radius * 0.85
		var x := cos(ang) * r
		var z := sin(ang) * r
		if is_land(x, z):
			return Vector3(x, get_height(x, z), z)
	return Vector3(0, get_height(0, 0), 0)


func raycast(origin: Vector3, dir: Vector3) -> Vector3:
	var d := dir.normalized()
	var p := origin
	for _i in range(400):
		if Vector2(p.x, p.z).length() > radius:
			p += d * 2.0
			continue
		var h := get_height(p.x, p.z)
		if p.y <= h + 0.08:
			return Vector3(p.x, h, p.z)
		var step := clampf((p.y - h) * 0.42, 0.35, 3.4)
		p += d * step
	return Vector3(INF, INF, INF)


func _process(_delta: float) -> void:
	if dirty.is_empty():
		return
	var n := 0
	var keys: Array = dirty.keys()
	for k in keys:
		_rebuild_chunk(k)
		dirty.erase(k)
		n += 1
		if n >= _rebuild_budget:
			break


func rebuild_all() -> void:
	dirty.clear()
	for k in chunks.keys():
		_rebuild_chunk(k)


func _build_chunks() -> void:
	var ncx := int(ceil(float(grid) / float(CHUNK)))
	for cz in range(ncx):
		for cx in range(ncx):
			var mi := MeshInstance3D.new()
			mi.name = "Chunk_%d_%d" % [cx, cz]
			mi.material_override = _terrain_mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			add_child(mi)
			chunks[Vector2i(cx, cz)] = mi
			_rebuild_chunk(Vector2i(cx, cz))


func _rebuild_chunk(ck: Vector2i) -> void:
	if not chunks.has(ck):
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var quads := 0
	var x0: int = ck.x * CHUNK
	var z0: int = ck.y * CHUNK
	var x1: int = mini(x0 + CHUNK, grid - 1)
	var z1: int = mini(z0 + CHUNK, grid - 1)
	for z in range(z0, z1):
		for x in range(x0, x1):
			if radial(x, z) > radius and radial(x + 1, z + 1) > radius:
				continue
			_quad(st, x, z)
			quads += 1
	if quads == 0:
		chunks[ck].mesh = null
		return
	st.generate_normals()
	var mesh := st.commit()
	chunks[ck].mesh = mesh


func _quad(st: SurfaceTool, x: int, z: int) -> void:
	var p00 := _vert(x, z)
	var p10 := _vert(x + 1, z)
	var p01 := _vert(x, z + 1)
	var p11 := _vert(x + 1, z + 1)
	var c00 := _color(x, z)
	var c10 := _color(x + 1, z)
	var c01 := _color(x, z + 1)
	var c11 := _color(x + 1, z + 1)
	_tri(st, p00, p10, p11, c00, c10, c11)
	_tri(st, p00, p11, p01, c00, c11, c01)


func _vert(x: int, z: int) -> Vector3:
	var w := grid_to_world(x, z)
	var h := heights[idx(x, z)]
	var dist := Vector2(w.x, w.y).length()
	if dist > radius:
		h = -6.0 - (dist - radius) * 2.0
	return Vector3(w.x, h, w.y)


func _color(x: int, z: int) -> Color:
	var b: int = int(biomes[idx(x, z)])
	var h := heights[idx(x, z)]
	var col: Color = GameState.BIOME_COLORS[clampi(b, 0, GameState.BIOME_COLORS.size() - 1)]
	if b == GameState.Biome.ARCTIC:
		col = col.lerp(Color(0.95, 0.96, 0.98), clampf(h / 6.0, 0.2, 0.85))
	elif b == GameState.Biome.VOLCANIC and h > 4.0:
		col = col.lerp(Color(0.55, 0.16, 0.08), 0.45)
	elif h > 10.0:
		col = col.lerp(Color(0.93, 0.95, 0.98), clampf((h - 10.0) / 5.0, 0.0, 1.0))
	return col


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	st.set_color(ca)
	st.add_vertex(a)
	st.set_color(cb)
	st.add_vertex(b)
	st.set_color(cc)
	st.add_vertex(c)


func _build_water() -> void:
	water = MeshInstance3D.new()
	water.name = "Water"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 18
	var segs := 64
	for r in range(rings):
		var r0 := (float(r) / float(rings)) * radius * 0.995
		var r1 := (float(r + 1) / float(rings)) * radius * 0.995
		for s in range(segs):
			var a0 := float(s) / float(segs) * TAU
			var a1 := float(s + 1) / float(segs) * TAU
			var p00 := Vector3(cos(a0) * r0, WATER_LEVEL, sin(a0) * r0)
			var p10 := Vector3(cos(a1) * r0, WATER_LEVEL, sin(a1) * r0)
			var p01 := Vector3(cos(a0) * r1, WATER_LEVEL, sin(a0) * r1)
			var p11 := Vector3(cos(a1) * r1, WATER_LEVEL, sin(a1) * r1)
			var uv_scale := 0.02
			# Clockwise top faces; the original winding produced downward normals.
			var vertices: Array[Vector3] = [p00, p01, p11]
			if r > 0:
				vertices.append_array([p00, p11, p10])
			for vertex in vertices:
				st.set_uv(Vector2(vertex.x, vertex.z) * uv_scale)
				st.add_vertex(vertex)
	st.generate_normals()
	water.mesh = st.commit()
	water.material_override = Gfx.water_material()
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)


func _build_underside() -> void:
	underside = MeshInstance3D.new()
	underside.name = "Underside"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 48
	var rock := Color(0.28, 0.24, 0.22)
	var deep := Color(0.12, 0.10, 0.12)
	var y_top := -0.6
	var y_bot := -14.0
	for s in range(segs):
		var a0 := float(s) / float(segs) * TAU
		var a1 := float(s + 1) / float(segs) * TAU
		var r := radius * 0.99
		var p0 := Vector3(cos(a0) * r, y_top, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, y_top, sin(a1) * r)
		var q0 := Vector3(cos(a0) * r * 0.15, y_bot, sin(a0) * r * 0.15)
		var q1 := Vector3(cos(a1) * r * 0.15, y_bot, sin(a1) * r * 0.15)
		st.set_color(rock)
		st.add_vertex(p0)
		st.set_color(rock)
		st.add_vertex(p1)
		st.set_color(deep)
		st.add_vertex(q1)
		st.set_color(rock)
		st.add_vertex(p0)
		st.set_color(deep)
		st.add_vertex(q1)
		st.set_color(deep)
		st.add_vertex(q0)
	st.generate_normals()
	underside.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.95
	underside.material_override = m
	add_child(underside)


func _build_cursor() -> void:
	cursor = MeshInstance3D.new()
	cursor.name = "BrushCursor"
	var cm := TorusMesh.new()
	cm.inner_radius = 0.85
	cm.outer_radius = 1.0
	cm.rings = 16
	cm.ring_segments = 8
	cursor.mesh = cm
	cursor.material_override = Gfx.mat(Color(1.0, 0.92, 0.45, 0.85), 0.4, 0.0, Color(1.0, 0.9, 0.4), 0.6, true)
	cursor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cursor)


func set_cursor(pos: Vector3, size: float, visible: bool) -> void:
	cursor.visible = visible
	if not visible:
		return
	cursor.global_position = pos + Vector3(0, 0.15, 0)
	var s := maxf(size, 0.6)
	cursor.scale = Vector3(s, 0.4, s)


func serialize() -> Dictionary:
	return {
		"radius": radius,
		"grid": grid,
		"heights": Array(heights),
		"biomes": Array(biomes),
		"volcanoes": volcanoes.duplicate(true)
	}


func deserialize(d: Dictionary) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	chunks.clear()
	dirty.clear()
	radius = float(d.get("radius", radius))
	grid = int(d.get("grid", grid))
	cell = (radius * 2.0) / float(max(grid - 1, 1))
	var hsrc: Array = d.get("heights", [])
	var b: Array = d.get("biomes", [])
	var n: int = grid * grid
	heights = PackedFloat32Array()
	heights.resize(n)
	heights.fill(-2.4)
	biomes = PackedByteArray()
	biomes.resize(n)
	biomes.fill(GameState.Biome.OCEAN)
	var lim := mini(n, hsrc.size())
	for i in range(lim):
		heights[i] = float(hsrc[i])
	lim = mini(n, b.size())
	for i in range(lim):
		biomes[i] = int(b[i])
	volcanoes = d.get("volcanoes", [])
	if chunks.is_empty():
		_terrain_mat = Gfx.terrain_material()
		_build_chunks()
		_build_water()
		_build_underside()
		_build_cursor()
	else:
		rebuild_all()
