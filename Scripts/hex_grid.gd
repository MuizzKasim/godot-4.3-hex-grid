extends Node

@export var height = 5
@export var width = 5
@export var raycast: RayCast3D
@export var hex_map_editor_ui: Control

var applied_color: Color = Color(0.5,0.5,0.5)
var applied_elevation: int = 0
var tiles: Array[Object] = []

const packed_hex: PackedScene = preload('res://Scenes/hex_tile.tscn')

func _init():
	var i = 0
	for y in range(height):
		for x in range(width):
			create_tile(x,y,i)
			i += 1
	

func _ready():
	#perturb_grid()
	raycast = $RayCast3D
	raycast.connect('hex_selected', _on_hex_selected)
	
	hex_map_editor_ui = $Control/HexMapEditorUI
	hex_map_editor_ui.connect('color_selected', _on_color_selected)
	hex_map_editor_ui.connect('elevation_set', _on_elevation_set)

func create_tile(x: int,z: int, index: int):
	## Create Grid
	var pos := Vector3()
	pos.x = (x + (z * 0.5 - z/2)) * (HexMetrics.INNER_RADIUS * 2)
	pos.y = 0
	pos.z = z * (HexMetrics.OUTER_RADIUS * 1.5)
	#pos.x /= 2
	#pos.z /= 2
	
	var hex_tile = packed_hex.instantiate()	
	#hex_tile.transform.origin = pos
	
	var hex_cell = hex_tile.hex_cell
	hex_cell.color = applied_color
	hex_cell.world_transform = pos
	hex_cell.coordinates = HexCoordinates.cartesian_oddr_to_axial(x, z)
	hex_cell.elevation = randi_range(0,3)
	#hex_cell.elevation = 0
	
	## Set Neighbors
	if x > 0:
		hex_cell.set_neighbor(HexDirections.direction.W, tiles[index - 1].hex_cell)		
	if z > 0:
		if (z&1) == 0:
			hex_cell.set_neighbor(HexDirections.direction.NE, tiles[index - width].hex_cell)
			if x > 0:
				hex_cell.set_neighbor(HexDirections.direction.NW, tiles[index - width - 1].hex_cell)
		else:
			hex_cell.set_neighbor(HexDirections.direction.NW, tiles[index - width].hex_cell)
			if x < width - 1:
				hex_cell.set_neighbor(HexDirections.direction.NE, tiles[index - width + 1].hex_cell)
	
	hex_tile.initialize(pos)
	hex_tile.set_label(hex_cell)
	hex_tile.set_meta('instance_id', index)
	hex_tile.set_meta('axial_coords', hex_cell.coordinates)
	
	tiles.append(hex_tile)
	add_child(hex_tile)
	
func edit_tile(hex_tile: Object) -> void:
	var hex_cell = hex_tile.hex_cell
	hex_cell.color = applied_color
	hex_cell.elevation = applied_elevation
	
	hex_tile.generate_geometry()
	hex_tile.update_neighbors(hex_tile)
	

func get_tile(index: int) -> Object:
	return tiles[index]
	
func _on_hex_selected(hex_coords: HexCoordinates, index: int) -> void:
	var hex_tile = get_tile(index)
	edit_tile(hex_tile)

func _on_color_selected(color: Color) -> void:
	applied_color = color
	
func _on_elevation_set(value: int) -> void:
	applied_elevation = value

func perturb_grid():
	for hex_instance in range(tiles.size()):
		var curr_mesh = tiles[hex_instance].mesh
		var mesh_tool = MeshDataTool.new()
		mesh_tool.create_from_surface(curr_mesh, 0)
		
		for dir in range(mesh_tool.get_vertex_count()):
			var local_pos = mesh_tool.get_vertex(dir)
			var world_pos = tiles[hex_instance].global_position + local_pos
			print(world_pos)
			
			var sample = HexMetrics.sample_noise(world_pos)
			local_pos += Vector3(sample.r* HexMetrics.CELL_PERTURB_STRENGTH, 0, sample.b * HexMetrics.CELL_PERTURB_STRENGTH)
			mesh_tool.set_vertex(dir, local_pos)
		
		curr_mesh.clear_surfaces()
		mesh_tool.commit_to_surface(curr_mesh)
