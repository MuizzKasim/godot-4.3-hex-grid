extends MeshInstance3D

## nodes
@export var label3d: Label3D
var enable_label3d: bool = true

## collision
var collision_polygon: ConcavePolygonShape3D
var collision_shape: CollisionShape3D
var collision_body: StaticBody3D

## hex cell reference
var hex_cell: HexCell

## array mesh
var top_mesh_data := []
var top_verts := PackedVector3Array()
var top_uvs := PackedVector2Array()
var top_normals := PackedVector3Array()
var top_indices := PackedInt32Array()
var top_colors := PackedColorArray()

## utilities
const default_color = Color(0.5,0.5,0.5)
const shader_base: Shader = preload('res://Shaders/base_hex.gdshader')
const shader_wireframe: Shader = preload('res://Shaders/wireframe.gdshader')
var world_center: Vector3

func _init():
	hex_cell = HexCell.new(self)

func _ready():
	label3d.visible = enable_label3d
	generate_geometry()

func initialize(pos: Vector3):
	self.global_position = pos

func generate_geometry() -> void:
	top_verts = PackedVector3Array()
	top_uvs = PackedVector2Array()
	top_normals = PackedVector3Array()
	top_indices = PackedInt32Array()
	top_colors = PackedColorArray()
	
	for dir in range(HexDirections.direction.size()):
		triangulate(dir)
		
	position_label(Vector3(0, hex_cell.elevation + 0.5, 0) )
	top_mesh_data.resize(Mesh.ARRAY_MAX)
	top_mesh_data[Mesh.ARRAY_VERTEX] = top_verts
	top_mesh_data[Mesh.ARRAY_TEX_UV] = top_uvs
	top_mesh_data[Mesh.ARRAY_NORMAL] = top_normals
	top_mesh_data[Mesh.ARRAY_INDEX] = top_indices
	top_mesh_data[Mesh.ARRAY_COLOR] = top_colors
	
	var new_mesh = ArrayMesh.new()
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, top_mesh_data)
	mesh = new_mesh
	
	generate_collision_body()
	apply_shader_material()

func generate_collision_body() -> void:
	if collision_polygon != null:
		collision_polygon = null
	collision_polygon = ConcavePolygonShape3D.new()
	collision_polygon.set_faces(mesh.get_faces())
	
	if collision_shape != null:
		collision_shape.free()
	collision_shape = CollisionShape3D.new()
	collision_shape.set_shape(collision_polygon)
	
	collision_body = StaticBody3D.new()
	collision_body.add_child(collision_shape)
	collision_body.collision_layer = 1
	collision_body.collision_mask = 1
	
	add_child(collision_body)

func apply_shader_material() -> void:
	var shader_material_1 = ShaderMaterial.new()
	shader_material_1.shader = shader_base
	#shader_material_1.set_shader_parameter('noise_texture', HexMetrics.NOISE_SOURCE)
	#shader_material_1.set_shader_parameter('noise_scale', HexMetrics.NOISE_SCALE)
	#shader_material_1.set_shader_parameter('displacement_strength', HexMetrics.CELL_PERTURB_STRENGTH)
	
	var shader_material_2 = ShaderMaterial.new()
	shader_material_2.shader = shader_wireframe
	#shader_material_2.set_shader_parameter('noise_texture', HexMetrics.NOISE_SOURCE)
	#shader_material_2.set_shader_parameter('noise_scale', HexMetrics.NOISE_SCALE)
	#shader_material_2.set_shader_parameter('displacement_strength', HexMetrics.CELL_PERTURB_STRENGTH)
	shader_material_1.next_pass = shader_material_2
	
	mesh.surface_set_material(0, shader_material_1)
	
func update_neighbors(hex_tile: Object):
	for neighbor_cell in hex_tile.hex_cell.neighbors:
		if neighbor_cell != null:
			neighbor_cell.generate_geometry()

func triangulate(direction: int) -> void:
	# Make Hex
	var center := Vector3.ZERO
	var e1: EdgeVertices = EdgeVertices.new(
		center + HexMetrics.get_first_solid_corner(direction),
		center + HexMetrics.get_second_solid_corner(direction)
	)
	var c = hex_cell.color if hex_cell else default_color
	center.y = hex_cell.elevation
	e1.v1.y = hex_cell.elevation
	e1.v2.y = hex_cell.elevation
	e1.v3.y = hex_cell.elevation
	e1.v4.y = hex_cell.elevation
	
	triangulate_edge_fan(center, e1, c)
	
	if (direction >= HexDirections.direction.SW):
		triangulate_connection(direction, e1)
	
