extends RefCounted
class_name HexCoordinates

var x: int: 
	set(value): x = value
	get: return x

var z: int:
	set(value): z = value
	get: return z

var y: int: 
	get: return -x - z

# synonymous coords
var q: int:
	set(value): x = value  
	get: return x   

var r: int:
	set(value): z = value
	get: return z

var s: int:
	get: return y  

func _init(x: int = 0, z: int = 0):
	self.x = x
	self.z = z

static func cartesian_oddr_to_axial(x:int, z:int)->HexCoordinates: 	# x-col, z-row # oddr means odd row. This function is intended for conversion to axial coordinates for hex grid with offset in odd rows
	return HexCoordinates.new(int(x-(z-(z&1))/2),z)	

static func world_to_hex_coords(pos: Vector3) -> HexCoordinates:
	var x := pos.x / (HexMetrics.INNER_RADIUS * 2)
	var y := -x
	
	var offset = pos.z  / (HexMetrics.OUTER_RADIUS * 3)
	x -= offset
	y -= offset
	
	var x_i: int = x
	var y_i: int = y
	var z_i: int = -x-y
	return HexCoordinates.new(x_i, z_i)

func to_strings() -> String:
	return "HexCoords(x: {0}, z: {1})".format( {"0":str(x), "1": str(z)} )

func to_strings_on_separate_lines() -> String:
	return "x: {0}\nz: {1}".format( {"0": str(x), "1": str(z)} )

func axial_to_strings_on_separate_lines() -> String:
	return "q:{0}\ns:{2}\nr:{1}".format( {"0": str(q), "1": str(r), "2": str(s) } )

func get_direction(i : int) -> String:
	match(i):
		1: return "E"
		2: return "SE"
		3: return "SW"
		4: return "W"
		5: return "NW"
		_: return "NE"
