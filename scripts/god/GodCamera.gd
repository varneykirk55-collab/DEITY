class_name GodCamera
extends Node3D
## Overhead deity camera: WASD move, wheel zoom, RMB rotate, MMB pan.

var yaw: float = 0.65
var pitch: float = -0.95
var distance: float = 62.0
var sensitivity: float = 0.005
var move_speed: float = 38.0
var min_dist: float = 8.0
var max_dist: float = 160.0
var bounds: float = 110.0

var _rotating := false
var _panning := false
var _cam: Camera3D
var _shake: float = 0.0


func _ready() -> void:
	_cam = Camera3D.new()
	_cam.name = "Camera"
	_cam.fov = 50.0
	_cam.near = 0.15
	_cam.far = 600.0
	_cam.current = true
	add_child(_cam)
	_apply()


func configure(world_radius: float) -> void:
	bounds = world_radius * 0.92
	distance = world_radius * 0.55
	max_dist = world_radius * 1.35
	global_position = Vector3(0, 4, 0)
	_apply()


func camera() -> Camera3D:
	return _cam


func shake(amt: float) -> void:
	_shake = max(_shake, amt)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_rotating = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			distance = clampf(distance * 0.88, min_dist, max_dist)
			_apply()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			distance = clampf(distance * 1.12, min_dist, max_dist)
			_apply()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var sens := sensitivity * GameState.mouse_sensitivity
		if _rotating:
			yaw -= mm.relative.x * sens
			pitch = clampf(pitch - mm.relative.y * sens, -1.35, -0.28)
			_apply()
		elif _panning:
			var right := Vector3(cos(yaw), 0, -sin(yaw))
			var fwd := Vector3(sin(yaw), 0, cos(yaw))
			global_position += (-right * mm.relative.x + fwd * mm.relative.y) * 0.04 * (distance / 50.0)
			_clamp_pos()
			_apply()


func _process(delta: float) -> void:
	if is_instance_valid(GameState.world) and GameState.world.pause_open:
		_rotating = false
		_panning = false
		return
	var wish := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		wish.z -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		wish.z += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		wish.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		wish.x += 1
	if wish != Vector3.ZERO:
		wish = wish.normalized()
		var right := Vector3(cos(yaw), 0, -sin(yaw))
		var fwd := Vector3(sin(yaw), 0, cos(yaw))
		# Camera looks along -fwd-ish; WASD relative to view
		var look_fwd := Vector3(sin(yaw), 0, cos(yaw) * 0 + cos(yaw))
		look_fwd = Vector3(sin(yaw), 0, cos(yaw))
		right = Vector3(cos(yaw), 0, -sin(yaw))
		global_position += (right * wish.x + look_fwd * wish.z) * move_speed * (distance / 55.0) * delta
		_clamp_pos()
	if Input.is_key_pressed(KEY_Q):
		yaw += 0.7 * delta
	if Input.is_key_pressed(KEY_E):
		yaw -= 0.7 * delta
	if Input.is_key_pressed(KEY_R):
		yaw = 0.65
		pitch = -0.95
	if _shake > 0.0:
		_shake = max(0.0, _shake - delta * 4.0)
	_apply()


func _clamp_pos() -> void:
	var p := Vector2(global_position.x, global_position.z)
	if p.length() > bounds:
		p = p.normalized() * bounds
		global_position.x = p.x
		global_position.z = p.y


func _apply() -> void:
	var offset := Vector3(
		sin(yaw) * cos(pitch),
		-sin(pitch),
		cos(yaw) * cos(pitch)
	) * distance
	if _cam == null:
		return
	var jitter := Vector3.ZERO
	if _shake > 0.0:
		jitter = Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * _shake
	_cam.position = offset + jitter
	if _cam.is_inside_tree():
		var target := global_position + Vector3(0, 1.2, 0)
		if not target.is_equal_approx(_cam.global_position):
			_cam.look_at(target, Vector3.UP)