func triangulate_connection(direction: int, e1: EdgeVertices) -> void:
	# Make Bridge
	var neighbor_cell = hex_cell.get_neighbor(direction)
	if neighbor_cell == null:
		return
	
	var bridge = HexMetrics.get_bridge(direction)
	bridge.y = neighbor_cell.world_transform.y - hex_cell.world_transform.y
	var e2 = EdgeVertices.new(
		e1.v1 + bridge,
		e1.v4 + bridge)
	e2.v1.y = neighbor_cell.elevation
	e2.v4.y = neighbor_cell.elevation
	var c1 :Color = hex_cell.color if hex_cell else default_color
	var c2 :Color = neighbor_cell.color if neighbor_cell else default_color
	
	if hex_cell.get_edge_type(direction) == HexMetrics.edge_type.Slope:
		triangulate_terrace(e1, hex_cell, e2, neighbor_cell)
	else:
		triangulate_edge_strip(e1, c1, e2, c2)
	
	# Make Triangle Gaps
	var next_neighbor_cell = hex_cell.get_neighbor(HexDirections.next(direction))
	if next_neighbor_cell and direction >= HexDirections.direction.W:
		var v5 = e1.v4 + HexMetrics.get_bridge(HexDirections.next(direction))
		v5.y = next_neighbor_cell.elevation
		var c3 = next_neighbor_cell.color
		
		## Check BLR configuration
		if hex_cell.elevation <= neighbor_cell.elevation:
			if hex_cell.elevation <= next_neighbor_cell.elevation:
				triangulate_corner(e1.v4, hex_cell, e2.v4, neighbor_cell, v5, next_neighbor_cell)
			else:
				triangulate_corner(v5, next_neighbor_cell, e1.v4, hex_cell, e2.v4, neighbor_cell)
		elif neighbor_cell.elevation <= next_neighbor_cell.elevation:
			triangulate_corner(e2.v4, neighbor_cell, v5, next_neighbor_cell, e1.v4, hex_cell)
		else:
			triangulate_corner(v5, next_neighbor_cell, e1.v4, hex_cell, e2.v4, neighbor_cell)
			
func triangulate_terrace(begin: EdgeVertices, begin_cell: HexCell, 
						end: EdgeVertices, end_cell: HexCell) -> void:
	var e2: EdgeVertices = EdgeVertices.terrace_lerp(begin, end, 1)
	var c2: Color = HexMetrics.terrace_lerp_color(begin_cell.color, end_cell.color, 1)
	
	triangulate_edge_strip(begin, begin_cell.color, e2, c2)
	
	for i in range(2, HexMetrics.TERRACE_STEPS+1, 1):
		var e1 = e2
		var c1 = c2
		e2 = EdgeVertices.terrace_lerp(begin, end, i)
		c2 = HexMetrics.terrace_lerp_color(begin_cell.color, end_cell.color, i)
		
		triangulate_edge_strip(e1,c1,e2,c2)
		
	triangulate_edge_strip(e2,c2, end, end_cell.color)
	
func triangulate_corner(bottom: Vector3, bottom_cell: HexCell, 
						left: Vector3, left_cell: HexCell,
						right: Vector3, right_cell: HexCell):
	var left_edge_type := bottom_cell.get_other_edge_type(left_cell)
	var right_edge_type := bottom_cell.get_other_edge_type(right_cell)
	
	## Check Cliff & Slopes Edge Variants
	if left_edge_type == HexMetrics.edge_type.Slope:
		
		if right_edge_type == HexMetrics.edge_type.Slope:
			## SSF - Slope, Slope Flat pattern
			triangulate_corner_terrace(bottom, bottom_cell, left, left_cell, right, right_cell)
		elif right_edge_type == HexMetrics.edge_type.Flat:
			## SFS - Slope, Flat, Slope pattern
			triangulate_corner_terrace(left, left_cell, right,right_cell, bottom, bottom_cell)
		else:
			# SCC - Slope, Cliff, Cliff
			# SSC - Slope, Slope, Cliff
			triangulate_corner_terrace_and_cliff(bottom, bottom_cell, left, left_cell, right, right_cell)

	elif right_edge_type == HexMetrics.edge_type.Slope:
		## FSS - Flat, Slope, Slope pattern
		if left_edge_type == HexMetrics.edge_type.Flat:
			triangulate_corner_terrace(right, right_cell, bottom, bottom_cell, left, left_cell)
		else:
			## CCS - Cliff, Cliff, Slope
			## CSS - Cliff, Slope, Slope
			triangulate_corner_cliff_and_terrace(bottom, bottom_cell, left, left_cell, right, right_cell)
		
	## Check for Double Cliff Variants
	elif (left_cell.get_other_edge_type(right_cell) == HexMetrics.edge_type.Slope):
		if left_cell.elevation < right_cell.elevation:
			triangulate_corner_cliff_and_terrace(right, right_cell, bottom, bottom_cell, left, left_cell)
		else:
			triangulate_corner_terrace_and_cliff(left, left_cell, right, right_cell, bottom, bottom_cell)
	else:
		## FFF - Flat, Flat, Flat
		## CCC - Cliff, Cliff, Cliff
		## CCF - Cliff, Cliff, Flat
		add_triangle(bottom, left, right)
		add_triangle_color(bottom_cell.color, left_cell.color, right_cell.color);
	
