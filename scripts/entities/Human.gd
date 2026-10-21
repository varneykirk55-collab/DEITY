class_name Human
extends Node3D

var id: int
var human_name: String = "Human"
var civ_id: int = -1
var tribe_seed: int = 0
var state: int = GameState.HumanState.IDLE
var age: float = 16.0
var lifespan: float = 62.0
var belief: float = 0.12
var heretic: bool = false
var infected: bool = false
var infect_t: float = 0.0
var warrior: bool = false
var gender: int = 0
var skin: Color
var hair: Color
var target: Vector3 = Vector3.ZERO
var target_node: Node3D = null
var walk_speed: float = 3.4
var work_t: float = 0.0
var think_t: float = 0.0
var dead: bool = false
var death_t: float = 0.0
var home: Vector3 = Vector3.ZERO
var torch: MeshInstance3D
var weapon: MeshInstance3D
var action_cd: float = 0.0

var _rig: Node3D
var _torso: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _head: MeshInstance3D
var _body: MeshInstance3D
var _anim: float = 0.0
var _plague_fx: MeshInstance3D
var _sash: MeshInstance3D
var _era_shown: int = -1
var _color_shown: Color = Color.TRANSPARENT
var _heretic_shown: bool = false
var _blocked_t: float = 0.0
var rng := RandomNumberGenerator.new()


func setup(p_id: int, pos: Vector3, p_tribe: int, p_rng: RandomNumberGenerator) -> void:
	id = p_id
	tribe_seed = p_tribe
	rng.seed = p_id * 9176 + 3
	gender = 0 if rng.randf() < 0.5 else 1
	human_name = Names.human(rng)
	age = rng.randf_range(14.0, 28.0)
	lifespan = rng.randf_range(52.0, 78.0)
	belief = rng.randf_range(0.05, 0.25)
	if rng.randf() < 0.06:
		heretic = true
		belief = 0.0
	var skins := [Color(0.95, 0.80, 0.66), Color(0.84, 0.65, 0.48), Color(0.62, 0.42, 0.28), Color(0.42, 0.28, 0.18), Color(0.92, 0.75, 0.58)]
	var hairs := [Color(0.12, 0.09, 0.07), Color(0.35, 0.22, 0.10), Color(0.55, 0.32, 0.12), Color(0.72, 0.55, 0.22), Color(0.35, 0.18, 0.12)]
	skin = skins[rng.randi() % skins.size()]
	hair = hairs[rng.randi() % hairs.size()]
	position = pos
	home = pos
	target = pos
	_build_rig()
	add_to_group("humans")


func _build_rig() -> void:
	_rig = Node3D.new()
	_rig.name = "Rig"
	add_child(_rig)
	# shadow
	Gfx.part(_rig, Gfx.sphere, Gfx.unshaded(Color(0, 0, 0, 0.35)), Vector3(0, 0.03, 0), Vector3(0.55, 0.05, 0.55), "Shadow")
	_leg_l = Node3D.new()
	_leg_l.position = Vector3(-0.12, 0.32, 0)
	_rig.add_child(_leg_l)
	Gfx.part(_leg_l, Gfx.box, Gfx.mat(skin.darkened(0.08)), Vector3(0, -0.16, 0), Vector3(0.14, 0.36, 0.16), "L")
	_leg_r = Node3D.new()
	_leg_r.position = Vector3(0.12, 0.32, 0)
	_rig.add_child(_leg_r)
	Gfx.part(_leg_r, Gfx.box, Gfx.mat(skin.darkened(0.08)), Vector3(0, -0.16, 0), Vector3(0.14, 0.36, 0.16), "R")
	_torso = Node3D.new()
	_torso.position = Vector3(0, 0.72, 0)
	_rig.add_child(_torso)
	_body = Gfx.part(_torso, Gfx.box, Gfx.mat(Color(0.45, 0.32, 0.18)), Vector3(0, 0, 0), Vector3(0.38, 0.48, 0.22), "Body")
	_sash = Gfx.part(_torso, Gfx.box, Gfx.mat(Color.WHITE), Vector3(0, 0.05, 0.12), Vector3(0.12, 0.42, 0.04), "Sash")
	_head = Gfx.part(_torso, Gfx.sphere, Gfx.mat(skin), Vector3(0, 0.42, 0), Vector3(0.34, 0.34, 0.34), "Head")
	Gfx.part(_torso, Gfx.sphere, Gfx.mat(hair), Vector3(0, 0.52, -0.02), Vector3(0.36, 0.22, 0.36), "Hair")
	_arm_l = Node3D.new()
	_arm_l.position = Vector3(-0.24, 0.16, 0)
	_torso.add_child(_arm_l)
	Gfx.part(_arm_l, Gfx.box, Gfx.mat(skin), Vector3(0, -0.16, 0), Vector3(0.12, 0.38, 0.12), "A")
	_arm_r = Node3D.new()
	_arm_r.position = Vector3(0.24, 0.16, 0)
	_torso.add_child(_arm_r)
	Gfx.part(_arm_r, Gfx.box, Gfx.mat(skin), Vector3(0, -0.16, 0), Vector3(0.12, 0.38, 0.12), "A")
	weapon = Gfx.part(_arm_r, Gfx.box, Gfx.mat(Color(0.45, 0.32, 0.16)), Vector3(0.0, -0.38, 0.12), Vector3(0.07, 0.46, 0.07), "Wep")
	weapon.visible = false
	torch = Gfx.part(_arm_r, Gfx.cylinder, Gfx.mat(Color(0.35, 0.2, 0.08), 0.7, 0.0, Color(1.0, 0.5, 0.1), 1.4), Vector3(0, -0.32, 0.1), Vector3(0.08, 0.5, 0.08), "Torch")
	torch.visible = false
	_plague_fx = Gfx.part(_torso, Gfx.sphere, Gfx.mat(Color(0.4, 1.0, 0.2, 0.35), 0.5, 0.0, Color(0.3, 1.0, 0.1), 0.8, true), Vector3(0, 0.2, 0), Vector3(0.7, 0.9, 0.7), "Plague")
	_plague_fx.visible = false


