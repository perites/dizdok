extends StaticBody2D
## A practice target. Flashes red when hit and disappears at 0 health.

@export var max_health: int = 100

var health: int

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_label: Label = $HealthLabel


func _ready() -> void:
	health = max_health
	health_label.text = str(health)


func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	health_label.text = str(health)

	# Flash red for a moment so the hit is easy to see.
	sprite.modulate = Color(1, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

	if health == 0:
		queue_free()
