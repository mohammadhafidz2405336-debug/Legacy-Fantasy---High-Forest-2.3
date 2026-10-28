extends CharacterBody2D
##
## Zhafran - player character.
## Movement, jump, melee attack, health/damage, interaction scanning.
## Attached to res://Scene/char_zhafran.tscn
##

signal health_depleted

const SPEED := 155.0
const JUMP_VELOCITY := -540.0
const GRAVITY := 1500.0
const MAX_FALL_SPEED := 780.0
const COYOTE_TIME := 0.10

const ATTACK_COOLDOWN := 0.36
const ATTACK_DAMAGE := 25
const INVULN_TIME := 0.9
const KNOCKBACK := 230.0

const SFX_JUMP := preload("res://brackeys_platformer_assets/sounds/jump.wav")
const SFX_HURT := preload("res://brackeys_platformer_assets/sounds/hurt.wav")
const SFX_ATTACK := preload("res://brackeys_platformer_assets/sounds/tap.wav")

# Node dicari lewat tipe, jadi tetap jalan walau namanya "AnimatedSprite2D2" / "AttackHitbox2".
# Node kembar (AnimatedSprite2D2, AttackHitbox2) otomatis dibuang supaya karakter tidak dobel.
@onready var sprite: AnimatedSprite2D = _pick_child("AnimatedSprite2D", "AnimatedSprite2D") as AnimatedSprite2D
@onready var attack_hitbox: Area2D = _pick_child("Area2D", "AttackHitbox") as Area2D
var _swing_hits: Array[int] = []
var _feet_offsets: Dictionary = {}

var facing := 1                    ## 1 = kanan, -1 = kiri
var is_dead := false
var controls_enabled := true

var _attack_cooldown := 0.0
var _attack_left := 0.0
var _invuln_left := 0.0
var _coyote_left := 0.0
var _spawn_point := Vector2.ZERO
var _interactables: Array = []
var _active_interactable: Node = null
var _interact_held := false
var _interact_area: Area2D
var _slash: Sprite2D
var _slash_tween: Tween

var _sfx: AudioStreamPlayer


func _pick_child(type_name: String, base_name: String) -> Node:
	var found: Array[Node] = []
	for c in get_children():
		if c.is_class(type_name):
			found.append(c)
	if found.is_empty():
		return null
	# utamakan node bernama persis base_name, kalau tidak ada pakai yang pertama
	var best: Node = found[0]
	for c in found:
		if str(c.name) == base_name:
			best = c
			break
	# kalau sprite terpilih kosong, pakai kembarannya yang punya frames
	if best is AnimatedSprite2D and (best as AnimatedSprite2D).sprite_frames == null:
		for c in found:
			if (c as AnimatedSprite2D).sprite_frames != null:
				best = c
				break
	# buang kembaran (AnimatedSprite2D2, AttackHitbox2, dst.)
	for c in found:
		if c != best and str(c.name).begins_with(base_name):
			c.queue_free()
	return best


func _ready() -> void:
	add_to_group("player")
	_spawn_point = global_position
	if sprite == null:
		push_error("player.gd: AnimatedSprite2D tidak ditemukan di " + str(get_path()))
	else:
		sprite.frame_changed.connect(_align_feet)
		_align_feet()
	if attack_hitbox == null:
		push_error("player.gd: Area2D (AttackHitbox) tidak ditemukan di " + str(get_path()))
	else:
		_ensure_hitbox_shape()
	_build_interact_area()
	_build_slash()
	_sfx = AudioStreamPlayer.new()
	_sfx.volume_db = -6.0
	add_child(_sfx)
	_play_anim("Idle")


