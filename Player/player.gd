extends CharacterBody2D

@export var speed: float = 300.0
## How fast the arms turn toward the mouse. Higher = snappier, 0 = instant.
@export var hand_turn_speed: float = 15.0

# Each arm hangs from its own shoulder pivot and rotates around it.
@onready var shoulders: Array[Node2D] = [$Hands/ShoulderLeft, $Hands/ShoulderRight]

@onready var hands: Node2D = $Hands
# The right arm holds the sword (see sword_arm.gd).
@onready var sword_arm: Node2D = $Hands/ShoulderRight/SwordArm
@onready var sprite: Sprite2D = $Sprite2D
# The gun hand turns around the shoulder (the GunHand node's position).
@onready var gun_hand: Node2D = $GunHand
@onready var gun_sprite: Sprite2D = $GunHand/Sprite2D
# The empty hand. Swaps picture with the facing but never turns.
@onready var idle_hand: Node2D = $IdleHand
@onready var idle_sprite: Sprite2D = $IdleHand/Sprite2D

# player_sheet.png is a 7x4 grid. Each row is one facing direction;
# column 0 is the standing pose, columns 1-6 are the walk cycle.
const ROW_RIGHT_BACK := 0
const ROW_LEFT_FACE := 1
const ROW_LEFT_BACK := 2
const ROW_RIGHT_FACE := 3
const WALK_FIRST_FRAME := 1
const WALK_FRAME_COUNT := 6

## Walk animation speed in frames per second.
@export var walk_fps: float = 10.0

var _walk_time := 0.0

# Hands_with_gun.png is 4 pictures stacked top to bottom:
# 0 = gun to the left, 1 = gun up-left (seen from behind),
# 2 = gun up-right (seen from behind), 3 = gun to the right.
const GUN_FRAME_LEFT_FACE := 0
const GUN_FRAME_LEFT_BACK := 1
const GUN_FRAME_RIGHT_BACK := 2
const GUN_FRAME_RIGHT_FACE := 3
# Shifts each picture so its shoulder (where the sleeve meets the body)
# sits on GunHand's origin. The hand turns around that point.
const GUN_SHOULDER_OFFSET: Array[Vector2] = [
	Vector2(-163, -17), Vector2(-103, -102), Vector2(103, -102), Vector2(163, -17)]
# Which way the gun already points in each picture, in degrees.
const GUN_DRAWN_ANGLE: Array[float] = [180.0, -139.0, -41.0, 0.0]

## Where the shoulder sits on the body for each gun picture
## (left-face, left-back, right-back, right-face). Tweak to line the arm up.
@export var gun_shoulder_positions: Array[Vector2] = [
	Vector2(-55, 15), Vector2(-55, -25), Vector2(45, -25), Vector2(45, 15)]
# Hands_without_gun.png uses the same 4-picture order as the gun hand.
# Shifts each picture so its shoulder sits on IdleHand's origin.
const IDLE_SHOULDER_OFFSET: Array[Vector2] = [
	Vector2(-216, -48), Vector2(-146, -133), Vector2(139, -129), Vector2(210, -32)]

## Where the empty hand's shoulder sits for each picture
## (left-face, left-back, right-back, right-face).
@export var idle_shoulder_positions: Array[Vector2] = [
	Vector2(40, 60), Vector2(40, 10), Vector2(-50, 10), Vector2(-50, 60)]
## Turn the gun to point exactly at the mouse. Off = only swap pictures.
@export var gun_follows_mouse: bool = true

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()

func _update_sprite(mouse: Vector2, delta: float) -> void:
	# Look toward the mouse: left/right by its x, back/face by its y.
	# Moving only decides whether the walk animation plays.
	var to_mouse := mouse - global_position
	var facing_right := to_mouse.x > 0.0
	var facing_back := to_mouse.y < 0.0

	var row: int
	var gun_frame: int
	if facing_back:
		row = ROW_RIGHT_BACK if facing_right else ROW_LEFT_BACK
		gun_frame = GUN_FRAME_RIGHT_BACK if facing_right else GUN_FRAME_LEFT_BACK
	else:
		row = ROW_RIGHT_FACE if facing_right else ROW_LEFT_FACE
		gun_frame = GUN_FRAME_RIGHT_FACE if facing_right else GUN_FRAME_LEFT_FACE
	_update_gun(gun_frame, mouse)
	_update_idle_hand(gun_frame)

	var column := 0  # Standing still.
	if velocity != Vector2.ZERO:
		_walk_time += delta
		column = WALK_FIRST_FRAME + int(_walk_time * walk_fps) % WALK_FRAME_COUNT
	else:
		_walk_time = 0.0  # Start the next walk from its first frame.

	sprite.frame = row * sprite.hframes + column

func _update_gun(gun_frame: int, mouse: Vector2) -> void:
	gun_sprite.frame = gun_frame
	gun_sprite.offset = GUN_SHOULDER_OFFSET[gun_frame]
	gun_hand.position = gun_shoulder_positions[gun_frame]

	if gun_follows_mouse:
		# Turn by the difference between where the gun is drawn pointing
		# and where the mouse is.
		var aim := (mouse - gun_hand.global_position).angle()
		gun_hand.rotation = wrapf(aim - deg_to_rad(GUN_DRAWN_ANGLE[gun_frame]), -PI, PI)
	else:
		gun_hand.rotation = 0.0

func _update_idle_hand(frame: int) -> void:
	idle_sprite.frame = frame
	idle_sprite.offset = IDLE_SHOULDER_OFFSET[frame]
	idle_hand.position = idle_shoulder_positions[frame]

func _unhandled_input(event: InputEvent) -> void:
	# "attack" is the left mouse button (Project Settings > Input Map).
	if event.is_action_pressed("attack"):
		sword_arm.attack()

func _process(delta: float) -> void:
	var mouse := get_global_mouse_position()
	_update_sprite(mouse, delta)
	
	for shoulder in shoulders:
		_aim_shoulder(shoulder, mouse, delta)
	
#
func _aim_shoulder(shoulder: Node2D, target: Vector2, delta: float) -> void:
	# Arms hang down (+Y) from the shoulder, but angle() measures from +X,
	# so subtract 90 degrees to make +Y face the mouse.
	var target_angle := (target - shoulder.global_position).angle() - PI / 2.0

	if hand_turn_speed <= 0.0:
		shoulder.rotation = target_angle
	else:
		shoulder.rotation = lerp_angle(shoulder.rotation, target_angle, hand_turn_speed * delta)
