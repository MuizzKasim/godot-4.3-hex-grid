extends RayCast3D

@export var camera: Camera3D
const RAY_LENGTH: int = 1000
var width
signal hex_selected(static_body)

func _ready():
	width = self.get_parent().width
	if width == null:
		print('Error: Unable to find map width')
		return

func _input(event):
	if event is InputEventMouseButton and not is_ui_event(event) and event.button_index == MOUSE_BUTTON_LEFT:
		select_object(event.position)

func is_ui_event(event): 
	var mouse_pos = event.position 
	return true if get_viewport().get_window().gui_get_hovered_control() else false

func select_object(mouse_pos):
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * RAY_LENGTH
	var space_state = get_world_3d().get_direct_space_state()
	# use global coordinates, not local to node
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var cast_result = space_state.intersect_ray(query)
	if cast_result:
		#var coord_position = cast_result.position
		#var hex_coords =  HexCoordinates.world_to_hex_coords(coord_position)
		#var index = (hex_coords.x + hex_coords.z * width) + hex_coords.z / 2# For a square grid we would do x + z * width, but in hex coords, we need to add half z offset as well 
		#print(hex_coords.to_strings())
		
		var hex_tile = cast_result.collider.get_parent()
		var hex_coords  = hex_tile.get_meta('axial_coords')
		var index = hex_tile.get_meta('instance_id')
		
		hex_selected.emit(hex_coords, index)
	else:
		print('No object clicked')