## AttackHitbox2 di map2.tscn tidak punya CollisionShape2D (ikon peringatan kuning di editor),
## jadi serangan tidak pernah mengenai apa pun. Bentuknya dibuat lewat kode kalau belum ada.
func _ensure_hitbox_shape() -> void:
	var has_shape := false
	for c in attack_hitbox.get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape != null:
			has_shape = true
			break
	if not has_shape:
		var shape := CollisionShape2D.new()
		shape.name = "AutoHitShape"
		var rect := RectangleShape2D.new()
		rect.size = Vector2(56.0, 70.0)
		shape.shape = rect
		attack_hitbox.add_child(shape)
	# deteksi semua layer; yang kena tetap difilter lewat grup "enemy" di _update_attack_hitbox
	attack_hitbox.collision_layer = 0
	attack_hitbox.collision_mask = 0xFFFFFFFF
	attack_hitbox.monitorable = false


func _build_interact_area() -> void:
	_interact_area = Area2D.new()
	_interact_area.name = "InteractArea"
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 9
	_interact_area.monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 120.0
	shape.shape = circle
	_interact_area.add_child(shape)
	add_child(_interact_area)


func _build_slash() -> void:
	_slash = Sprite2D.new()
	_slash.name = "SlashEffect"
	_slash.texture = _make_slash_texture()
	_slash.visible = false
	_slash.z_index = 5
	add_child(_slash)


func _make_slash_texture() -> ImageTexture:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in size:
		for x in size:
			var v := Vector2(x - 6, y - 32)
			var r := v.length()
			var a := v.angle()
			if r > 20.0 and r < 31.0 and a > -0.95 and a < 0.95:
				var alpha := 1.0 - absf(a) * 0.5
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)


# --------------------------------------------------------------------------
# Movement
# --------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_attack_left = maxf(0.0, _attack_left - delta)
	_invuln_left = maxf(0.0, _invuln_left - delta)
	_update_invuln_flash()

	var dir := 0.0
	if controls_enabled:
		dir = Input.get_axis("move_left", "move_right")

	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		_coyote_left = maxf(0.0, _coyote_left - delta)
	else:
		_coyote_left = COYOTE_TIME

	if controls_enabled and Input.is_action_just_pressed("jump") and _coyote_left > 0.0:
		velocity.y = JUMP_VELOCITY
		_coyote_left = 0.0
		_play_sfx(SFX_JUMP)

	if absf(dir) > 0.01:
		facing = 1 if dir > 0.0 else -1
		if sprite != null:
			sprite.flip_h = facing < 0
		velocity.x = dir * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 8.0 * delta)

	if controls_enabled and Input.is_action_just_pressed("attack") and _attack_cooldown <= 0.0:
		_attack()

	# keep the slash in front of the character
	if _slash.visible:
		_slash.position = Vector2(facing * 24, 48)
		_slash.flip_h = facing < 0

	move_and_slide()
	_update_attack_hitbox()
	_update_animation(dir)
	_update_interaction()

	# fell out of the level
	if global_position.y > 1400.0:
		_respawn(true)


func _update_animation(dir: float) -> void:
	if not is_on_floor():
		_play_anim("Jump")
	elif absf(dir) > 0.01:
		_play_anim("Run")
	else:
		_play_anim("Idle")


