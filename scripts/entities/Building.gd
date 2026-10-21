class_name Building
extends Node3D

enum Kind { HUT, HOUSE, HALL, WALL, TEMPLE, SHRINE, CASTLE, WORKSHOP, TOWER }

var id: int
var civ_id: int = -1
var kind: int = Kind.HUT
var era: int = 0
var hp: float = 10.0
var burning: bool = false
var burn_t: float = 0.0
var complete: float = 1.0
var _root: Node3D
var _fire: MeshInstance3D


func setup(p_id: int, p_civ: int, p_kind: int, p_era: int, pos: Vector3, color: Color) -> void:
	id = p_id
	civ_id = p_civ
	kind = p_kind
	era = p_era
	position = pos
	_root = Node3D.new()
	add_child(_root)
	_build_mesh(color)
	add_to_group("buildings")
	if kind == Kind.TEMPLE or kind == Kind.SHRINE:
		add_to_group("temples")


func _build_mesh(color: Color) -> void:
	for c in _root.get_children():
		c.queue_free()
	var wall := color.lerp(Color(0.55, 0.45, 0.32), 0.35)
	var roof := Color(0.55, 0.22, 0.16)
	var stone := Color(0.55, 0.52, 0.48)
	match era:
		GameState.Era.STONE:
			wall = Color(0.50, 0.40, 0.25)
			roof = Color(0.35, 0.28, 0.16)
		GameState.Era.BRONZE:
			wall = Color(0.62, 0.48, 0.30)
			roof = Color(0.55, 0.28, 0.14)
		GameState.Era.IRON:
			wall = stone
			roof = Color(0.40, 0.22, 0.16)
		GameState.Era.MEDIEVAL:
			wall = Color(0.58, 0.56, 0.52)
			roof = Color(0.45, 0.16, 0.14)
		GameState.Era.RENAISSANCE:
			wall = Color(0.78, 0.70, 0.52)
			roof = Color(0.35, 0.38, 0.22)
		GameState.Era.INDUSTRIAL:
			wall = Color(0.35, 0.35, 0.36)
			roof = Color(0.22, 0.22, 0.24)
		GameState.Era.MODERN:
			wall = Color(0.72, 0.78, 0.82)
			roof = Color(0.18, 0.22, 0.28)
	wall = wall.lerp(color, 0.22)
	match kind:
		Kind.HUT, Kind.HOUSE:
			var w := 1.6 if kind == Kind.HOUSE else 1.15
			var h := 1.1 if kind == Kind.HOUSE else 0.85
			Gfx.part(_root, Gfx.box, Gfx.mat(wall), Vector3(0, h * 0.5, 0), Vector3(w, h, w * 0.9), "W")
			var roof_mi := Gfx.part(_root, Gfx.prism, Gfx.mat(roof), Vector3(0, h + 0.35, 0), Vector3(w * 1.15, 0.7, w), "R")
			roof_mi.rotation.y = 0
			Gfx.part(_root, Gfx.box, Gfx.mat(Color(0.2, 0.12, 0.08)), Vector3(0, 0.35, w * 0.46), Vector3(0.28, 0.55, 0.08), "Door")
		Kind.HALL, Kind.WORKSHOP:
			Gfx.part(_root, Gfx.box, Gfx.mat(wall), Vector3(0, 1.0, 0), Vector3(3.2, 2.0, 2.2), "W")
			Gfx.part(_root, Gfx.prism, Gfx.mat(roof), Vector3(0, 2.3, 0), Vector3(3.5, 0.9, 2.4), "R")
			Gfx.part(_root, Gfx.box, Gfx.mat(color), Vector3(0, 2.8, 0), Vector3(0.2, 0.8, 0.2), "Spire")
		Kind.SHRINE:
			Gfx.part(_root, Gfx.box, Gfx.mat(stone), Vector3(0, 0.4, 0), Vector3(1.1, 0.8, 1.1), "Base")
			Gfx.part(_root, Gfx.cylinder, Gfx.mat(Color(0.85, 0.75, 0.35), 0.4, 0.4, Color(1.0, 0.9, 0.4), 0.4), Vector3(0, 1.2, 0), Vector3(0.25, 1.4, 0.25), "Pillar")
			Gfx.part(_root, Gfx.sphere, Gfx.mat(Color(1.0, 0.9, 0.4), 0.3, 0.2, Color(1.0, 0.85, 0.3), 0.8), Vector3(0, 2.05, 0), Vector3(0.45, 0.45, 0.45), "Orb")
		Kind.TEMPLE:
			Gfx.part(_root, Gfx.box, Gfx.mat(wall), Vector3(0, 1.1, 0), Vector3(3.4, 2.2, 2.6), "W")
			Gfx.part(_root, Gfx.prism, Gfx.mat(Color(0.92, 0.78, 0.28)), Vector3(0, 2.6, 0), Vector3(3.8, 1.2, 2.9), "R")
			for i in range(-1, 2):
				Gfx.part(_root, Gfx.cylinder, Gfx.mat(Color(0.85, 0.8, 0.65)), Vector3(float(i) * 0.9, 1.0, 1.35), Vector3(0.22, 2.0, 0.22), "C")
			Gfx.part(_root, Gfx.sphere, Gfx.mat(Color(1.0, 0.88, 0.3), 0.3, 0.2, Color(1.0, 0.9, 0.4), 1.0), Vector3(0, 3.5, 0), Vector3(0.5, 0.5, 0.5), "Sun")
		Kind.CASTLE, Kind.TOWER:
			Gfx.part(_root, Gfx.box, Gfx.mat(stone), Vector3(0, 1.6, 0), Vector3(3.6, 3.2, 3.6), "Keep")
			Gfx.part(_root, Gfx.box, Gfx.mat(stone.darkened(0.1)), Vector3(-1.6, 2.6, -1.6), Vector3(1.1, 5.2, 1.1), "T1")
			Gfx.part(_root, Gfx.box, Gfx.mat(stone.darkened(0.1)), Vector3(1.6, 2.6, 1.6), Vector3(1.1, 5.2, 1.1), "T2")
			Gfx.part(_root, Gfx.box, Gfx.mat(color), Vector3(0, 3.4, 0.05), Vector3(0.2, 1.2, 0.08), "Banner")
			Gfx.part(_root, Gfx.prism, Gfx.mat(roof), Vector3(0, 3.5, 0), Vector3(3.9, 0.8, 3.9), "R")
		Kind.WALL:
			Gfx.part(_root, Gfx.box, Gfx.mat(stone), Vector3(0, 0.7, 0), Vector3(3.4, 1.4, 0.45), "W")
	_fire = Gfx.part(_root, Gfx.sphere, Gfx.mat(Color(1.0, 0.45, 0.1, 0.7), 0.4, 0.0, Color(1.0, 0.4, 0.05), 2.0, true), Vector3(0, 1.4, 0), Vector3(1.6, 1.8, 1.6), "Fire")
	_fire.visible = false


func restyle(new_era: int, color: Color) -> void:
	era = new_era
	_build_mesh(color)


func burn() -> void:
	burning = true
	if _fire:
		_fire.visible = true


func _process(delta: float) -> void:
	if not burning:
		return
	var sd := GameState.sim_delta(delta)
	burn_t += sd
	if _fire:
		_fire.scale = Vector3.ONE * (1.4 + sin(Time.get_ticks_msec() * 0.01) * 0.2)
	if burn_t > 4.0:
		remove_from_group("buildings")
		remove_from_group("temples")
		queue_free()


func serialize() -> Dictionary:
	return {
		"id": id, "civ": civ_id, "kind": kind, "era": era,
		"x": global_position.x, "y": global_position.y, "z": global_position.z,
		"hp": hp, "burning": burning, "burn_t": burn_t
	}
