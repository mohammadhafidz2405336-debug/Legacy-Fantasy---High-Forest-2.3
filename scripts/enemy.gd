extends CharacterBody2D
##
## Shared enemy behaviour for the snail, the bee and the boar.
## Patrols around its spawn point, shows a health bar, hurts the player on
## contact and reports its defeat to GameState (mission counter).
##

const GRAVITY := 1200.0
const CONTACT_RANGE := 26.0
const CONTACT_HEIGHT := 46.0

@export var max_health: int = 40
@export var speed: float = 26.0
@export var contact_damage: int = 12
@export var patrol_radius: float = 64.0
@export var flying: bool = false
@export var float_amplitude: float = 14.0
@export var float_speed: float = 2.0
@export var idle_animation: String = ""

var health: int = 0
var defeated := false

var _origin := Vector2.ZERO
var _dir := 1.0
var _time := 0.0
var _hit_flash := 0.0
var _sprite: AnimatedSprite2D
var _bar: ProgressBar
var _player: Node2D


func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	_origin = global_position
	_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_dir = -1.0 if (randi() % 2 == 0) else 1.0
	_time = randf() * TAU
	_build_health_bar()
	_play_idle()
	# Enemies use layer 4, world-only body collisions.
	collision_layer = 4
	collision_mask = 1


func _play_idle() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var candidates: Array[String] = []
	if not idle_animation.is_empty():
		candidates.append(idle_animation)
	candidates.append_array(["Walk", "Fly", "Run", "Idle", "Out", "default", "Walk"])
	for anim in candidates:
		if _sprite.sprite_frames.has_animation(anim):
			_sprite.play(anim)
			return


func _build_health_bar() -> void:
	_bar = get_node_or_null("HealthBar") as ProgressBar
	if _bar != null:
		_bar.max_value = max_health
		_bar.value = health


func _physics_process(delta: float) -> void:
	if defeated:
		return

	_time += delta
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	if not flying:
		velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)

	# patrol around the spawn point
	if global_position.x - _origin.x > patrol_radius:
		_dir = -1.0
	elif global_position.x - _origin.x < -patrol_radius:
		_dir = 1.0
	if is_on_wall():
		_dir = -_dir

	if not flying and is_on_floor():
		var foot := global_position + Vector2(_dir * 18.0, 12.0)
		var ground := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(foot, foot + Vector2(0, 32), 1))
		if ground.is_empty():
			_dir = -_dir
	velocity.x = _dir * minf(speed, absf(_origin.x + _dir * patrol_radius - global_position.x) / delta)
	if flying:
		var target_y := _origin.y + sin(_time * float_speed) * float_amplitude
		velocity.y = clampf((target_y - global_position.y) / delta, -90.0, 90.0)

	move_and_slide()

	if _sprite != null:
		_sprite.flip_h = _dir < 0.0
		if _hit_flash > 0.0:
			_hit_flash = maxf(0.0, _hit_flash - delta)
			_sprite.modulate = Color(1.6, 1.2, 1.2) if _hit_flash > 0.0 else Color.WHITE

	_check_contact()


func _check_contact() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _player.has_method("take_damage"):
		return
	var dx: float = absf(_player.global_position.x - global_position.x)
	var dy: float = absf(_player.global_position.y - global_position.y)
	if dx < CONTACT_RANGE and dy < CONTACT_HEIGHT:
		_player.take_damage(contact_damage, global_position.x)


# --------------------------------------------------------------------------
# Combat
# --------------------------------------------------------------------------
func take_damage(amount: int, from_direction: int = 1) -> void:
	if defeated:
		return
	health = maxi(0, health - amount)
	_hit_flash = 0.15
	velocity.x = from_direction * 40.0
	if _sprite != null:
		_sprite.modulate = Color(1.8, 1.0, 1.0)
	if _bar != null:
		_bar.value = health
	if health <= 0:
		_die()


func _die() -> void:
	if defeated:
		return
	defeated = true
	remove_from_group("enemy")
	if _bar != null:
		_bar.visible = false
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	GameState.register_enemy_defeated()
	if Hud: Hud.toast(Story.TOAST_ENEMY, 1.4)

	if _sprite != null:
		if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation("Dead"):
			_sprite.play("Dead")
		else:
			_sprite.modulate = Color(1.4, 1.4, 1.4)

	var tween := create_tween()
	tween.tween_interval(0.45)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)