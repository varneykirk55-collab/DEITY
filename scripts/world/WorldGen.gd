class_name WorldGen
extends RefCounted


static func generate(terrain: TerrainWorld, cfg: Dictionary, rng: RandomNumberGenerator) -> void:
	var mode: int = int(cfg.get("mode", GameState.WorldMode.GENERATED))
	if mode == GameState.WorldMode.EMPTY:
		_empty(terrain)
		return
	_continents(terrain, rng)
	_biomes(terrain, cfg, rng)
	_rivers(terrain, rng)
	terrain.rebuild_all()


static func _empty(terrain: TerrainWorld) -> void:
	var g := terrain.grid
	for z in range(g):
		for x in range(g):
			var dist := terrain.radial(x, z)
			var h := -2.6
			if dist > terrain.radius * 0.92:
				h = -4.0
			terrain.heights[terrain.idx(x, z)] = h
			terrain.biomes[terrain.idx(x, z)] = GameState.Biome.OCEAN
	terrain.rebuild_all()


static func _continents(terrain: TerrainWorld, rng: RandomNumberGenerator) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.018
	noise.fractal_octaves = 5
	var mountain := FastNoiseLite.new()
	mountain.seed = rng.randi()
	mountain.noise_type = FastNoiseLite.TYPE_SIMPLEX
	mountain.frequency = 0.035
	mountain.fractal_octaves = 3
	var detail := FastNoiseLite.new()
	detail.seed = rng.randi()
	detail.frequency = 0.08
	var g := terrain.grid
	var R := terrain.radius
	for z in range(g):
		for x in range(g):
			var w := terrain.grid_to_world(x, z)
			var dist := Vector2(w.x, w.y).length()
			var fall := clampf(1.0 - _falloff(R * 0.62, R * 0.96, dist), 0.0, 1.0)
			var n := noise.get_noise_2d(w.x, w.y)
			var m := mountain.get_noise_2d(w.x * 0.7, w.y * 0.7)
			var d := detail.get_noise_2d(w.x, w.y)
			var land: float = (n + 0.12) * 5.5 + max(0.0, m) * 9.0 * max(0.0, n + 0.05)
			land += d * 0.45
			land *= fall
			land -= 0.35
			if dist > R * 0.97:
				land = -5.0
			terrain.heights[terrain.idx(x, z)] = clampf(land, -6.0, 18.0)


static func _biomes(terrain: TerrainWorld, cfg: Dictionary, rng: RandomNumberGenerator) -> void:
	var selected: Array = cfg.get("biomes", [])
	if selected.is_empty():
		selected = [GameState.Biome.ARCTIC, GameState.Biome.TEMPERATE, GameState.Biome.GRASSLAND, GameState.Biome.TROPICAL]
	var n1 := FastNoiseLite.new()
	n1.seed = rng.randi()
	n1.frequency = 0.012
	var g := terrain.grid
	var R := terrain.radius
	var single: bool = selected.size() == 1
	for z in range(g):
		for x in range(g):
			var h := terrain.heights[terrain.idx(x, z)]
			if h < 0.05:
				terrain.biomes[terrain.idx(x, z)] = GameState.Biome.OCEAN
				continue
			if single:
				terrain.biomes[terrain.idx(x, z)] = int(selected[0])
				continue
			var w := terrain.grid_to_world(x, z)
			var lat := (w.y / R) # -1 south ... 1 north
			var n := n1.get_noise_2d(w.x, w.y)
			var b: int
			if lat > 0.55 + n * 0.1:
				b = GameState.Biome.ARCTIC
			elif lat < -0.45 + n * 0.1:
				b = GameState.Biome.TROPICAL
			elif h > 7.5:
				b = GameState.Biome.MOUNTAINOUS
			else:
				var t := (n + 1.0) * 0.5
				var idxb := int(floor(t * float(selected.size())))
				idxb = clampi(idxb, 0, selected.size() - 1)
				b = int(selected[idxb])
			if b == GameState.Biome.OCEAN:
				b = GameState.Biome.GRASSLAND
			# Prefer selected biomes if arctic/tropical not chosen
			if b == GameState.Biome.ARCTIC and not selected.has(GameState.Biome.ARCTIC):
				b = int(selected[0])
			if b == GameState.Biome.TROPICAL and not selected.has(GameState.Biome.TROPICAL):
				b = int(selected[mini(1, selected.size() - 1)])
			if h > 9.0 and selected.has(GameState.Biome.MOUNTAINOUS):
				b = GameState.Biome.MOUNTAINOUS
			if h > 8.0 and selected.has(GameState.Biome.VOLCANIC) and n > 0.45:
				b = GameState.Biome.VOLCANIC
			terrain.biomes[terrain.idx(x, z)] = b


static func _rivers(terrain: TerrainWorld, rng: RandomNumberGenerator) -> void:
	var count := 3 if terrain.grid >= 128 else 2
	for _i in range(count):
		var start := Vector3.ZERO
		var found := false
		for _t in range(20):
			var p := terrain.random_land_point(rng)
			if p.y > 5.0:
				start = p
				found = true
				break
		if not found:
			continue
		var pos := Vector2(start.x, start.z)
		for _s in range(80):
			var h := terrain.get_height(pos.x, pos.y)
			if h < 0.05:
				break
			var low := pos
			var low_h := h
			for k in range(8):
				var a := float(k) * TAU / 8.0
				var q := pos + Vector2(cos(a), sin(a)) * terrain.cell * 1.5
				var hh := terrain.get_height(q.x, q.y)
				if hh < low_h:
					low_h = hh
					low = q
			if low == pos:
				pos += Vector2(rng.randf() - 0.5, rng.randf() - 0.5) * 2.0
			else:
				pos = low
			terrain.brush(pos.x, pos.y, 1.6, 0.45, "lower")


static func _falloff(e0: float, e1: float, x: float) -> float:
	var t := clampf((x - e0) / max(e1 - e0, 0.0001), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