func _play_anim(anim_name: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(anim_name):
		return
	if sprite.animation != anim_name:
		sprite.play(anim_name)


func _play_sfx(stream: AudioStream) -> void:
	if _sfx == null or stream == null:
		return
	_sfx.stream = stream
	_sfx.play()


# --------------------------------------------------------------------------
# Attack
# --------------------------------------------------------------------------
func _attack() -> void:
	_attack_cooldown = ATTACK_COOLDOWN
	_attack_left = 0.14
	_play_sfx(SFX_ATTACK)
	_flash_slash()

	_swing_hits.clear()
	if attack_hitbox == null:
		return
	attack_hitbox.position.x = facing * 34.0
	attack_hitbox.monitoring = true


func _update_attack_hitbox() -> void:
	if attack_hitbox == null:
		return
	attack_hitbox.monitoring = _attack_left > 0.0
	if _attack_left <= 0.0:
		return
	var targets: Array = []
	targets.append_array(attack_hitbox.get_overlapping_bodies())
	targets.append_array(attack_hitbox.get_overlapping_areas())
	for enemy in targets:
		if enemy.is_in_group("enemy") and enemy.has_method("take_damage") and enemy.get_instance_id() not in _swing_hits:
			_swing_hits.append(enemy.get_instance_id())
			enemy.take_damage(ATTACK_DAMAGE, facing)


func _align_feet() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if sprite.animation == &"Jump":
		return
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not _feet_offsets.has(texture):
		var image := texture.get_image()
		_feet_offsets[texture] = 74.0 - (image.get_used_rect().end.y - texture.get_height() * 0.5)
	sprite.position.y = _feet_offsets[texture]


func _flash_slash() -> void:
	_slash.visible = true
	_slash.modulate.a = 1.0
	_slash.rotation = -facing * 0.35
	if _slash_tween != null and _slash_tween.is_valid():
		_slash_tween.kill()
	_slash_tween = create_tween()
	_slash_tween.tween_property(_slash, "modulate:a", 0.0, 0.16)
	_slash_tween.tween_callback(func(): _slash.visible = false)


# --------------------------------------------------------------------------
# Damage & respawn
# --------------------------------------------------------------------------
func take_damage(amount: int, from_x: float = 0.0) -> void:
	if is_dead or _invuln_left > 0.0:
		return
	_invuln_left = INVULN_TIME
	_play_sfx(SFX_HURT)
	var died := GameState.damage_player(amount)
	if from_x != 0.0:
		var push := signf(global_position.x - from_x)
		velocity.x = push * KNOCKBACK
		velocity.y = -170.0
	if died:
		_die()
	else:
		if Hud: Hud.toast(Story.TOAST_DANGER, 1.4)


func _update_invuln_flash() -> void:
	if sprite == null:
		return
	if _invuln_left > 0.0:
		var blink := fmod(_invuln_left, 0.16) < 0.08
		sprite.modulate.a = 0.35 if blink else 1.0
	elif not is_dead:
		sprite.modulate.a = 1.0


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	health_depleted.emit()
	_play_anim("Dead")
	await get_tree().create_timer(1.1).timeout
	_respawn(true)


func _respawn(show_message: bool) -> void:
	GameState.heal_full()
	global_position = _spawn_point
	velocity = Vector2.ZERO
	is_dead = false
	_invuln_left = INVULN_TIME
	if sprite != null:
		sprite.modulate.a = 1.0
	_play_anim("Idle")
	if show_message:
		Hud.toast(Story.TOAST_DIED)


func set_spawn_point(point: Vector2) -> void:
	_spawn_point = point


# --------------------------------------------------------------------------
# Interaction
# --------------------------------------------------------------------------
func _update_interaction() -> void:
	if not controls_enabled or Dialogue.is_active or is_dead:
		if Hud: Hud.hide_prompt()
		_active_interactable = null
		_interact_held = Input.is_action_pressed("interact")
		return

	_interactables = []
	_interactables.append_array(_interact_area.get_overlapping_areas())
	_interactables.append_array(_interact_area.get_overlapping_bodies())
	var best: Node = null
	var best_dist := INF
	for node in _interactables:
		if not node.is_in_group("interactable"):
			continue
		if node.has_method("can_interact") and not node.can_interact():
			continue
		var d := global_position.distance_to((node as Node2D).global_position)
		if d < best_dist:
			best_dist = d
			best = node

	var held := Input.is_action_pressed("interact")
	var pressed := held and not _interact_held
	_interact_held = held

	_active_interactable = best
	if best != null:
		if Hud: Hud.show_prompt(best.get_prompt())
		if pressed:
			if Hud: Hud.hide_prompt()
			best.interact(self)
	else:
		if Hud: Hud.hide_prompt()

func disable_controls() -> void:
	controls_enabled = false
	velocity.x = 0.0


func enable_controls() -> void:
	controls_enabled = true
