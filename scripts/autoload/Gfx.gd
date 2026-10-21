extends Node
## Shared materials, primitive meshes, and tiny runtime icons.

var box: BoxMesh
var sphere: SphereMesh
var sphere_hi: SphereMesh
var cylinder: CylinderMesh
var cone: CylinderMesh
var prism: PrismMesh
var plane: PlaneMesh
var cap: CapsuleMesh

var _mats: Dictionary = {}
var _icons: Dictionary = {}
var terrain_shader: Shader
var water_shader: Shader
var lava_shader: Shader


func _ready() -> void:
	box = BoxMesh.new()
	box.size = Vector3.ONE
	sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 8
	sphere.rings = 4
	sphere_hi = SphereMesh.new()
	sphere_hi.radius = 0.5
	sphere_hi.height = 1.0
	sphere_hi.radial_segments = 14
	sphere_hi.rings = 8
	cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.5
	cylinder.height = 1.0
	cylinder.radial_segments = 8
	cylinder.rings = 1
	cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.5
	cone.height = 1.0
	cone.radial_segments = 8
	prism = PrismMesh.new()
	prism.size = Vector3.ONE
	plane = PlaneMesh.new()
	plane.size = Vector2.ONE
	cap = CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.2
	cap.radial_segments = 8
	terrain_shader = load("res://assets/shaders/terrain.gdshader")
	water_shader = load("res://assets/shaders/water.gdshader")
	lava_shader = load("res://assets/shaders/lava.gdshader")


func mat(color: Color, roughness: float = 0.82, metallic: float = 0.0, emit: Color = Color(0, 0, 0, 1), emit_e: float = 0.0, trans: bool = false) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f|%s|%.1f|%s" % [color, roughness, metallic, emit, emit_e, trans]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	if emit_e > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_e
	if trans:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats[key] = m
	return m


func unshaded(color: Color) -> StandardMaterial3D:
	var key := "u|%s" % color
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 0.99 else BaseMaterial3D.TRANSPARENCY_DISABLED
	_mats[key] = m
	return m


func terrain_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = terrain_shader
	return m


func water_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = water_shader
	return m


func lava_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = lava_shader
	return m


func part(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3, scl: Vector3, n: String = "Part") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi


