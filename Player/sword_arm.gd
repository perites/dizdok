extends Node2D
## Swings the sword arm around the shoulder and damages anything the blade touches.
## Anything with a take_damage(amount) method can be hit.

@export var damage: int = 25
## How far (in degrees) the sword rests to either side of the mouse direction.
## A slash sweeps from one side to the other, so the full arc is twice this.
@export var swing_angle: float = 60.0
## How long one slash takes, in seconds.
@export var swing_time: float = 0.18

@onready var hitbox: Area2D = $Hitbox

var _swinging := false
var _side := 1.0  # Which side the sword rests on: 1 or -1.
var _already_hit: Array[Node] = []


func _ready() -> void:
	rotation = deg_to_rad(swing_angle) * _side


func attack() -> void:
	if _swinging:
		return
	_swinging = true
	_already_hit.clear()
	_side = -_side  # Slash to the other side; the next slash comes back.

	var tween := create_tween()
	# Move in step with physics so the hitbox is checked at every position.
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", deg_to_rad(swing_angle) * _side, swing_time)
	tween.tween_callback(_end_swing)


func _end_swing() -> void:
	_swinging = false


func _physics_process(_delta: float) -> void:
	# The blade only deals damage while it is swinging.
	if not _swinging:
		return
	for body in hitbox.get_overlapping_bodies():
		_hit(body)
	for area in hitbox.get_overlapping_areas():
		_hit(area)


func _hit(target: Node) -> void:
	# Hit each target once per slash, and never hit whoever is holding the sword.
	if target in _already_hit or target.is_ancestor_of(self):
		return
	if target.has_method("take_damage"):
		_already_hit.append(target)
		target.take_damage(damage)
