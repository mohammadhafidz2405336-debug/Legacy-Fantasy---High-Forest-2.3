extends Area2D
##
## Surat (rescue letter). Built entirely from code so Map 1 only needs to
## spawn it at a position on solid ground.
##

signal read_completed

const LETTER_TEXTURE := preload("res://Aset 3/pesan.png")

var _used := false
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("letter")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	monitorable = true
	# The authored scene already carries the sprite and the interaction shape.
	_sprite = get_node_or_null("LetterSprite") as Sprite2D
	if _sprite == null:
		_build_visual()
	if get_node_or_null("InteractShape") == null:
		_build_collision()
	_start_float()


func _build_visual() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "LetterSprite"
	_sprite.texture = LETTER_TEXTURE
	_sprite.scale = Vector2(3.2, 3.2)
	_sprite.position = Vector2(0, -30)
	add_child(_sprite)

	# soft glow so the letter is easy to spot in the level
	var glow := Sprite2D.new()
	glow.name = "Glow"
	glow.texture = LETTER_TEXTURE
	glow.scale = Vector2(4.6, 4.6)
	glow.position = Vector2(0, -30)
	glow.modulate = Color(1.0, 0.95, 0.6, 0.22)
	glow.z_index = -1
	add_child(glow)


func _build_collision() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(66, 70)
	shape.shape = rect
	shape.position = Vector2(0, -26)
	add_child(shape)


func _start_float() -> void:
	if _sprite == null:
		return
	var tween := create_tween().set_loops()
	tween.tween_property(_sprite, "position:y", -36.0, 1.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_sprite, "position:y", -26.0, 1.1).set_trans(Tween.TRANS_SINE)


# --------------------------------------------------------------------------
# Interactable API
# --------------------------------------------------------------------------
func can_interact() -> bool:
	return not _used and not GameState.letter_read


func get_prompt() -> String:
	return Story.PROMPT_LETTER % UIKit.key_name("interact")


func interact(_player: Node) -> void:
	if not can_interact():
		return
	_used = true
	Hud.hide_prompt()
	await Dialogue.play(Story.letter())
	GameState.letter_read = true
	Hud.toast(Story.TOAST_LETTER_READ, 2.4)
	read_completed.emit()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_property(self, "position:y", position.y - 20.0, 0.4)
	tween.chain().tween_callback(queue_free)