func apply_civ_visual(color: Color, era: int) -> void:
	if era == _era_shown and color == _color_shown and heretic == _heretic_shown:
		return
	_color_shown = color
	_heretic_shown = heretic
	if _sash:
		_sash.material_override = Gfx.mat(color)
	_era_shown = era
	var cloth := color.lerp(Color(0.4, 0.3, 0.2), 0.45)
	match era:
		GameState.Era.STONE:
			cloth = color.lerp(Color(0.45, 0.32, 0.18), 0.55)
			weapon.scale = Vector3(0.08, 0.4, 0.08)
			weapon.material_override = Gfx.mat(Color(0.4, 0.3, 0.16))
		GameState.Era.BRONZE:
			cloth = color.lerp(Color(0.55, 0.38, 0.18), 0.4)
			weapon.material_override = Gfx.mat(Color(0.78, 0.55, 0.18), 0.4, 0.55)
		GameState.Era.IRON:
			cloth = color.lerp(Color(0.28, 0.28, 0.30), 0.4)
			weapon.material_override = Gfx.mat(Color(0.55, 0.56, 0.58), 0.35, 0.7)
		GameState.Era.MEDIEVAL:
			cloth = color.lerp(Color(0.25, 0.18, 0.18), 0.3)
			weapon.material_override = Gfx.mat(Color(0.7, 0.7, 0.72), 0.3, 0.8)
		GameState.Era.RENAISSANCE:
			cloth = color.lerp(Color(0.45, 0.22, 0.28), 0.35)
		GameState.Era.INDUSTRIAL:
			cloth = color.lerp(Color(0.18, 0.18, 0.2), 0.4)
		GameState.Era.MODERN:
			cloth = color.lerp(Color(0.2, 0.25, 0.32), 0.3)
	if _body:
		_body.material_override = Gfx.mat(cloth)
	if heretic and _body:
		_body.material_override = Gfx.mat(Color(0.12, 0.10, 0.14))


func tick(sd: float, world: Node) -> void:
	if dead:
		death_t += sd
		rotation.x = lerp_angle(rotation.x, PI * 0.5, clampf(sd * 3.0, 0.0, 1.0))
		if death_t > 2.2:
			queue_free()
		return
	age += sd * 0.055
	if age >= lifespan:
		die("age")
		return
	if infected:
		infect_t += sd
		_plague_fx.visible = true
		belief = max(0.0, belief - sd * 0.02)
		if infect_t > 22.0:
			die("plague")
			return
	else:
		_plague_fx.visible = false
	think_t -= sd
	action_cd = max(0.0, action_cd - sd)
	if think_t <= 0.0:
		_think(world)
		think_t = rng.randf_range(0.35, 0.85)
	_act(sd, world)


