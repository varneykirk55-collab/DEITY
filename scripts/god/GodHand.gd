class_name GodHand
extends Node3D
## Stylized divine hand: the player's physical presence in the miniature world.
## Built from smooth cylinders and spheres (no blocky fingers), it hovers just
## above the terrain under the mouse, follows raised mountains, and poses to
## match the selected divine tool. It hides whenever the UI/pause is active.

# Overall scale relative to the miniature world.
var hand_size: float = 1.0
# Height of the palm above the terrain surface (fingertips sit just above ground).
var hover_offset: float = 1.15
# Idle vertical float (bobbing) amplitude/speed.
var bob_amplitude: float = 0.12
var bob_speed: float = 2.6

# Maximum curl angle per finger joint (radians).
var curl_angle: float = 0.95

# Current interaction target, mirrored from ToolController / GameWorld.
var hover_pos: Vector3 = Vector3.ZERO
var hover_valid: bool = false
var tool: int = GameState.ToolId.INSPECT
var active: bool = true  # false while a menu/UI blocks the hand

var terrain: Node = null  # TerrainWorld, for surface-following height

# Animation state.
var anim_state: String = "idle"  # idle, pointing, grabbing, releasing, pressing, casting
var anim_t: float = 0.0

# Per-finger rig: {root, knuckle, dip_joint, sign, target_curl, curl}
var fingers: Array = []
var palm: MeshInstance3D = null
var wrist: MeshInstance3D = null
var _mat: StandardMaterial3D = null


func _ready() -> void:
	_mat = Gfx.mat(Color(0.96, 0.86, 0.72), 0.72, 0.0, Color(1.0, 0.92, 0.82), 0.14, false)
	_build_hand()
	_set_pose("idle")


func set_terrain(t: Node) -> void:
	terrain = t


## Called each frame by GameWorld with the current hover / tool / pause state.
func update(hover: Vector3, valid: bool, p_tool: int, p_active: bool, delta: float) -> void:
	hover_pos = hover
	hover_valid = valid
	tool = p_tool
	active = p_active

	# Pose driven by the selected divine tool.
	var pose := _pose_for_tool(tool)
	if pose != anim_state:
		_set_pose(pose)

	# Interpolate finger curls toward their targets.
	var changed := false
	for f in fingers:
		var target := float(f.get("target_curl", 0.3))
		var cur := float(f.get("curl", 0.3))
		if abs(target - cur) > 0.01:
			cur = lerpf(cur, target, clampf(delta * 5.0, 0.0, 1.0))
			f["curl"] = cur
			changed = true
	if changed:
		_apply_curls()

	# Position: follow the mouse over terrain, bobbing slightly when idle.
	if hover_valid and terrain != null and terrain.has_method("get_height"):
		var h := terrain.get_height(hover_pos.x, hover_pos.z)
		var base_y := h + hover_offset
		if anim_state == "idle":
			anim_t += delta * bob_speed
			base_y += sin(anim_t) * bob_amplitude
		elif anim_state == "pressing":
			base_y -= 0.18  # press down toward the surface
		global_position = Vector3(hover_pos.x, base_y, hover_pos.z)
	elif hover_valid:
		global_position = Vector3(hover_pos.x, hover_offset, hover_pos.z)

	# Visibility: never obstruct menus / UI.
	visible = active and hover_valid


func _pose_for_tool(t: int) -> String:
	match t:
		GameState.ToolId.LIGHTNING:
			return "pointing"
		GameState.ToolId.RAISE:
			return "pressing"
		GameState.ToolId.LOWER:
			return "pressing"
		GameState.ToolId.MOUNTAIN:
			return "casting"
		GameState.ToolId.FOREST:
			return "pointing"
		GameState.ToolId.SPAWN_HUMAN_1, GameState.ToolId.SPAWN_HUMAN_5, GameState.ToolId.SPAWN_HUMAN_20:
			return "releasing"
		GameState.ToolId.PLAGUE, GameState.ToolId.CURE, GameState.ToolId.MIRACLE:
			return "casting"
		GameState.ToolId.KILL, GameState.ToolId.KILL_GROUP:
			return "grabbing"
		_:
			return "idle"


func _set_pose(pose: String) -> void:
	anim_state = pose
	match pose:
		"idle":
			_set_targets(0.3, 0.3, 0.3, 0.3, 0.25)  # relaxed, slightly curled
		"pointing":
			_set_targets(0.0, 0.85, 0.85, 0.85, 0.85)  # index extended, rest curled
		"grabbing":
			_set_targets(0.95, 0.95, 0.95, 0.95, 0.95)  # fist
		"releasing":
			_set_targets(0.15, 0.15, 0.15, 0.15, 0.15)  # open, offering life
		"pressing":
			_set_targets(0.55, 0.55, 0.55, 0.55, 0.5)  # press into terrain
		"casting":
			_set_targets(0.1, 0.15, 0.15, 0.15, 0.2)  # open, divine gesture


