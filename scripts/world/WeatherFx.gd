class_name WeatherFx
extends Node3D

var rain: GPUParticles3D
var snow: GPUParticles3D
var storm_light: OmniLight3D
var mode: String = "clear"
var local_override: String = ""
var local_t: float = 0.0
var _flash_t: float = 0.0


func setup(radius: float) -> void:
	rain = _make_particles(Color(0.65, 0.75, 0.95, 0.7), Vector3(0, -1, 0), 14.0, 900, Vector2(0.04, 0.35), radius)
	snow = _make_particles(Color(0.95, 0.96, 1.0, 0.85), Vector3(0.15, -1, 0.05), 4.0, 700, Vector2(0.08, 0.08), radius)
	rain.emitting = false
	snow.emitting = false
	storm_light = OmniLight3D.new()
	storm_light.light_color = Color(0.75, 0.85, 1.0)
	storm_light.light_energy = 0.0
	storm_light.omni_range = radius
	storm_light.position = Vector3(0, 28, 0)
	add_child(storm_light)


func _make_particles(col: Color, dir: Vector3, speed: float, amount: int, size: Vector2, radius: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.direction = dir
	mat.spread = 12.0
	mat.initial_velocity_min = speed * 0.7
	mat.initial_velocity_max = speed
	mat.gravity = Vector3(0, -2.0, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(radius, 1.0, radius)
	mat.color = col
	p.process_material = mat
	p.amount = amount
	p.lifetime = 2.4
	p.visibility_aabb = AABB(Vector3(-radius, -10, -radius), Vector3(radius * 2, 50, radius * 2))
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, size.y, size.x)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = col
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = sm
	p.draw_pass_1 = mesh
	p.position = Vector3(0, 22, 0)
	add_child(p)
	return p


func set_biome_weather(kind: String) -> void:
	if mode == kind:
		return
	mode = kind
	_apply()


func summon(kind: String, duration: float = 18.0) -> void:
	local_override = kind
	local_t = duration
	_apply()


func _process(delta: float) -> void:
	var sd := GameState.sim_delta(delta)
	if local_t > 0.0:
		local_t -= sd
		if local_t <= 0.0:
			local_override = ""
			_apply()
	var active := local_override if local_override != "" else mode
	if active == "storm":
		_flash_t -= delta
		if _flash_t <= 0.0 and randf() < 0.015:
			storm_light.light_energy = 8.0
			_flash_t = 0.12
		else:
			storm_light.light_energy = lerp(storm_light.light_energy, 0.0, 0.2)
	else:
		storm_light.light_energy = 0.0


func _apply() -> void:
	var active := local_override if local_override != "" else mode
	rain.emitting = active in ["rain", "storm"]
	snow.emitting = active == "snow"
	# Intensity is visual only; particle amount stays fixed for renderer stability.
