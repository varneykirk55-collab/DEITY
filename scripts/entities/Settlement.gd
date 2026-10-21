class_name Settlement
extends Node3D

var id: int
var civ_id: int = -1
var settle_name: String = "Camp"
var population: int = 0
var has_temple: bool = false
var belief_avg: float = 0.1
var heretic_count: int = 0
var build_progress: float = 0.0
var next_kind: int = Building.Kind.HUT
var label: Label3D
var banner: MeshInstance3D
var radius: float = 10.0


func setup(p_id: int, p_civ: int, p_name: String, pos: Vector3, color: Color) -> void:
	id = p_id
	civ_id = p_civ
	settle_name = p_name
	position = pos
	label = Label3D.new()
	label.text = settle_name
	label.font_size = 42
	label.outline_size = 12
	label.modulate = Color.WHITE
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.position = Vector3(0, 6.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)
	banner = Gfx.part(self, Gfx.box, Gfx.mat(color), Vector3(0, 4.2, 0), Vector3(0.12, 4.4, 0.12), "Pole")
	Gfx.part(self, Gfx.box, Gfx.mat(color), Vector3(0.45, 5.6, 0), Vector3(0.9, 0.55, 0.06), "Flag")
	add_to_group("settlements")


func refresh_label(pop: int, era_name: String) -> void:
	population = pop
	if label:
		label.text = "%s\n%d  •  %s" % [settle_name, pop, era_name]


func serialize() -> Dictionary:
	return {
		"id": id, "civ": civ_id, "name": settle_name,
		"x": global_position.x, "y": global_position.y, "z": global_position.z,
		"has_temple": has_temple, "build": build_progress, "next": next_kind, "radius": radius
	}
