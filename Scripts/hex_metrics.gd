extends Node
class_name HexMetrics

#Hexagon cell size constants
const SIZE: float = 10
const HEX_HEIGHT: float = 2.0
const OUTER_RADIUS: float = 1.0 * SIZE
const INNER_RADIUS: float = OUTER_RADIUS * 0.866025404

const SOLID_FACTOR: float = 0.8
const BLEND_FACTOR: float = 1 - SOLID_FACTOR

const ELEVATION_STEP: float = 3
const TERRACES_PER_SLOPE: int = 2
const TERRACE_STEPS: int = TERRACES_PER_SLOPE * 2 + 1
const HORIZONTAL_TERRACE_STEP_SIZE: float = 1/ float(TERRACE_STEPS)
const VERTICAL_TERRACE_STEP_SIZE: float = 1/ (float(TERRACES_PER_SLOPE) + 1)

const NOISE_SOURCE: Texture2D  = preload('res://Resources/noise.png')
const CELL_PERTURB_STRENGTH: float = 4
const ELEVATION_PERTURB_STRENGTH: float = 1.5
const NOISE_SCALE : float = 0.5  # 0.1 to 5 - high frequency to low frequency

const NOISE_PERLIN: NoiseTexture2D = preload('res://Resources/perlin.tres')

enum edge_type {Flat, Slope, Cliff}

const CORNERS: Array[Vector3] = [
		Vector3(0, 0, -OUTER_RADIUS),
		Vector3(INNER_RADIUS, 0, -0.5 * OUTER_RADIUS),
		Vector3(INNER_RADIUS, 0, 0.5 * OUTER_RADIUS),
		Vector3(0, 0, OUTER_RADIUS),
		Vector3(-INNER_RADIUS, 0, 0.5 * OUTER_RADIUS),
		Vector3(-INNER_RADIUS, 0, -0.5 * OUTER_RADIUS)
	]

const UV_CENTER: Vector2 = Vector2(0.5,0.5)
# Assumes hexagon face is looking up
const UV_CORNERS: Array[Vector2]= [
	Vector2(0.5, 0),
	Vector2(1, 0.25),
	Vector2(1, 0.75),
	Vector2(0.5, 1),
	Vector2(0, 0.75),
	Vector2(0, 0.25),
]

# Neighbors are ordered from top right then going clockwise
const CELL_NEIGHBORS: Array[Vector3] = [
	Vector3(1,0,-1),
	Vector3(1,-1,0),
	Vector3(0,-1,1),
	Vector3(-1,0,1),
	Vector3(-1,1,0),
	Vector3(0,1,-1)
]

static func get_first_corner(direction:int) -> Vector3:
	return CORNERS[direction]
	
static func get_second_corner(direction: int) -> Vector3:
	return CORNERS[(direction + 1) % 6]

static func get_first_uv_corner(direction:int) -> Vector2:
	return UV_CORNERS[direction]
	
static func get_second_uv_corner(direction: int) -> Vector2:
	return UV_CORNERS[(direction + 1) % 6]


static func get_first_solid_corner(direction: int) -> Vector3: 
	return CORNERS[direction] * SOLID_FACTOR 
	
static func get_second_solid_corner(direction: int) -> Vector3:
	return CORNERS[(direction + 1) % 6] * SOLID_FACTOR 
	
	
static func get_first_uv_solid_corner(direction:int) -> Vector2:
	return UV_CENTER + (UV_CORNERS[direction] - UV_CENTER) * SOLID_FACTOR
	
static func get_second_uv_solid_corner(direction: int) -> Vector2:
	return UV_CENTER + (UV_CORNERS[(direction + 1) % 6] - UV_CENTER) * SOLID_FACTOR

static func get_bridge(direction: int) -> Vector3:
	return (HexMetrics.get_first_corner(direction) + HexMetrics.get_second_corner(direction)) * BLEND_FACTOR

static func get_first_uv_bridge(direction: int) -> Vector2:
	var uv1: Vector2 = HexMetrics.get_first_uv_corner(direction)
	var uv2: Vector2 = HexMetrics.get_second_uv_corner(direction)
	var bridge_uv: Vector2 = uv1.lerp(uv2, BLEND_FACTOR)
	return bridge_uv
	
static func get_second_uv_bridge(direction: int) -> Vector2:
	var uv1: Vector2 = HexMetrics.get_first_uv_corner(direction)
	var uv2: Vector2 = HexMetrics.get_second_uv_corner(direction)
	var bridge_uv: Vector2 = uv1.lerp(uv2, SOLID_FACTOR)
	return bridge_uv

static func terrace_lerp(a: Vector3, b: Vector3, step: int) -> Vector3:
	## TERRACE HORIZONTAL (FLAT SIDE)
	# This is interpolation formula (1-t)a + tb
	# h is t, a is a, b is b
	var h: float = step * HexMetrics.HORIZONTAL_TERRACE_STEP_SIZE
	a.x += (b.x-a.x) * h
	a.z += (b.z-a.z) * h
	
	## TERRACE VERTICAL (SLOPED SIDE)
	var v: float = ((step+1)/2) * HexMetrics.VERTICAL_TERRACE_STEP_SIZE
	a.y += (b.y-a.y) * v
	
	return a
	
static func terrace_lerp_color(a: Color, b: Color, step: int) -> Color:
	var h = step * HexMetrics.HORIZONTAL_TERRACE_STEP_SIZE
	return a.lerp(b,h)
	
static func get_edge_type(elevation_1: int, elevation_2: int) -> int:
	if (elevation_1 == elevation_2):
		return edge_type.Flat
	var delta = elevation_2 - elevation_1
	if (delta == -HexMetrics.ELEVATION_STEP || delta == HexMetrics.ELEVATION_STEP):
		return edge_type.Slope
	return edge_type.Cliff

static func sample_noise(pos: Vector3) -> Color:
	return NOISE_SOURCE.get_image().get_pixelv(Vector2(
		pos.x , pos.z ))

static func perturb(pos: Vector3) -> Vector3:
	var pos1 = pos
	pos1.x += HexMetrics.OUTER_RADIUS
	pos1.y += HexMetrics.OUTER_RADIUS
	pos1.z += HexMetrics.OUTER_RADIUS
	#var sample = get_pixel_bilinear(pos1.x, pos1.z)
	var sample := sample_noise(pos1 * HexMetrics.NOISE_SCALE)
	var perturb := Vector3((sample.r*2-1) * HexMetrics.CELL_PERTURB_STRENGTH, 
						   (sample.g*2-1) * HexMetrics.ELEVATION_PERTURB_STRENGTH, 
						   (sample.b*2-1) * HexMetrics.CELL_PERTURB_STRENGTH)
	return perturb 
