class_name Player
extends CharacterBody2D

@export var max_health: float = 3.0

var health: float = 0.0

@onready var attack_component: Node = %AttackComponent
@onready var health_bar: HealthBar = $HealthBar
@onready var hit_stop_manager: Node = get_node_or_null("/root/HitStopManager")
@onready var combat_input: PlayerCombatInputComponent = %PlayerCombatInputComponent


func _ready() -> void:
	add_to_group("player")
	health_bar.width = 44.0
	health_bar.height = 6.0
	health = max_health
	health_bar.set_ratio(1.0)

	# Orbit the enemy: resolve it from the "enemies" group and hand it to the
	# combat controller so the rings revolve around the correct center.
	combat_input.enemy = get_tree().get_first_node_in_group("enemies") as Node2D

	# Also allow firing with the Space key (in addition to the mouse click).
	_bind_space_to_shoot()


func take_damage(amount: float) -> void:
	if hit_stop_manager != null:
		hit_stop_manager.medium_hit_stop()

	health = maxf(health - amount, 0.0)
	health_bar.set_ratio(health / max_health)

	if health <= 0.0:
		get_tree().quit()  # player died -> close the game immediately


func _physics_process(delta: float) -> void:
	# Resolve the enemy lazily: it may not be in the "enemies" group yet when
	# _ready() ran, so re-check until we have a valid orbit center.
	if combat_input.enemy == null:
		combat_input.enemy = get_tree().get_first_node_in_group("enemies") as Node2D

	# Drive orbital combat movement: rotate on the ring and shift rings.
	combat_input.apply_to(self, delta)

	if Input.is_action_just_pressed("shoot"):
		_on_player_attacked()


func _on_player_attacked() -> void:
	attack_component.shoot()


## Registers the Space key on the "shoot" action if it is not already bound,
## so the player can fire with Space regardless of the cached Input Map.
func _bind_space_to_shoot() -> void:
	var space_event := InputEventKey.new()
	space_event.physical_keycode = KEY_SPACE
	if not InputMap.action_has_event("shoot", space_event):
		InputMap.action_add_event("shoot", space_event)
