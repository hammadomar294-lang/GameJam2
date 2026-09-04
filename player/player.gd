class_name Player
extends CharacterBody2D

@export var max_health: float = 3.0

var health: float = 0.0

@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var attack_component: Node = %AttackComponent
@onready var health_bar: HealthBar = $HealthBar


func _ready() -> void:
	add_to_group("player")
	health_bar.width = 44.0
	health_bar.height = 6.0
	health = max_health
	health_bar.set_ratio(1.0)


func take_damage(amount: float) -> void:
	health = maxf(health - amount, 0.0)
	health_bar.set_ratio(health / max_health)

	if health <= 0.0:
		get_tree().quit()  # player died -> close the game immediately


func _physics_process(delta: float) -> void:
	movement_component.move(input_component.direction, delta)

	if Input.is_action_just_pressed("shoot"):
		_on_player_attacked()


func _on_player_attacked() -> void:
	attack_component.shoot()
