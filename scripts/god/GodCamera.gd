class_name GodCamera
extends Node3D
## Overhead deity camera: WASD move, wheel zoom, RMB rotate, MMB pan.
## All movement is smoothly interpolated so navigation never jumps.

var yaw: float = 0.65
var pitch: float = -0.95
var distance: float = 62.0
var sensitivity: float = 0.005
var move_speed: float = 38.0
var min_dist: float = 8.0
var max_dist: float = 160.0
var bounds: float = 110.0
# Pitch limits: near top-down (-1.45 ~ -83deg) to slight upward tilt (-0.25 ~ -14deg).
var min_pitch: float = -1.45
var max_pitch: float = -0.25

# Smoothing rates (higher = snappier, lower = smoother/laggier).
var position_smooth: float = 10.0
var rotation_smooth: float = 6.0
var zoom_smooth: float = 12.0

# Camera stays this far above the surface when looking down.
var terrain_clearance: float = 4.0

# Target values smoothed toward each frame.
var _target_yaw: float = 0.65
var _target_pitch: float = -0.95
var _target_distance: float = 62.0
var _target_position: Vector3 = Vector3.ZERO

var _rotating := false
var _panning := false
var _cam: Camera3D
var terrain: Node = null  # TerrainWorld, optional for terrain-aware height.
var _shake: float = 0.0


func _ready() -> void:
	_cam = Camera3D.new()
	_cam.name = "Camera"
	_cam.fov = 50.0
	_cam.near = 0.15
	_cam.far = 600.0
	_cam.current = true
	add_child(_cam)
	_target_yaw = yaw
	_target_pitch = pitch
	_target_distance = distance
	_target_position = global_position
	_apply()


func configure(world_radius: float) -> void:
	bounds = world_radius * 0.92
	distance = world_radius * 0.55
	max_dist = world_radius * 1.35
	_target_distance = distance
	global_position = Vector3(0, 4, 0)
	_target_position = global_position
	_apply()


func camera() -> Camera3D:
	return _cam


func shake(amt: float) -> void:
	_shake = max(_shake, amt)


func set_terrain(t: Node) -> void:
	terrain = t


func _terrain_height_at(x: float, z: float) -> float:
	if terrain == null:
		return 0.0
	if terrain.has_method("get_height"):
		return terrain.get_height(x, z)
	return 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_rotating = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_target_distance = clampf(_target_distance * 0.82, min_dist, max_dist)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_target_distance = clampf(_target_distance * 1.18, min_dist, max_dist)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var sens := sensitivity * GameState.mouse_sensitivity
		if _rotating:
			_target_yaw -= mm.relative.x * sens
			_target_pitch = clampf(_target_pitch - mm.relative.y * sens, min_pitch, max_pitch)
		elif _panning:
			var right := Vector3(cos(yaw), 0, -sin(yaw))
			var fwd := Vector3(sin(yaw), 0, cos(yaw))
			global_position += (-right * mm.relative.x + fwd * mm.relative.y) * 0.04 * (distance / 50.0)
			_clamp_pos()
			_target_position = global_position


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
		var fwd := Vector3(sin(yaw), 0, cos(yaw))
		var right := Vector3(cos(yaw), 0, -sin(yaw))
		global_position += (right * wish.x + fwd * wish.z) * move_speed * (distance / 55.0) * delta
		_clamp_pos()
		_target_position = global_position

	if Input.is_key_pressed(KEY_Q):
		_target_yaw += 0.7 * delta
	if Input.is_key_pressed(KEY_E):
		_target_yaw -= 0.7 * delta
	if Input.is_key_pressed(KEY_R):
		_target_yaw = 0.65
		_target_pitch = -0.95
		_target_position = Vector3(0, 4, 0)
		_clamp_pos()

	# Smooth interpolation: no sudden jumps when input changes.
	yaw = lerpf(yaw, _target_yaw, rotation_smooth * delta)
	pitch = lerpf(pitch, _target_pitch, rotation_smooth * delta)
	distance = lerpf(distance, _target_distance, zoom_smooth * delta)
	global_position = global_position.lerp(_target_position, position_smooth * delta)

	# Keep the camera above raised terrain / mountains.
	if terrain != null:
		var h := _terrain_height_at(global_position.x, global_position.z)
		var min_y := h + terrain_clearance
		if global_position.y < min_y:
			global_position.y = min_y
			_target_position.y = global_position.y

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
