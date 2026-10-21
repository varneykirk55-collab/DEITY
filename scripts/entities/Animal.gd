class_name Animal
extends Node3D

const SPECIES := {
	"deer": {"scale": 0.9, "color": Color(0.55, 0.38, 0.18), "speed": 3.2, "food": 3, "biomes": [4, 10, 5]},
	"wolf": {"scale": 0.75, "color": Color(0.45, 0.45, 0.48), "speed": 4.2, "food": 2, "biomes": [1, 3, 4, 9]},
	"bear": {"scale": 1.25, "color": Color(0.32, 0.20, 0.10), "speed": 2.6, "food": 5, "biomes": [4, 3, 9]},
	"polar_bear": {"scale": 1.3, "color": Color(0.92, 0.94, 0.96), "speed": 2.5, "food": 5, "biomes": [1]},
	"reindeer": {"scale": 1.0, "color": Color(0.62, 0.42, 0.22), "speed": 3.4, "food": 3, "biomes": [1]},
	"lion": {"scale": 1.05, "color": Color(0.80, 0.58, 0.22), "speed": 3.8, "food": 4, "biomes": [7, 10]},
	"zebra": {"scale": 1.0, "color": Color(0.9, 0.9, 0.88), "speed": 3.6, "food": 3, "biomes": [7]},
	"elephant": {"scale": 1.9, "color": Color(0.55, 0.55, 0.52), "speed": 2.2, "food": 8, "biomes": [7]},
	"monkey": {"scale": 0.55, "color": Color(0.45, 0.28, 0.16), "speed": 3.5, "food": 1, "biomes": [2, 5]},
	"boar": {"scale": 0.7, "color": Color(0.28, 0.18, 0.12), "speed": 3.0, "food": 3, "biomes": [2, 5, 4]},
	"bison": {"scale": 1.35, "color": Color(0.38, 0.24, 0.12), "speed": 2.8, "food": 5, "biomes": [10]},
	"goat": {"scale": 0.6, "color": Color(0.78, 0.76, 0.70), "speed": 3.3, "food": 2, "biomes": [3, 9]},
	"bird": {"scale": 0.35, "color": Color(0.2, 0.55, 0.85), "speed": 5.0, "food": 1, "biomes": [2, 5, 4]}
}

var id: int
var species: String = "deer"
var age: float = 1.0
var dead: bool = false
var mate_cd: float = 12.0
var think_t: float = 0.0
var target: Vector3 = Vector3.ZERO
var speed: float = 3.0
var food: int = 3
var rng := RandomNumberGenerator.new()
var _anim: float = 0.0
var _rig: Node3D
var _leg: Array = []


static func pick_for_biome(b: int, rng: RandomNumberGenerator) -> String:
	var opts: Array = []
	for k in SPECIES.keys():
		if b in SPECIES[k]["biomes"] or (b == GameState.Biome.GRASSLAND and k in ["deer", "bison"]):
			opts.append(k)
	if opts.is_empty():
		return ""
	return opts[rng.randi() % opts.size()]


func setup(p_id: int, p_species: String, pos: Vector3) -> void:
	id = p_id
	species = p_species if SPECIES.has(p_species) else "deer"
	rng.seed = p_id * 13 + 9
	age = rng.randf_range(0.5, 4.0)
	var spec: Dictionary = SPECIES[species]
	speed = spec["speed"]
	food = spec["food"]
	position = pos
	target = pos
	_build(spec)
	add_to_group("animals")


