class_name MovementComponent
extends Node

@export var angular_speed: float = 3.0
@export var radius: float = 160.0
@export var entity: CharacterBody2D = null

var angle: float = 0.0


func _ready() -> void:
	if entity == null:
		entity = owner as CharacterBody2D

	if entity == null:
		return

	angle = entity.global_position.angle()
	entity.global_position = Vector2.RIGHT.rotated(angle) * radius


func move(movement_direction: float, delta: float) -> void:
	if entity == null:
		return

	angle += movement_direction * angular_speed * delta
	entity.global_position = Vector2.RIGHT.rotated(angle) * radius
