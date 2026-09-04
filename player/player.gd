class_name Player
extends CharacterBody2D

@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var attack_component: Node = %AttackComponent


func _physics_process(delta: float) -> void:
	movement_component.move(input_component.direction, delta)

	if Input.is_action_just_pressed("shoot"):
		_on_player_attacked()


func _on_player_attacked() -> void:
	attack_component.shoot()