func icon(kind: String, col: Color = Color.WHITE) -> Texture2D:
	var key := "%s|%s" % [kind, col]
	if _icons.has(key):
		return _icons[key]
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ink := Color(col.r, col.g, col.b, 1)
	match kind:
		"raise":
			_tri(img, Vector2i(16, 4), Vector2i(6, 26), Vector2i(26, 26), ink)
		"lower":
			_tri(img, Vector2i(16, 28), Vector2i(6, 6), Vector2i(26, 6), ink)
		"mountain":
			_tri(img, Vector2i(10, 26), Vector2i(16, 8), Vector2i(22, 26), ink)
			_tri(img, Vector2i(18, 26), Vector2i(24, 12), Vector2i(30, 26), Color(ink.r * 0.8, ink.g * 0.8, ink.b * 0.8))
		"valley":
			_rect(img, 4, 18, 24, 8, ink)
			_tri(img, Vector2i(4, 18), Vector2i(16, 8), Vector2i(28, 18), Color(ink.r, ink.g, ink.b, 0.5))
		"island":
			_ellipse(img, 16, 18, 12, 7, ink)
			_rect(img, 12, 10, 8, 8, Color(0.3, 0.7, 0.3))
		"lake":
			_ellipse(img, 16, 16, 11, 8, Color(0.2, 0.5, 0.85))
		"river":
			_rect(img, 14, 4, 4, 24, Color(0.2, 0.5, 0.9))
		"paint":
			_rect(img, 8, 8, 16, 16, ink)
			_rect(img, 20, 6, 6, 10, Color(0.8, 0.8, 0.8))
		"forest":
			_tri(img, Vector2i(10, 24), Vector2i(10, 8), Vector2i(22, 24), Color(0.2, 0.55, 0.2))
			_tri(img, Vector2i(18, 24), Vector2i(22, 10), Vector2i(28, 24), Color(0.18, 0.45, 0.18))
		"veg":
			_rect(img, 15, 14, 3, 12, Color(0.4, 0.25, 0.1))
			_ellipse(img, 16, 12, 8, 8, Color(0.3, 0.7, 0.25))
		"volcano":
			_tri(img, Vector2i(16, 6), Vector2i(4, 28), Vector2i(28, 28), Color(0.3, 0.25, 0.22))
			_rect(img, 14, 4, 4, 6, Color(1.0, 0.4, 0.1))
		"tree":
			_rect(img, 14, 18, 4, 10, Color(0.4, 0.25, 0.12))
			_ellipse(img, 16, 14, 9, 9, Color(0.22, 0.6, 0.22))
		"animal":
			_ellipse(img, 16, 18, 10, 6, ink)
			_ellipse(img, 24, 14, 5, 5, ink)
		"human":
			_ellipse(img, 16, 8, 4, 4, Color(0.95, 0.8, 0.65))
			_rect(img, 12, 13, 8, 10, ink)
			_rect(img, 12, 23, 3, 7, ink)
			_rect(img, 17, 23, 3, 7, ink)
		"group":
			_rect(img, 6, 14, 6, 12, ink)
			_rect(img, 13, 10, 6, 16, ink)
			_rect(img, 20, 14, 6, 12, ink)
		"inspect":
			_ellipse(img, 13, 13, 8, 8, Color(0.9, 0.9, 0.9, 0.0))
			_ring(img, 13, 13, 8, ink)
			_rect(img, 20, 20, 8, 3, ink)
		"tech":
			_rect(img, 8, 20, 16, 6, ink)
			_rect(img, 14, 8, 4, 12, ink)
		"boost":
			_tri(img, Vector2i(16, 4), Vector2i(8, 16), Vector2i(24, 16), ink)
			_tri(img, Vector2i(16, 14), Vector2i(8, 28), Vector2i(24, 28), ink)
		"lightning":
			_tri(img, Vector2i(18, 2), Vector2i(8, 16), Vector2i(16, 16), Color(1.0, 0.95, 0.4))
			_tri(img, Vector2i(14, 16), Vector2i(22, 16), Vector2i(10, 30), Color(1.0, 0.95, 0.4))
		"tornado":
			_tri(img, Vector2i(16, 4), Vector2i(6, 28), Vector2i(26, 28), Color(0.7, 0.75, 0.8))
		"meteor":
			_ellipse(img, 20, 12, 7, 7, Color(1.0, 0.55, 0.15))
			_tri(img, Vector2i(4, 26), Vector2i(16, 8), Vector2i(14, 20), Color(1.0, 0.8, 0.2))
		"kill":
			_rect(img, 6, 14, 20, 4, Color(0.8, 0.15, 0.15))
			_rect(img, 14, 6, 4, 20, Color(0.8, 0.15, 0.15))
		"rain":
			_ellipse(img, 16, 10, 10, 6, Color(0.7, 0.75, 0.8))
			_rect(img, 10, 16, 2, 8, Color(0.4, 0.65, 1.0))
			_rect(img, 16, 18, 2, 8, Color(0.4, 0.65, 1.0))
			_rect(img, 22, 16, 2, 8, Color(0.4, 0.65, 1.0))
		"storm":
			_ellipse(img, 16, 10, 11, 6, Color(0.35, 0.38, 0.45))
			_tri(img, Vector2i(16, 16), Vector2i(12, 28), Vector2i(18, 22), Color(1.0, 0.95, 0.3))
		"snow":
			_rect(img, 15, 6, 2, 20, Color(0.9, 0.95, 1.0))
			_rect(img, 6, 15, 20, 2, Color(0.9, 0.95, 1.0))
		"miracle":
			_ellipse(img, 16, 16, 10, 10, Color(1.0, 0.9, 0.35))
			_rect(img, 15, 6, 2, 20, Color(1, 1, 1))
			_rect(img, 6, 15, 20, 2, Color(1, 1, 1))
		"plague":
			_ellipse(img, 16, 16, 10, 10, Color(0.35, 0.85, 0.2))
			_rect(img, 14, 10, 4, 12, Color(0.1, 0.3, 0.1))
		"cure":
			_ellipse(img, 16, 16, 11, 11, Color(0.4, 0.85, 0.95))
			_rect(img, 14, 8, 4, 16, Color(1, 1, 1))
			_rect(img, 8, 14, 16, 4, Color(1, 1, 1))
		"pause":
			_rect(img, 8, 6, 6, 20, ink)
			_rect(img, 18, 6, 6, 20, ink)
		"play":
			_tri(img, Vector2i(8, 4), Vector2i(8, 28), Vector2i(26, 16), ink)
		"fast":
			_tri(img, Vector2i(4, 6), Vector2i(4, 26), Vector2i(16, 16), ink)
			_tri(img, Vector2i(14, 6), Vector2i(14, 26), Vector2i(28, 16), ink)
		"veryfast":
			_tri(img, Vector2i(2, 8), Vector2i(2, 24), Vector2i(12, 16), ink)
			_tri(img, Vector2i(10, 8), Vector2i(10, 24), Vector2i(20, 16), ink)
			_tri(img, Vector2i(18, 8), Vector2i(18, 24), Vector2i(28, 16), ink)
		"temple":
			_rect(img, 6, 20, 20, 8, ink)
			_tri(img, Vector2i(16, 4), Vector2i(6, 20), Vector2i(26, 20), Color(0.95, 0.85, 0.4))
		_:
			_rect(img, 8, 8, 16, 16, ink)
	var tex := ImageTexture.create_from_image(img)
	_icons[key] = tex
	return tex


