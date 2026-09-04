class_name Bullet
extends Area2D

var stats: Resource
var direction: Vector2 = Vector2.RIGHT

var _lifetime_timer: float = 0.0


func setup(new_stats: Resource, new_direction: Vector2) -> void:
	stats = new_stats
	direction = new_direction.normalized()
	rotation = direction.angle()


func _ready() -> void:
	add_to_group("bullets")

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(4, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(6, true)


func _process(delta: float) -> void:
	if stats == null:
		return

	global_position += direction * stats.speed * delta

	_lifetime_timer += delta
	if _lifetime_timer >= stats.lifetime:
		queue_free()


func _on_body_entered(_body: Node2D) -> void:
	queue_free()


func _on_area_entered(_area: Area2D) -> void:
	queue_free()
