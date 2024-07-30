class_name Player
extends CharacterBody2D

@export var speed: float = 6
@export var sword_damage: int = randi_range(1, 5)
@export var health: int = 100
@export var max_health: int = 100
@export var death_prefab: PackedScene
@export var special_damage: int = randi_range(5, 10)
@export var special_interval: float = 30
@export var special_scene: PackedScene


@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitboxArea
@onready var health_progress_bar: ProgressBar = $HealthProgressBar


var input_vector: Vector2 = Vector2(0, 0)
var is_running: bool = false
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var hitbox_cooldown: float = 0.0
var special_cooldown: float = 0.0


signal meat_collected(value: int)

func _ready():
	GameManager.player = self
	meat_collected.connect(func(value: int): GameManager.meat_counter += 1)

func _process(delta: float) -> void:
	GameManager.player_position = position
	
		# Obter o input vector
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Atualizar temporizador do ataque
	if is_attacking:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			is_attacking = false
			is_running = false
			animation_player.play("idle")
	
	#processar dano
	update_hitbox_detection(delta)
	
	# Ataque especial (Special)
	update_special(delta)
	
	# atualizar health bar
	health_progress_bar.max_value = max_health
	health_progress_bar.value = health
	
	
func _physics_process(delta: float) -> void:

	# Modificar a velocidade
	var target_velocity = input_vector * speed * 100.0
	if is_attacking:
		target_velocity *= 0.25
	velocity = lerp(velocity, target_velocity, 0.05)
	move_and_slide()
	
	# Atualizar o is_running
	var was_running = is_running
	is_running = not input_vector.is_zero_approx()
	
	# Tocar a animação
	if was_running != is_running:
		if is_running:
			animation_player.play("run")
		else:
			animation_player.play("idle")
	
	# Girar animação
	if input_vector.x > 0:
		sprite.flip_h = false
		pass
	elif input_vector.x < 0:
		sprite.flip_h = true
		pass

	# Ataque
	if Input.is_action_just_pressed("attack"):
		attack()

func attack() -> void:
	if is_attacking:
		return
	
	# attack_side_1
	# attack_side_2
	
	# Tocar animação
	animation_player.play("attack_side_1")
	
	# Configurar temporizador
	attack_cooldown = 0.56
	
	# Marcar ataque
	is_attacking = true
	
	# attack_down_1
	# attack_down_2

func deal_damage_to_enemies() -> void:
	var bodies = sword_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			enemy.damage(sword_damage)
			
			var direction_to_enemy = (enemy.position - position).normalized()
			var attack_direction: Vector2
			if sprite.flip_h:
				attack_direction = Vector2.LEFT
			else:
				attack_direction = Vector2.RIGHT
			var dot_product = direction_to_enemy.dot(attack_direction)

func update_special(delta: float) -> void:
	special_cooldown -= delta
	if special_cooldown > 0: return
	special_cooldown = special_interval
	
	var special = special_scene.instantiate()
	special.damage_amount = special_damage
	add_child(special)

func update_hitbox_detection(delta: float) -> void:
	# temporizador
	hitbox_cooldown -= delta
	if hitbox_cooldown > 0: return
	# frequencia 2x por segundo
	hitbox_cooldown = 0.5
	# detectar inimigos
	var bodies = hitbox_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			var damage_amount = 1
			damage(damage_amount)
	
	pass

func damage(amount: int) -> void:
	if health <= 0: return
	
	health -= amount
	
	#piscar inimigo quando levar dano
	modulate = Color.RED
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	#processar morte
	if health <= 0:
		die()

func die() -> void:
	GameManager.end_game()
	if death_prefab:
		var death_object = death_prefab.instantiate()
		death_object.position = position
		get_parent().add_child(death_object)
	
	queue_free()

func heal(amount: int) -> int:
	health += amount
	if health > max_health:
		health = max_health
	return health