func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for iy in range(y, mini(32, y + h)):
		for ix in range(x, mini(32, x + w)):
			if ix >= 0 and iy >= 0:
				img.set_pixel(ix, iy, c)


func _ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	for iy in range(cy - ry, cy + ry + 1):
		for ix in range(cx - rx, cx + rx + 1):
			if ix < 0 or iy < 0 or ix >= 32 or iy >= 32:
				continue
			var dx := float(ix - cx) / float(max(rx, 1))
			var dy := float(iy - cy) / float(max(ry, 1))
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(ix, iy, c)


func _ring(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for iy in range(cy - r, cy + r + 1):
		for ix in range(cx - r, cx + r + 1):
			if ix < 0 or iy < 0 or ix >= 32 or iy >= 32:
				continue
			var d := Vector2(ix - cx, iy - cy).length()
			if d <= float(r) and d >= float(r) - 2.2:
				img.set_pixel(ix, iy, c)


func _tri(img: Image, a: Vector2i, b: Vector2i, c: Vector2i, col: Color) -> void:
	var minx := mini(a.x, mini(b.x, c.x))
	var maxx := maxi(a.x, maxi(b.x, c.x))
	var miny := mini(a.y, mini(b.y, c.y))
	var maxy := maxi(a.y, maxi(b.y, c.y))
	for y in range(miny, maxy + 1):
		for x in range(minx, maxx + 1):
			if x < 0 or y < 0 or x >= 32 or y >= 32:
				continue
			if _inside(Vector2(x, y), Vector2(a), Vector2(b), Vector2(c)):
				img.set_pixel(x, y, col)


func _inside(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var v0 := c - a
	var v1 := b - a
	var v2 := p - a
	var den := v0.x * v1.y - v1.x * v0.y
	if abs(den) < 0.0001:
		return false
	var u := (v2.x * v1.y - v1.x * v2.y) / den
	var v := (v0.x * v2.y - v2.x * v0.y) / den
	return u >= 0.0 and v >= 0.0 and (u + v) <= 1.0
