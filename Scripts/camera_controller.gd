extends Camera3D

# Input Action
var rotate_right_action:=""
var rotate_left_action:=""
var rotate_up_action:=""
var rotate_down_action:=""

# Movement and zoom speeds
var move_speed: float = 30.0
var rotation_speed: float = 0.1
var zoom_speed: float = 2.0

@export var sensitivity = 0.2
@export var smoothness = 0.5
@export var yaw_limit = 360
@export var pitch_limit = 360

var mouse_offset := Vector2()
var yaw = 0.0
var pitch = 0.0
var total_yaw = 0.0
var total_pitch = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if event is InputEventMouseMotion:
		mouse_offset = event.relative

func _process(delta):
	handle_movement(delta)
	handle_rotation(delta)
	
func handle_movement(delta: float):
	var direction: Vector3 = Vector3.ZERO
	var speed_multiplier: float = 4 if Input.is_key_pressed(KEY_SHIFT) else 1
		
	if Input.is_action_pressed("camera_up"):
		direction.z -= 1
	if Input.is_action_pressed("camera_down"):
		direction.z += 1
	if Input.is_action_pressed("camera_left"):
		direction.x -= 1
	if Input.is_action_pressed("camera_right"):
		direction.x += 1
	
	direction = direction.normalized()
	translate(direction * move_speed * delta * speed_multiplier)

func handle_rotation(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		var offset = mouse_offset * sensitivity
		mouse_offset = Vector2()
		
		yaw = yaw * smoothness + offset.x * (1.0 - smoothness)
		pitch = pitch * smoothness + offset.y * (1.0 - smoothness)
		
		if yaw_limit < 360:
			yaw = clamp(yaw, -yaw_limit - total_yaw, yaw_limit - total_yaw)
		if pitch_limit < 360:
			pitch = clamp(pitch, -pitch_limit - total_pitch, pitch_limit - total_pitch)
		
		total_yaw += yaw
		total_pitch += pitch
		
		rotate_y(deg_to_rad(-yaw))
		rotate_object_local(Vector3(1, 0, 0), deg_to_rad(-pitch))
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
