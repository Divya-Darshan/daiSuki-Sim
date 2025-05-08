extends CharacterBody3D

@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_sprint : bool = false
@export var can_freefly : bool = false

@export_group("Speeds")
@export var look_speed : float = 0.002
@export var base_speed : float = 7.0
@export var jump_velocity : float = 4.5
@export var sprint_speed : float = 10.0
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
@export var input_left : String = "ui_left"
@export var input_right : String = "ui_right"
@export var input_forward : String = "ui_up"
@export var input_back : String = "ui_down"
@export var input_jump : String = "ui_accept"
@export var input_sprint : String = "sprint"
@export var input_freefly : String = "freefly"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var is_touch_device := false

@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider

func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	is_touch_device = DisplayServer.is_touchscreen_available()

func _unhandled_input(event: InputEvent) -> void:
	if is_touch_device:
		if event is InputEventScreenDrag and not is_joystick_area(event.position):
			rotate_look(event.relative)
	else:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			capture_mouse()
		if Input.is_key_pressed(KEY_ESCAPE):
			release_mouse()
		if mouse_captured and event is InputEventMouseMotion:
			rotate_look(event.relative)

	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return

	if can_jump and Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity

	move_speed = sprint_speed if can_sprint and Input.is_action_pressed(input_sprint) else base_speed

	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func rotate_look(rot_input: Vector2):
	var multiplier := 0.01 if is_touch_device else look_speed
	look_rotation.x -= rot_input.y * multiplier
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * multiplier

	var current_rotation_y = rotation.y
	var current_head_rotation_x = head.rotation.x

	# Smoothly interpolate to target rotations
	var new_rotation_y = lerp_angle(current_rotation_y, look_rotation.y, 0.15)
	var new_head_rotation_x = lerp_angle(current_head_rotation_x, look_rotation.x, 0.15)

	# Apply new rotations
	transform.basis = Basis()
	rotate_y(new_rotation_y)
	head.transform.basis = Basis()
	head.rotate_x(new_head_rotation_x)



func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func check_input_mappings():
	if can_move and not InputMap.has_action(input_left): can_move = false
	if can_move and not InputMap.has_action(input_right): can_move = false
	if can_move and not InputMap.has_action(input_forward): can_move = false
	if can_move and not InputMap.has_action(input_back): can_move = false
	if can_jump and not InputMap.has_action(input_jump): can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint): can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly): can_freefly = false

func is_joystick_area(pos: Vector2) -> bool:
	var joystick := get_node_or_null("/root/Main/CanvasLayer/VirtualJoystick") # Adjust to your scene path!
	if joystick:
		var scale: Vector2 = joystick.get_global_transform_with_canvas().get_scale()
		var rect := Rect2(joystick.global_position, joystick.size * scale)
		return rect.has_point(pos)
	return false
