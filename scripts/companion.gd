extends CharacterBody2D
##
## Sandho - Project Manager & Level Manager.
## Starts as a standing NPC in Map 1, then becomes Zhafran's companion and
## follows him for the rest of the level (and Map 2).
## Attached to res://Scene/char_sandho.tscn
##

const GRAVITY := 1500.0
const RUN_SPEED := 165.0
const JUMP_VELOCITY := -540.0
const FOLLOW_DISTANCE := 52.0
var _attack_cooldown := 0.0
var _feet_offsets: Dictionary = {}

var is_companion := false

var _player: Node2D
var _sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 8
	collision_mask = 1
	_sprite = _pick_sprite()
	_player = get_tree().get_first_node_in_group("player")
	if _sprite == null:
		push_error("companion.gd: AnimatedSprite2D tidak ditemukan di " + str(get_path()))
	else:
		_sprite.frame_changed.connect(_align_feet)
	_play("Idle")
	_align_feet()


## Cari AnimatedSprite2D lewat tipe, jadi nama node ("AnimatedSprite2D2", dll) tidak masalah.
## Sprite kembar otomatis dibuang supaya karakter tidak tampil dobel.
func _pick_sprite() -> AnimatedSprite2D:
	var found: Array[AnimatedSprite2D] = []
	for ch in get_children():
		if ch is AnimatedSprite2D:
			found.append(ch)
	if found.is_empty():
		return null
	var best: AnimatedSprite2D = found[0]
	for s in found:
		if str(s.name) == "AnimatedSprite2D":
			best = s
			break
	if best.sprite_frames == null:
		for s in found:
			if s.sprite_frames != null:
				best = s
				break
	for s in found:
		if s != best and str(s.name).begins_with("AnimatedSprite2D"):
			s.queue_free()
	return best


func start_following() -> void:
	is_companion = true
	# sudah jadi teman: tidak bisa diajak bicara lagi, jadi prompt "Tekan E" tidak muncul
	if is_in_group("interactable"):
		remove_from_group("interactable")
	_player = get_tree().get_first_node_in_group("player")
	collision_layer = 8
	collision_mask = 1


func _physics_process(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 780.0)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	if not is_companion or _player == null:
		velocity.x = move_toward(velocity.x, 0.0, RUN_SPEED * 6.0 * delta)
		move_and_slide()
		_play("Idle")
		return

	var player_pos := _player.global_position
	var facing: int = int(_player.get("facing")) if _player.get("facing") != null else 1
	if facing == 0:
		facing = 1

	var desired_x := player_pos.x - facing * FOLLOW_DISTANCE
	var dx := desired_x - global_position.x

	if absf(dx) > 10.0:
		var direction := signf(dx)
		velocity.x = direction * minf(RUN_SPEED, absf(dx) * 6.0)
		if _sprite != null:
			_sprite.flip_h = direction < 0.0
		_play("Walk")
		if is_on_floor():
			var foot := global_position + Vector2(direction * 23.0, 72.0)
			var ground := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(foot, foot + Vector2(0, 38), 1))
			# ponytail: local jumps navigate reachable steps/gaps, not arbitrary routes.
			if test_move(global_transform, Vector2(direction * 12.0, 0)) or ground.is_empty() or player_pos.y < global_position.y - 28.0:
				velocity.y = JUMP_VELOCITY
	else:
		velocity.x = move_toward(velocity.x, 0.0, RUN_SPEED * 8.0 * delta)
		_play("Idle")

	move_and_slide()

	# Sandho also helps attack nearby enemies!
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			if _attack_cooldown <= 0.0 and global_position.distance_to(enemy.global_position) < 90.0:
				enemy.take_damage(5, int(signf(enemy.global_position.x - global_position.x)))
				_attack_cooldown = 0.6
				break


func can_interact() -> bool:
	if is_companion or GameState.sandho_intro_seen or Dialogue.is_active:
		return false
	# hanya bisa diajak bicara di scene yang punya intro Sandho (Map 1)
	return get_parent() != null and get_parent().has_method("_run_sandho_intro")


func get_prompt() -> String:
	return "Tekan %s untuk berbicara dengan Sandho" % UIKit.key_name("interact")


func interact(player: Node) -> void:
	if can_interact() and player is Node2D and global_position.distance_to(player.global_position) <= 120.0 and get_parent().has_method("_run_sandho_intro"):
		get_parent()._run_sandho_intro()


func _align_feet() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if _sprite.animation == &"Jump":
		return
	var texture := _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	if not _feet_offsets.has(texture):
		_feet_offsets[texture] = 74.0 - (texture.get_image().get_used_rect().end.y - texture.get_height() * 0.5)
	_sprite.position.y = _feet_offsets[texture]


func _play(animation: String) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if not _sprite.sprite_frames.has_animation(animation):
		return
	if _sprite.animation != animation:
		_sprite.play(animation)
