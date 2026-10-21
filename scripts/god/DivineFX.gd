class_name DivineFX
extends Node3D


func lightning(pos: Vector3) -> void:
	var bolt := MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := 28.0
	var x := pos.x
	var z := pos.z
	var pts: Array[Vector3] = []
	while y > pos.y:
		pts.append(Vector3(x, y, z))
		x += randf_range(-1.1, 1.1)
		z += randf_range(-1.1, 1.1)
		y -= randf_range(1.4, 2.6)
	pts.append(Vector3(pos.x, pos.y, pos.z))
	var col := Color(0.85, 0.95, 1.0)
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var w := 0.18
		st.set_color(col)
		st.add_vertex(a + Vector3(w, 0, 0))
		st.add_vertex(b + Vector3(w, 0, 0))
		st.add_vertex(b + Vector3(-w, 0, 0))
		st.add_vertex(a + Vector3(w, 0, 0))
		st.add_vertex(b + Vector3(-w, 0, 0))
		st.add_vertex(a + Vector3(-w, 0, 0))
	st.generate_normals()
	bolt.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = Color(0.7, 0.85, 1.0)
	m.emission_energy_multiplier = 4.0
	bolt.material_override = m
	add_child(bolt)
	var light := OmniLight3D.new()
	light.light_color = Color(0.8, 0.9, 1.0)
	light.light_energy = 12.0
	light.omni_range = 18.0
	light.position = pos + Vector3(0, 4, 0)
	add_child(light)
	_burst(pos, Color(0.8, 0.9, 1.0), 30)
	_timed_free(bolt, 0.35)
	_timed_free(light, 0.4)


func tornado(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	var p := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 2.4
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 80.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3(0, 3, 0)
	mat.color = Color(0.7, 0.75, 0.8, 0.7)
	p.process_material = mat
	p.amount = 220
	p.lifetime = 1.2
	p.position = Vector3(0, 1, 0)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.25, 0.25, 0.25)
	mesh.material = Gfx.unshaded(mat.color)
	p.draw_pass_1 = mesh
	n.add_child(p)
	var vis := Gfx.part(n, Gfx.cone, Gfx.mat(Color(0.65, 0.7, 0.75, 0.45), 0.8, 0.0, Color(0.6, 0.65, 0.7), 0.2, true), Vector3(0, 5, 0), Vector3(6, 10, 6), "Cone")
	vis.rotation.x = PI
	n.set_meta("life", 9.0)
	n.set_meta("kind", "tornado")
	return n


func meteor(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos + Vector3(8, 28, 8)
	n.set_meta("dest", pos)
	n.set_meta("kind", "meteor")
	n.set_meta("life", 2.2)
	add_child(n)
	Gfx.part(n, Gfx.sphere, Gfx.mat(Color(0.25, 0.2, 0.18), 0.6, 0.1, Color(1.0, 0.45, 0.1), 2.5), Vector3.ZERO, Vector3(1.6, 1.6, 1.6), "Rock")
	var trail := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.initial_velocity_min = 0.2
	mat.color = Color(1.0, 0.5, 0.1)
	trail.process_material = mat
	trail.amount = 40
	trail.lifetime = 0.4
	var spark := SphereMesh.new()
	spark.radius = 0.12
	spark.height = 0.24
	spark.material = Gfx.unshaded(Color(1.0, 0.5, 0.1))
	trail.draw_pass_1 = spark
	n.add_child(trail)
	return n


func plague_burst(pos: Vector3) -> void:
	_burst(pos, Color(0.35, 0.95, 0.2), 24)


func miracle_burst(pos: Vector3) -> void:
	_burst(pos, Color(1.0, 0.9, 0.35), 28)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.9, 0.5)
	light.light_energy = 6.0
	light.omni_range = 14.0
	light.position = pos + Vector3(0, 3, 0)
	add_child(light)
	_timed_free(light, 1.2)


func erupt(pos: Vector3) -> void:
	_burst(pos, Color(1.0, 0.35, 0.05), 50)
	var lava := Gfx.part(self, Gfx.sphere, Gfx.lava_material(), pos + Vector3(0, 1, 0), Vector3(3, 1.2, 3), "Lava")
	_timed_free(lava, 4.0)


func _burst(pos: Vector3, col: Color, n: int) -> void:
	var p := GPUParticles3D.new()
	p.position = pos + Vector3(0, 1, 0)
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 70.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 7.0
	mat.gravity = Vector3(0, -4, 0)
	mat.color = col
	p.process_material = mat
	p.amount = n
	p.lifetime = 0.7
	p.one_shot = true
	p.emitting = true
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	mesh.radial_segments = 6
	mesh.rings = 3
	mesh.material = Gfx.unshaded(mat.color)
	p.draw_pass_1 = mesh
	add_child(p)
	_timed_free(p, 1.2)


func _timed_free(n: Node, t: float) -> void:
	get_tree().create_timer(t).timeout.connect(n.queue_free)