func triangulate_corner_terrace(begin: Vector3, begin_cell: HexCell, 
								left: Vector3, left_cell: HexCell,
								right: Vector3, right_cell: HexCell):
	var v3 := HexMetrics.terrace_lerp(begin, left, 1)
	var v4 := HexMetrics.terrace_lerp(begin, right, 1)
	var c3: Color = HexMetrics.terrace_lerp_color(begin_cell.color, left_cell.color, 1)
	var c4: Color = HexMetrics.terrace_lerp_color(begin_cell.color, right_cell.color, 1)

	add_triangle(begin, v3, v4);
	add_triangle_color(begin_cell.color, c3, c4);
	
	for i in range(2, HexMetrics.TERRACE_STEPS, 1):
		var v1 = v3
		var v2 = v4
		var c1 = c3
		var c2 = c4
		v3 = HexMetrics.terrace_lerp(begin, left, i)
		v4 = HexMetrics.terrace_lerp(begin, right, i)
		c3 = HexMetrics.terrace_lerp_color(begin_cell.color, left_cell.color, i)
		c4 = HexMetrics.terrace_lerp_color(begin_cell.color, right_cell.color, i)
		
		add_quad(v1, v2, v3, v4);
		add_quad_color(c1, c2, c3, c4);
	
	add_quad(v3, v4, left, right);
	add_quad_color(c3, c4, left_cell.color, right_cell.color);

func triangulate_corner_terrace_and_cliff(begin: Vector3, begin_cell: HexCell, 
										left: Vector3, left_cell: HexCell,
										right: Vector3, right_cell: HexCell):
	var b: float = HexMetrics.ELEVATION_STEP / float(right_cell.elevation - begin_cell.elevation);
	b = -b if b<0 else b
	var perturb_begin = perturb_vector(begin)
	var perturb_right = perturb_vector(right)
	var perturb_left = perturb_vector(left)
	var boundary := perturb_begin.lerp(perturb_right, b);
	var boundary_color: Color = begin_cell.color.lerp( right_cell.color, b);
	
	## Triangulate Bottom Part
	triangulate_boundary_triangle(begin, begin_cell, left, left_cell, boundary, boundary_color)
	
	## Triangulate Top Part
	if left_cell.get_other_edge_type(right_cell) == HexMetrics.edge_type.Slope:
		triangulate_boundary_triangle(left, left_cell, right, right_cell, boundary, boundary_color)
	else:
		add_triangle_unperturbed(perturb_left, perturb_right, boundary)
		add_triangle_color(left_cell.color, right_cell.color, boundary_color);
		
func triangulate_corner_cliff_and_terrace(begin: Vector3, begin_cell: HexCell, 
										left: Vector3, left_cell: HexCell,
										right: Vector3, right_cell: HexCell):
	var b: float = HexMetrics.ELEVATION_STEP / float(left_cell.elevation - begin_cell.elevation);
	b = -b if b<0 else b
	var perturb_begin = perturb_vector(begin)
	var perturb_left = perturb_vector(left)
	var perturb_right = perturb_vector(right)
	var boundary := perturb_begin.lerp(perturb_left, b);
	var boundary_color: Color = begin_cell.color.lerp(left_cell.color, b);
	
	## Triangulate Bottom Part
	triangulate_boundary_triangle(right, right_cell, begin, begin_cell, boundary, boundary_color)
	
	## Triangulate Top Part
	if left_cell.get_other_edge_type(right_cell) == HexMetrics.edge_type.Slope:
		triangulate_boundary_triangle(left, left_cell, right, right_cell, boundary, boundary_color)
	else:
		add_triangle_unperturbed(perturb_left, perturb_right, boundary)
		add_triangle_color(left_cell.color, right_cell.color, boundary_color);
		
func triangulate_boundary_triangle(begin: Vector3, begin_cell: HexCell, 
								left: Vector3, left_cell: HexCell,
								boundary: Vector3, boundary_color: Color):
	var v2 = HexMetrics.terrace_lerp(begin, left, 1)
	var c2 = HexMetrics.terrace_lerp_color(begin_cell.color, left_cell.color, 1)
	
	var perturb_begin = perturb_vector(begin)
	var perturb_v2 = perturb_vector(v2)
	
	add_triangle_unperturbed(perturb_begin, perturb_v2, boundary);
	add_triangle_color(begin_cell.color, c2, boundary_color);
	
	for i in range(0, HexMetrics.TERRACE_STEPS, 1):
		var v1 = v2
		var c1 = c2
		v2 = HexMetrics.terrace_lerp(begin, left, i)
		c2 = HexMetrics.terrace_lerp_color(begin_cell.color, left_cell.color, i)
		var perturbed_v1 = perturb_vector(v1)
		perturb_v2 = perturb_vector(v2)
		
		add_triangle_unperturbed(perturbed_v1,perturb_v2,boundary)
		add_triangle_color(c1,c2,boundary_color)
		
	var perturb_left = perturb_vector(left)
	
	add_triangle_unperturbed(perturb_v2, perturb_left, boundary);
	add_triangle_color(c2, left_cell.color, boundary_color);
	
