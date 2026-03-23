extends CharacterBody3D

# Movement
const SPEED = 6.0
const JUMP_VELOCITY = 12.0
const GRAVITY = 25.0
const COYOTE_TIME = 0.12
const JUMP_BUFFER_TIME = 0.1
const AIR_JUMPS = 1

# Dash
const DASH_SPEED = 18.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 0.6

# Wall jump
const WALL_SLIDE_MAX_SPEED = 3.0
const WALL_JUMP_VELOCITY_X = 9.0
const WALL_JUMP_VELOCITY_Y = 14.0
const WALL_JUMP_LOCK_TIME = 0.2

# Health
const MAX_HEALTH = 100
const INVINCIBILITY_TIME = 0.5

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var air_jumps_remaining: int = AIR_JUMPS
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var is_dashing: bool = false
var wall_jump_timer: float = 0.0
var is_wall_sliding: bool = false
var facing_direction: float = 1.0
var health: int = MAX_HEALTH
var invincibility_timer: float = 0.0
var spawn_position: Vector3

signal health_changed(new_health: int)
signal died()


func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position


func take_damage(amount: int) -> void:
	if invincibility_timer > 0.0:
		return
	health = max(0, health - amount)
	invincibility_timer = INVINCIBILITY_TIME
	health_changed.emit(health)
	if health == 0:
		_die()


func _check_dash_hits() -> void:
	for i in get_slide_collision_count():
		var collider = get_slide_collision(i).get_collider()
		if collider and collider.is_in_group("enemy"):
			collider.take_damage(collider.health * 0.5)


func _die() -> void:
	died.emit()
	global_position = spawn_position
	velocity = Vector3.ZERO
	health = MAX_HEALTH
	health_changed.emit(health)


func _physics_process(delta: float) -> void:
	# Tick timers
	dash_cooldown_timer = max(0.0, dash_cooldown_timer - delta)
	jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	wall_jump_timer = max(0.0, wall_jump_timer - delta)
	invincibility_timer = max(0.0, invincibility_timer - delta)

	# Track facing direction for dash
	var move_input = Input.get_axis("move_left", "move_right")
	if move_input != 0.0:
		facing_direction = sign(move_input)

	# --- Dash ---
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		velocity.y = 0.0

	if is_dashing:
		dash_timer -= delta
		velocity.x = facing_direction * DASH_SPEED
		velocity.y = 0.0
		velocity.z = 0.0
		if dash_timer <= 0.0:
			is_dashing = false
		move_and_slide()
		_check_dash_hits()
		return

	# --- Floor state ---
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		air_jumps_remaining = AIR_JUMPS
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	# --- Wall slide ---
	is_wall_sliding = false
	if is_on_wall() and not is_on_floor() and velocity.y < 0.0:
		var wall_normal = get_wall_normal()
		var pressing_into_wall = (wall_normal.x > 0.0 and move_input < 0.0) or (wall_normal.x < 0.0 and move_input > 0.0)
		if pressing_into_wall:
			is_wall_sliding = true

	# --- Gravity ---
	if not is_on_floor():
		if is_wall_sliding:
			velocity.y = max(velocity.y - GRAVITY * delta, -WALL_SLIDE_MAX_SPEED)
		else:
			velocity.y -= GRAVITY * delta

	# --- Jump buffer ---
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME

	# --- Wall jump (takes priority) ---
	if Input.is_action_just_pressed("jump") and is_wall_sliding:
		var wall_normal = get_wall_normal()
		velocity.x = wall_normal.x * WALL_JUMP_VELOCITY_X
		velocity.y = WALL_JUMP_VELOCITY_Y
		wall_jump_timer = WALL_JUMP_LOCK_TIME
		air_jumps_remaining = AIR_JUMPS
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
	# --- Ground / coyote jump ---
	elif jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
	# --- Air jump ---
	elif Input.is_action_just_pressed("jump") and air_jumps_remaining > 0:
		velocity.y = JUMP_VELOCITY
		air_jumps_remaining -= 1

	# --- Horizontal movement ---
	# Locked briefly after wall jump to preserve launch momentum
	if wall_jump_timer <= 0.0:
		velocity.x = move_input * SPEED

	velocity.z = 0.0
	move_and_slide()