func _think(world: Node) -> void:
	if state == GameState.HumanState.DIE:
		return
	if state in [GameState.HumanState.GATHER, GameState.HumanState.HUNT, GameState.HumanState.REBEL, GameState.HumanState.FIGHT] and is_instance_valid(target_node):
		return
	if state == GameState.HumanState.BUILD:
		return
	if heretic and world.settlement_has_temple(civ_id) and rng.randf() < 0.08:
		var temple: Node = world.nearest_temple(global_position, civ_id)
		if temple and global_position.distance_to(temple.global_position) < 40.0:
			target_node = temple
			target = temple.global_position
			state = GameState.HumanState.REBEL
			torch.visible = true
			return
	if warrior and world.civ_at_war(civ_id):
		var enemy: Human = world.nearest_enemy(self)
		if enemy:
			target_node = enemy
			target = enemy.global_position
			state = GameState.HumanState.FIGHT
			weapon.visible = true
			return
	var animal: Node = world.nearest_animal(global_position, 16.0)
	if animal and world.civ_needs_food(civ_id) and rng.randf() < 0.45:
		target_node = animal
		target = animal.global_position
		state = GameState.HumanState.HUNT
		weapon.visible = true
		return
	if world.civ_can_build(civ_id):
		var site: Vector3 = world.next_build_site(civ_id, global_position)
		if site.y > -900.0:
			target = site
			target_node = null
			state = GameState.HumanState.BUILD
			return
	var res: Node = world.nearest_resource(global_position, 40.0, civ_id)
	if res:
		target_node = res
		target = res.global_position
		state = GameState.HumanState.GATHER
		return
	# wander near home
	var ang := rng.randf() * TAU
	var rad := rng.randf_range(2.0, 10.0)
	target = home + Vector3(cos(ang) * rad, 0, sin(ang) * rad)
	target.y = world.terrain.get_height(target.x, target.z)
	target_node = null
	state = GameState.HumanState.WALK


func _act(sd: float, world: Node) -> void:
	match state:
		GameState.HumanState.WALK, GameState.HumanState.GATHER, GameState.HumanState.BUILD, GameState.HumanState.HUNT, GameState.HumanState.FIGHT, GameState.HumanState.FLEE, GameState.HumanState.REBEL:
			if is_instance_valid(target_node):
				target = target_node.global_position
			_move_towards(target, sd, world)
			var dist := Vector2(global_position.x - target.x, global_position.z - target.z).length()
			if dist < 1.15:
				_arrive(world)
		GameState.HumanState.IDLE:
			pass


func _move_towards(p: Vector3, sd: float, world: Node) -> void:
	var spd := walk_speed
	if state == GameState.HumanState.FLEE:
		spd *= 1.45
	if infected:
		spd *= 0.72
	var d := Vector3(p.x - global_position.x, 0, p.z - global_position.z)
	if d.length() < 0.05:
		return
	d = d.normalized()
	var step := minf(spd * sd, global_position.distance_to(p))
	var next := global_position + d * step
	if not world.terrain.is_land(next.x, next.z):
		var found := false
		for angle in [0.6, -0.6, 1.2, -1.2]:
			var side := d.rotated(Vector3.UP, angle)
			var candidate := global_position + side * step
			if world.terrain.is_land(candidate.x, candidate.z):
				d = side
				next = candidate
				found = true
				break
		if not found:
			_blocked_t += sd
			if _blocked_t > 1.5:
				state = GameState.HumanState.IDLE
				target_node = null
				think_t = 0
			return
	_blocked_t = 0
	global_position = next
	var h: float = world.terrain.get_height(global_position.x, global_position.z)
	if h < 0.05:
		# step back onto land
		global_position -= d * step
		h = world.terrain.get_height(global_position.x, global_position.z)
	global_position.y = h
	var yaw := atan2(d.x, d.z)
	rotation.y = lerp_angle(rotation.y, yaw, clampf(sd * 8.0, 0.0, 1.0))