func _set_targets(pinky: float, ring: float, middle: float, index: float, thumb: float) -> void:
	var vals := [pinky, ring, middle, index, thumb]
	for i in range(fingers.size()):
		fingers[i]["target_curl"] = vals[i]


func _apply_curls() -> void:
	for f in fingers:
		var sign := float(f.get("sign", 1.0))
		var curl := float(f.get("curl", 0.3))
		var angle := curl * curl_angle * sign
		var knuckle: Node3D = f.get("knuckle")
		var dip_joint: Node3D = f.get("dip_joint")
		if knuckle:
			knuckle.rotation = Vector3(0.0, 0.0, angle)
		if dip_joint:
			# Curl the distal segment a bit more for a natural bend.
			dip_joint.rotation = Vector3(0.0, 0.0, angle * 0.7)


func _build_hand() -> void:
	# Palm: flattened oval sphere.
	palm = Gfx.part(self, Gfx.sphere_hi, _mat, Vector3.ZERO, Vector3(0.52, 0.17, 0.42) * hand_size, "Palm")
	# Wrist below the palm.
	wrist = Gfx.part(self, Gfx.cylinder, _mat, Vector3(0.0, -0.42, 0.0), Vector3(0.30, 0.85, 0.30) * hand_size, "Wrist")

	# Five fingers radiating from the palm, pointing down and outward.
	# (name, spread_x, forward_z, reach, curl_sign)
	var specs := [
		["pinky",  -0.78, 0.22, 0.82,  1.0],
		["ring",   -0.42, 0.48, 0.92,  1.0],
		["middle",  0.00, 0.72, 1.02, -1.0],
		["index",    0.42, 0.48, 0.92, -1.0],
		["thumb",   0.85, 0.05, 0.62, -1.0],
	]
	for spec in specs:
		var name := String(spec[0])
		var sx := float(spec[1])
		var fz := float(spec[2])
		var reach := float(spec[3])
		var sign := float(spec[4])
		var dir := Vector3(sx, -1.0, fz).normalized()  # down and outward

		var root := Node3D.new()
		root.name = name
		root.position = Vector3.ZERO
		add_child(root)
		_orient_y(root, dir)  # local +Y points along the finger

		# Segments along local +Y (outward/down from palm).
		var mcp_len := reach * 0.32
		var pip_len := reach * 0.34
		var dip_len := reach * 0.34

		var mcp = Gfx.part(root, Gfx.cylinder, _mat, Vector3(0, mcp_len * 0.5, 0), Vector3(0.11, mcp_len, 0.11) * hand_size, "MCP")
		var knuckle := Node3D.new()
		knuckle.name = "Knuckle"
		knuckle.position = Vector3(0, mcp_len, 0)
		root.add_child(knuckle)

		var pip = Gfx.part(knuckle, Gfx.cylinder, _mat, Vector3(0, pip_len * 0.5, 0), Vector3(0.095, pip_len, 0.095) * hand_size, "PIP")
		var dip_joint := Node3D.new()
		dip_joint.name = "Dip"
		dip_joint.position = Vector3(0, pip_len, 0)
		knuckle.add_child(dip_joint)

		var dip = Gfx.part(dip_joint, Gfx.cylinder, _mat, Vector3(0, dip_len * 0.5, 0), Vector3(0.085, dip_len, 0.085) * hand_size, "DIP")
		var tip = Gfx.part(dip_joint, Gfx.sphere, _mat, Vector3(0, dip_len, 0), Vector3(0.10, 0.10, 0.10) * hand_size, "Tip")

		fingers.append({
			"root": root,
			"knuckle": knuckle,
			"dip_joint": dip_joint,
			"sign": sign,
			"target_curl": 0.3,
			"curl": 0.3
		})


## Orient `node` so its local +Y axis points along `dir` (used so finger
## segments extend naturally outward from the palm).
func _orient_y(node: Node3D, dir: Vector3) -> void:
	var d := dir.normalized()
	var ref := Vector3.UP
	if abs(d.dot(ref)) > 0.999:
		ref = Vector3.FORWARD
	var side := d.cross(ref).normalized()
	ref = side.cross(d).normalized()
	var b := Basis(side, d, ref)
	node.transform = b
	node.transform.origin = node.global_position
