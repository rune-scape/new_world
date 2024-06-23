extends RigidBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -400.0
var jump : bool = true

# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var gravity = 600


func _physics_process(delta):
	# Handle jump.
	if Input.is_action_just_pressed("ui_up"):
		linear_velocity.y = JUMP_VELOCITY
	
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	var accel = 3;
	var deccel = 4;
	linear_velocity.x = direction * SPEED
	#if direction:
	#	if abs(velocity.x) < SPEED:
	#		velocity.x += direction * (SPEED/accel)
	#else:
	#	if abs(velocity.x) > 0.05:
	#		velocity.x = move_toward(velocity.x,0,SPEED/deccel)
	
