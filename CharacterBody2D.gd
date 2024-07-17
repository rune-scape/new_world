extends CharacterBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -200.0
var jump : bool = true

# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var gravity = 600

var walkdelta:float = 0.0
var sitdelta:float = 0.0

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jump = false

	# Handle jump.
	if (Input.is_action_just_pressed("ui_up") and is_on_floor()) or (Input.is_action_pressed("ui_up") and is_on_floor_only()):
		if not jump:
			velocity.y = JUMP_VELOCITY
			jump = true
	
	#if Input.is_action_just_pressed("ui_down"):
	#	$CollisionShape2D.scale.y = 0.5
	#	$Sprite2D.scale.y = 0.135 * 0.5
	#	if is_on_floor():
	#		position.y += $CollisionShape2D.shape.size.y/2.0 * 0.5
	#if Input.is_action_just_released("ui_down"):
	#	$CollisionShape2D.scale.y = 1.0
	#	$Sprite2D.scale.y = 0.135 * 1.0
	#	if is_on_floor():
	#		position.y -= $CollisionShape2D.shape.size.y/2.0 * 0.5
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	var accel = 3
	var deccel = 4
	
	if is_on_floor():
		if direction != 0:
			walkdelta += delta
			$Sprite2D.frame = (int (walkdelta/0.05)%8)
		else:
			walkdelta = 0.0
			$Sprite2D.frame = 17
	else:
		$Sprite2D.frame = 18
	if direction != 0:
		$Sprite2D.flip_h = (direction == 1)
		sitdelta = 0
	else:
		sitdelta += delta
		if sitdelta > 1:
			$Sprite2D.frame = 16
	velocity.x = direction * SPEED
	#if direction:
	#	if abs(velocity.x) < SPEED:
	#		velocity.x += direction * (SPEED/accel)
	#else:
	#	if abs(velocity.x) > 0.05:
	#		velocity.x = move_toward(velocity.x,0,SPEED/deccel)
	
	move_and_slide()
