extends CharacterBody3D

const SPEED = 6.0
const JUMP_VELOCITY = 12.0
const GRAVITY = 25.0
const COYOTE_TIME = 0.12
const JUMP_BUFFER_TIME = 0.1

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0


func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Coyote time — allows jumping shortly after walking off a ledge
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	# Jump buffer — allows pressing jump slightly before landing
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	# Execute jump
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
		jump_buffer_timer = 0.0

	# Horizontal movement
	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED

	# Lock Z axis — keeps movement strictly 2D
	velocity.z = 0.0

	move_and_slide()