func _build(spec: Dictionary) -> void:
	_rig = Node3D.new()
	add_child(_rig)
	var scl: float = spec["scale"]
	_rig.scale = Vector3.ONE * scl
	var col: Color = spec["color"]
	Gfx.part(_rig, Gfx.sphere, Gfx.unshaded(Color(0, 0, 0, 0.3)), Vector3(0, 0.02, 0), Vector3(0.9, 0.06, 0.5), "Sh")
	Gfx.part(_rig, Gfx.box, Gfx.mat(col), Vector3(0, 0.42, 0), Vector3(0.85, 0.38, 0.42), "Body")
	var head := Gfx.part(_rig, Gfx.sphere, Gfx.mat(col.lightened(0.08)), Vector3(0, 0.55, 0.42), Vector3(0.36, 0.36, 0.36), "Head")
	if species == "elephant":
		Gfx.part(_rig, Gfx.cylinder, Gfx.mat(col), Vector3(0, 0.35, 0.62), Vector3(0.12, 0.7, 0.12), "Trunk").rotation.x = 0.6
		Gfx.part(_rig, Gfx.box, Gfx.mat(col.lightened(0.1)), Vector3(-0.32, 0.7, 0.2), Vector3(0.08, 0.35, 0.22), "EarL")
		Gfx.part(_rig, Gfx.box, Gfx.mat(col.lightened(0.1)), Vector3(0.32, 0.7, 0.2), Vector3(0.08, 0.35, 0.22), "EarR")
	if species == "zebra":
		Gfx.part(_rig, Gfx.box, Gfx.mat(Color(0.1, 0.1, 0.1)), Vector3(0, 0.5, 0.05), Vector3(0.86, 0.08, 0.44), "Stripe")
	if species == "lion":
		Gfx.part(_rig, Gfx.sphere, Gfx.mat(Color(0.72, 0.42, 0.12)), Vector3(0, 0.58, 0.38), Vector3(0.5, 0.5, 0.4), "Mane")
	if species in ["deer", "reindeer", "goat"]:
		Gfx.part(head, Gfx.box, Gfx.mat(Color(0.35, 0.25, 0.12)), Vector3(-0.12, 0.22, 0), Vector3(0.05, 0.35, 0.05), "AntL")
		Gfx.part(head, Gfx.box, Gfx.mat(Color(0.35, 0.25, 0.12)), Vector3(0.12, 0.22, 0), Vector3(0.05, 0.35, 0.05), "AntR")
	if species == "bird":
		_rig.position.y = 2.4
		Gfx.part(_rig, Gfx.box, Gfx.mat(col.darkened(0.2)), Vector3(-0.4, 0.5, 0), Vector3(0.5, 0.06, 0.25), "WingL")
		Gfx.part(_rig, Gfx.box, Gfx.mat(col.darkened(0.2)), Vector3(0.4, 0.5, 0), Vector3(0.5, 0.06, 0.25), "WingR")
	for i in range(4):
		var lx := -0.22 if i % 2 == 0 else 0.22
		var lz := -0.22 if i < 2 else 0.22
		var leg := Node3D.new()
		leg.position = Vector3(lx, 0.28, lz)
		_rig.add_child(leg)
		Gfx.part(leg, Gfx.box, Gfx.mat(col.darkened(0.15)), Vector3(0, -0.16, 0), Vector3(0.1, 0.32, 0.1), "Leg")
		_leg.append(leg)
	Gfx.part(_rig, Gfx.box, Gfx.mat(col.darkened(0.1)), Vector3(0, 0.45, -0.48), Vector3(0.08, 0.08, 0.28), "Tail")


func tick(sd: float, world: Node) -> void:
	if dead:
		return
	age += sd * 0.03
	mate_cd = max(0.0, mate_cd - sd)
	think_t -= sd
	if think_t <= 0.0:
		var ang := rng.randf() * TAU
		var rad := rng.randf_range(3.0, 14.0)
		target = global_position + Vector3(cos(ang) * rad, 0, sin(ang) * rad)
		if not world.terrain.is_land(target.x, target.z):
			target = global_position
		think_t = rng.randf_range(1.5, 4.0)
	var d := Vector3(target.x - global_position.x, 0, target.z - global_position.z)
	if d.length() > 0.4:
		d = d.normalized()
		var next := global_position + d * minf(speed * sd, global_position.distance_to(target))
		if species != "bird" and not world.terrain.is_land(next.x, next.z):
			think_t = 0
			return
		global_position = next
		if species != "bird":
			global_position.y = world.terrain.get_height(global_position.x, global_position.z)
		else:
			global_position.y = world.terrain.get_height(global_position.x, global_position.z) + 3.2 + sin(_anim) * 0.4
		rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), clampf(sd * 6.0, 0.0, 1.0))


func try_reproduce(world: Node, others: Array) -> void:
	if dead or mate_cd > 0.0 or age < 2.0:
		return
	if world.species_count(species) >= 28:
		return
	for o in others:
		if o == self or not is_instance_valid(o) or o.species != species or o.dead:
			continue
		if global_position.distance_to(o.global_position) < 6.0 and o.mate_cd <= 0.0:
			mate_cd = 28.0
			o.mate_cd = 28.0
			world.spawn_animal(species, global_position + Vector3(rng.randf() - 0.5, 0, rng.randf() - 0.5) * 2.0)
			return


func kill() -> void:
	if dead:
		return
	dead = true
	remove_from_group("animals")
	queue_free()


func _process(delta: float) -> void:
	_anim += GameState.sim_delta(delta) * 7.0
	if dead or _leg.is_empty():
		return
	for i in range(_leg.size()):
		_leg[i].rotation.x = sin(_anim + (PI if i % 2 == 0 else 0.0)) * 0.45


func serialize() -> Dictionary:
	return {"id": id, "species": species, "age": age, "x": global_position.x, "y": global_position.y, "z": global_position.z, "mate": mate_cd}