func _arrive(world: Node) -> void:
	if action_cd > 0.0:
		return
	match state:
		GameState.HumanState.GATHER:
			if is_instance_valid(target_node) and target_node.has_method("gather"):
				var kind: String = target_node.gather()
				world.add_resource(civ_id, kind, 1)
				world.float_text(global_position + Vector3(0, 1.6, 0), "+" + kind, Color(0.85, 0.95, 0.55))
			action_cd = 0.7
			state = GameState.HumanState.IDLE
		GameState.HumanState.BUILD:
			world.contribute_build(civ_id, global_position)
			world.float_text(global_position + Vector3(0, 1.6, 0), "build", Color(0.9, 0.8, 0.4))
			action_cd = 0.8
			state = GameState.HumanState.IDLE
		GameState.HumanState.HUNT:
			if is_instance_valid(target_node) and target_node.has_method("kill"):
				target_node.kill()
				world.add_resource(civ_id, "food", 4)
				world.float_text(global_position + Vector3(0, 1.6, 0), "+food", Color(0.95, 0.55, 0.4))
			weapon.visible = false
			action_cd = 0.6
			state = GameState.HumanState.IDLE
		GameState.HumanState.FIGHT:
			if is_instance_valid(target_node) and target_node is Human:
				var e: Human = target_node
				if rng.randf() < 0.45:
					e.hurt(self)
				action_cd = 0.55
				if e.dead:
					state = GameState.HumanState.IDLE
					weapon.visible = false
			else:
				state = GameState.HumanState.IDLE
				weapon.visible = false
		GameState.HumanState.REBEL:
			if is_instance_valid(target_node) and target_node.has_method("burn"):
				target_node.burn()
				world.float_text(global_position + Vector3(0, 1.8, 0), "heresy", Color(0.9, 0.3, 0.1))
			torch.visible = false
			action_cd = 1.0
			state = GameState.HumanState.IDLE
		GameState.HumanState.WALK, GameState.HumanState.FLEE:
			state = GameState.HumanState.IDLE


func hurt(_from: Human) -> void:
	if dead:
		return
	if rng.randf() < 0.5:
		die("war")
	else:
		state = GameState.HumanState.FLEE
		var a := rng.randf() * TAU
		target = global_position + Vector3(cos(a), 0, sin(a)) * 12.0


func die(_why: String = "") -> void:
	if dead:
		return
	dead = true
	state = GameState.HumanState.DIE
	death_t = 0.0
	weapon.visible = false
	torch.visible = false
	remove_from_group("humans")


func infect() -> void:
	if dead or infected:
		return
	infected = true
	infect_t = 0.0
	_plague_fx.visible = true


func cure() -> void:
	infected = false
	infect_t = 0.0
	_plague_fx.visible = false


func _process(delta: float) -> void:
	var sd := GameState.sim_delta(delta)
	# Dead humans leave the simulation group, so finish cleanup here.
	if dead:
		tick(sd, null)
		return
	if sd <= 0.0 and not dead:
		return
	_anim += max(delta, sd) * 6.0
	_animate()


func _animate() -> void:
	if _rig == null:
		return
	if dead:
		return
	var moving := state in [GameState.HumanState.WALK, GameState.HumanState.GATHER, GameState.HumanState.BUILD, GameState.HumanState.HUNT, GameState.HumanState.FIGHT, GameState.HumanState.FLEE, GameState.HumanState.REBEL]
	if moving and state != GameState.HumanState.FIGHT and state != GameState.HumanState.BUILD and state != GameState.HumanState.GATHER:
		_leg_l.rotation.x = sin(_anim * 1.6) * 0.55
		_leg_r.rotation.x = sin(_anim * 1.6 + PI) * 0.55
		_arm_l.rotation.x = sin(_anim * 1.6 + PI) * 0.45
		_arm_r.rotation.x = sin(_anim * 1.6) * 0.45
		_rig.position.y = abs(sin(_anim * 1.6)) * 0.05
	elif state == GameState.HumanState.GATHER or state == GameState.HumanState.BUILD:
		_arm_r.rotation.x = -0.3 + sin(_anim * 2.2) * 0.8
		_leg_l.rotation.x = 0.1
		_leg_r.rotation.x = -0.05
	elif state == GameState.HumanState.FIGHT or state == GameState.HumanState.REBEL:
		_arm_r.rotation.x = -0.9 + sin(_anim * 2.8) * 1.0
		_arm_l.rotation.x = 0.4
	else:
		_leg_l.rotation.x = lerp_angle(_leg_l.rotation.x, 0.0, 0.15)
		_leg_r.rotation.x = lerp_angle(_leg_r.rotation.x, 0.0, 0.15)
		_arm_l.rotation.x = lerp_angle(_arm_l.rotation.x, 0.05, 0.1)
		_arm_r.rotation.x = lerp_angle(_arm_r.rotation.x, 0.05, 0.1)
		_rig.position.y = sin(_anim * 0.35) * 0.02


func serialize() -> Dictionary:
	return {
		"id": id, "name": human_name, "civ": civ_id, "tribe": tribe_seed,
		"age": age, "life": lifespan, "belief": belief, "heretic": heretic,
		"infected": infected, "infect_t": infect_t, "warrior": warrior,
		"x": global_position.x, "y": global_position.y, "z": global_position.z,
		"home_x": home.x, "home_y": home.y, "home_z": home.z, "gender": gender
	}
