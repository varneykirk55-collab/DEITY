class_name ResourceNode
extends Node3D

var id: int
var kind: String = "wood" # wood, stone, ore
var tree_type: String = "oak"
var depleted_visual: bool = false


func setup(p_id: int, p_kind: String, pos: Vector3, ttype: String = "oak") -> void:
	id = p_id
	kind = p_kind
	tree_type = ttype
	position = pos
	_build()
	add_to_group("resources")


func _build() -> void:
	match kind:
		"wood":
			_tree()
		"stone":
			Gfx.part(self, Gfx.sphere, Gfx.mat(Color(0.55, 0.53, 0.50)), Vector3(0, 0.35, 0), Vector3(1.1, 0.7, 0.9), "R1")
			Gfx.part(self, Gfx.sphere, Gfx.mat(Color(0.48, 0.46, 0.44)), Vector3(0.35, 0.22, 0.15), Vector3(0.6, 0.45, 0.55), "R2")
		"ore":
			Gfx.part(self, Gfx.sphere, Gfx.mat(Color(0.40, 0.38, 0.36)), Vector3(0, 0.3, 0), Vector3(0.9, 0.55, 0.8), "R")
			Gfx.part(self, Gfx.box, Gfx.mat(Color(0.55, 0.45, 0.18), 0.4, 0.6, Color(0.8, 0.6, 0.2), 0.3), Vector3(0.1, 0.4, 0.1), Vector3(0.35, 0.25, 0.35), "Vein")


func _tree() -> void:
	var trunk_col := Color(0.40, 0.26, 0.12)
	var leaf := Color(0.22, 0.50, 0.18)
	var trunk_h := 1.8
	var leaf_s := Vector3(1.6, 1.4, 1.6)
	match tree_type:
		"pine":
			trunk_h = 2.4
			leaf = Color(0.12, 0.38, 0.22)
			Gfx.part(self, Gfx.cylinder, Gfx.mat(trunk_col), Vector3(0, trunk_h * 0.5, 0), Vector3(0.22, trunk_h, 0.22), "T")
			Gfx.part(self, Gfx.cone, Gfx.mat(leaf), Vector3(0, trunk_h + 0.2, 0), Vector3(1.5, 2.4, 1.5), "L1")
			Gfx.part(self, Gfx.cone, Gfx.mat(leaf.lightened(0.08)), Vector3(0, trunk_h + 1.1, 0), Vector3(1.1, 1.8, 1.1), "L2")
			return
		"palm":
			trunk_h = 2.6
			trunk_col = Color(0.45, 0.32, 0.14)
			leaf = Color(0.18, 0.55, 0.22)
			Gfx.part(self, Gfx.cylinder, Gfx.mat(trunk_col), Vector3(0, trunk_h * 0.5, 0), Vector3(0.2, trunk_h, 0.2), "T")
			for i in range(5):
				var a := float(i) / 5.0 * TAU
				var p := Gfx.part(self, Gfx.box, Gfx.mat(leaf), Vector3(cos(a) * 0.7, trunk_h + 0.1, sin(a) * 0.7), Vector3(0.9, 0.08, 0.35), "P")
				p.rotation.y = a
			return
		"acacia":
			leaf = Color(0.42, 0.55, 0.16)
			leaf_s = Vector3(2.2, 0.7, 2.2)
			trunk_h = 2.1
		"jungle":
			leaf = Color(0.10, 0.40, 0.14)
			leaf_s = Vector3(2.0, 1.8, 2.0)
			trunk_h = 2.8
		"cactus":
			Gfx.part(self, Gfx.cylinder, Gfx.mat(Color(0.28, 0.52, 0.22)), Vector3(0, 1.0, 0), Vector3(0.35, 2.0, 0.35), "C")
			Gfx.part(self, Gfx.cylinder, Gfx.mat(Color(0.28, 0.52, 0.22)), Vector3(0.35, 1.1, 0), Vector3(0.18, 0.8, 0.18), "A")
			return
		"dead":
			Gfx.part(self, Gfx.cylinder, Gfx.mat(Color(0.25, 0.2, 0.16)), Vector3(0, 1.0, 0), Vector3(0.2, 2.0, 0.2), "T")
			Gfx.part(self, Gfx.box, Gfx.mat(Color(0.22, 0.18, 0.14)), Vector3(0.3, 1.6, 0), Vector3(0.7, 0.08, 0.08), "B")
			return
	Gfx.part(self, Gfx.cylinder, Gfx.mat(trunk_col), Vector3(0, trunk_h * 0.5, 0), Vector3(0.28, trunk_h, 0.28), "T")
	Gfx.part(self, Gfx.sphere, Gfx.mat(leaf), Vector3(0, trunk_h + 0.4, 0), leaf_s, "L")


func gather() -> String:
	# Source remains; only production is granted.
	return kind


func serialize() -> Dictionary:
	return {"id": id, "kind": kind, "type": tree_type, "x": global_position.x, "y": global_position.y, "z": global_position.z}


static func tree_for_biome(b: int) -> String:
	match b:
		GameState.Biome.ARCTIC, GameState.Biome.MOUNTAINOUS:
			return "pine"
		GameState.Biome.TROPICAL:
			return "palm"
		GameState.Biome.RAINFOREST:
			return "jungle"
		GameState.Biome.SAVANNA:
			return "acacia"
		GameState.Biome.DESERT:
			return "cactus"
		GameState.Biome.VOLCANIC:
			return "dead"
		_:
			return "oak"
