class_name AttackComponent
extends Node

@export var bullet_stats: Resource
@export var entity: CharacterBody2D = null

var _can_shoot: bool = true

func _ready() -> void:
	if entity == null:
		entity = owner as CharacterBody2D

func shoot() -> void:
	if entity == null or bullet_stats == null or bullet_stats.bullet_scene == null or not _can_shoot:
		return
	_can_shoot = false
	var bullets_count: int = max(bullet_stats.instantiated_bullets_count, 1)
	var base_direction: Vector2 = -entity.global_position.normalized()
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.LEFT
	for index in range(bullets_count):
		var bullet = bullet_stats.bullet_scene.instantiate()
		var bullet_direction := _get_bullet_direction(base_direction, index, bullets_count)
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = entity.global_position + bullet_direction * bullet_stats.spawn_distance
		bullet.setup(bullet_stats, bullet_direction)
	await get_tree().create_timer(bullet_stats.shoot_cooldown).timeout
	_can_shoot = true

func _get_bullet_direction(base_direction: Vector2, index: int, bullets_count: int) -> Vector2:
	if bullets_count == 1:
		return base_direction
	var spread_angle := deg_to_rad(bullet_stats.spread_angle_degrees)
	var angle_step := spread_angle / float(bullets_count - 1)
	var angle_offset := -spread_angle * 0.5 + angle_step * index
	return base_direction.rotated(angle_offset)
