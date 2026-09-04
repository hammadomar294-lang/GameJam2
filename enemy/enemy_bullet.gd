class_name EnemyBullet
extends Area2D

var stats: Resource
var direction: Vector2 = Vector2.RIGHT

var _lifetime_timer: float = 0.0


func setup(new_stats: Resource, new_direction: Vector2) -> void:
	stats = new_stats
	direction = new_direction.normalized()
	rotation = direction.angle()


func _ready() -> void:
	add_to_group("enemy_bullets")

	collision_layer = 0
	set_collision_layer_value(4, true)
	collision_mask = 0
	set_collision_mask_value(2, true)  # player


func _process(delta: float) -> void:
	if stats == null:
		return

	global_position += direction * stats.speed * delta

	_lifetime_timer += delta
	if _lifetime_timer >= stats.lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		var damage: float = float(stats.damage) if stats != null else 1.0
		body.take_damage(damage)
	queue_free()
