extends CharacterBody2D
##
## Hafidz - Programmer, found at the end of Map 2.
## Interaction is handled by the level script (it decides between the
## "objectives incomplete" talk and the full rescue sequence).
##

signal talk_requested

var _sprite: AnimatedSprite2D
var _area: Area2D


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("hafidz")
	name = "Hafidz"
	collision_layer = 8
	collision_mask = 1

	# the scene was duplicated from Zhafran, drop the extra camera
	var cam := get_node_or_null("Camera2D")
	if cam != null:
		cam.queue_free()

	_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if _sprite != null and _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation("default"):
		_sprite.animation = &"default"
		_sprite.stop()
		_sprite.frame = 0

	_area = Area2D.new()
	_area.name = "TalkArea"
	_area.collision_layer = 0
	_area.collision_mask = 1
	_area.monitoring = false
	add_child(_area)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(70, 110)
	shape.shape = rect
	_area.add_child(shape)


func _physics_process(delta: float) -> void:
	velocity.x = 0.0
	velocity.y = minf(velocity.y + 1500.0 * delta, 780.0)
	move_and_slide()


func can_interact() -> bool:
	return not Dialogue.is_active


func get_prompt() -> String:
	return Story.PROMPT_HAFIDZ % UIKit.key_name("interact")


func interact(_player: Node) -> void:
	Hud.hide_prompt()
	talk_requested.emit()


func celebrate() -> void:
	if _sprite != null:
		var rest_y := _sprite.position.y
		var tween := create_tween().set_loops(3)
		tween.tween_property(_sprite, "position:y", rest_y - 12.0, 0.18)
		tween.tween_property(_sprite, "position:y", rest_y, 0.18)
