extends CharacterBody3D

const SPEED = 2.0
const GRAVITY = 25.0
const PATROL_RANGE = 3.0
const CONTACT_DAMAGE = 10

var patrol_origin: Vector3
var patrol_direction: float = 1.0
var health: int = 30

signal died()


func _ready() -> void:
	add_to_group("enemy")
	patrol_origin = global_position
	$HurtBox.body_entered.connect(_on_body_entered)


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		died.emit()
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.take_damage(CONTACT_DAMAGE)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	velocity.x = patrol_direction * SPEED
	velocity.z = 0.0

	# Reverse at patrol range edges
	if global_position.x <= patrol_origin.x - PATROL_RANGE:
		patrol_direction = 1.0
	elif global_position.x >= patrol_origin.x + PATROL_RANGE:
		patrol_direction = -1.0

	move_and_slide()
