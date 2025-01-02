extends Node
class_name HexCell

var instance_id: int
var elevation: int:
	get:
		return elevation * HexMetrics.ELEVATION_STEP
	set(value):
		elevation = value
		world_transform.y = value * HexMetrics.ELEVATION_STEP
var hex_tile: Object
var world_transform: Vector3:
	get: 
		return world_transform
var coordinates: HexCoordinates 
var label3d : Label3D
var color: Color
var neighbors: Array[HexCell] = [null, null, null, null, null, null]

func _init(hex_tile: Object):
	self.hex_tile = hex_tile
	
func get_neighbor(direction :int) -> HexCell:
	return neighbors[direction]

func set_neighbor(direction: int, cell :HexCell ) -> void:
	neighbors[direction] = cell
	cell.neighbors[HexDirections.opposite(direction)] = self

func get_edge_type(direction: int)-> int:
	return HexMetrics.get_edge_type(elevation, neighbors[direction].elevation)

func get_other_edge_type(other_cell: HexCell) -> int:
	return HexMetrics.get_edge_type(elevation, other_cell.elevation)

func generate_geometry():
	hex_tile.generate_geometry()