func triangulate_edge_fan(center: Vector3, edge: EdgeVertices, color: Color):
	add_triangle(center, edge.v1, edge.v2)
	add_triangle_color(color, color, color)
	add_triangle(center, edge.v2, edge.v3)
	add_triangle_color(color, color, color)
	add_triangle(center, edge.v3, edge.v4)
	add_triangle_color(color, color, color)

func triangulate_edge_strip (e1: EdgeVertices, c1: Color, e2: EdgeVertices, c2: Color):
	add_quad(e1.v1, e1.v2, e2.v1, e2.v2);
	add_quad_color(c1, c1, c2, c2);
	add_quad(e1.v2, e1.v3, e2.v2, e2.v3);
	add_quad_color(c1, c1, c2, c2);
	add_quad(e1.v3, e1.v4, e2.v3, e2.v4);
	add_quad_color(c1, c1, c2, c2);

func add_triangle(v1: Vector3,v2: Vector3,v3: Vector3) -> void:
	var w1 = perturb_vector(v1)
	var w2 = perturb_vector(v2)
	var w3 = perturb_vector(v3)
	
	var index = top_verts.size()
	var x = v1 - v2
	var y = v1 - v3
	var c = -x.cross(y).normalized()

	top_verts.append( w1 )
	top_verts.append( w2 )
	top_verts.append( w3 )
	
	top_uvs.append(Vector2(0,0))
	top_uvs.append(Vector2(0,0))
	top_uvs.append(Vector2(1,1))
	
	top_indices.append(index)
	top_indices.append(index + 1)
	top_indices.append(index + 2)

	for i in range(3):
		top_normals.append(c)

func add_triangle_unperturbed(v1, v2, v3:):
	var index = top_verts.size()
	var x = v1 - v2
	var y = v1 - v3
	var c = -x.cross(y).normalized()

	top_verts.append( v1 )
	top_verts.append( v2 )
	top_verts.append( v3 )
	
	top_uvs.append(Vector2(0,0))
	top_uvs.append(Vector2(0,0))
	top_uvs.append(Vector2(1,1))
	
	top_indices.append(index)
	top_indices.append(index + 1)
	top_indices.append(index + 2)

	for i in range(3):
		top_normals.append(c)

	
func add_triangle_color(c1: Color, c2: Color, c3:Color) -> void:
	top_colors.append(c1)
	top_colors.append(c2)
	top_colors.append(c3)

func add_quad(v1: Vector3,v2: Vector3,v3: Vector3,v4: Vector3) -> void:	
	var w1 = perturb_vector(v1)
	var w2 = perturb_vector(v2)
	var w3 = perturb_vector(v3)
	var w4 = perturb_vector(v4)

	var index = top_verts.size()
	var x = v1 - v2
	var y = v1 - v3
	var c = x.cross(y).normalized()
	
	top_verts.append( w1 )
	top_verts.append( w2 )
	top_verts.append( w3 )
	top_verts.append( w4 )
	
	top_uvs.append(Vector2(0,0))
	top_uvs.append(Vector2(0,0))
	top_uvs.append(Vector2(1,1))
	top_uvs.append(Vector2(0,1))

	top_indices.append(index)
	top_indices.append(index + 2)
	top_indices.append(index + 1)
	
	top_indices.append(index + 1)
	top_indices.append(index + 2)
	top_indices.append(index + 3)
	
	for i in range(4):
		top_normals.append(c)
	
func add_quad_color(c1: Color,c2: Color,c3: Color,c4: Color):
	top_colors.append(c1)
	top_colors.append(c2)
	top_colors.append(c3)
	top_colors.append(c4)

func position_label(pos: Vector3) -> void:
	if label3d.transform.origin.x == 0 and label3d.transform.origin.z == 0 :
		label3d.transform.origin = pos
		label3d.transform.origin.y += 0.1
	return

func set_label(hex_cell: HexCell) -> void:
	label3d.text = hex_cell.coordinates.axial_to_strings_on_separate_lines()

func toggle_label() -> void:
	label3d.visible = !label3d.visible

func perturb_vector(local_position: Vector3) -> Vector3:
	var perturbed_position: Vector3 = local_position + HexMetrics.perturb(self.global_position + local_position)
	return perturbed_position
