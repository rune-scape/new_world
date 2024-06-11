extends CharacterBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -200.0
var jump : bool = true

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jump = false;

	# Handle jump.
	if (Input.is_action_just_pressed("ui_up") and is_on_floor()) or (Input.is_action_pressed("ui_up") and is_on_floor_only()):
		if not jump:
			velocity.y = JUMP_VELOCITY
			jump = true
	
	if Input.is_action_just_pressed("ui_down"):
		scale.y = 0.5
		position.y += $CollisionShape2D.shape.size.y/4
	if Input.is_action_just_released("ui_down"):
		scale.y = 1.0
		position.y -= $CollisionShape2D.shape.size.y/4
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
