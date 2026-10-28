extends Area2D
##
## Portal menuju Map 2. Hidden (locked) until the rescue letter has been read,
## then plays an activation animation before it can be used.
##

signal portal_entered

const PORTAL_SHEET := preload("res://Aset 3/portal-Sheet (1).png")
const FRAME_SIZE := Vector2i(64, 64)
const FRAME_COUNT := 8
const SFX_OPEN := preload("res://brackeys_platformer_assets/sounds/power_up.wav")

var is_active := false
var _entering := false
var _sprite: AnimatedSprite2D
var _sheet: Sprite2D
var _label: Label
var _frame_timer: Timer
var _frame := 0


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("portal")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	monitorable = true
	# The authored scene carries PortalSprite (sheet) and InteractShape.
	_sheet = get_node_or_null("PortalSprite") as Sprite2D
	if _sheet == null:
		_build_visual()
	_label = get_node_or_null("PortalLabel") as Label
	if get_node_or_null("InteractShape") == null:
		_build_collision()
	visible = false
	set_active(false)


func _build_visual() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "PortalSprite"
	_sprite.sprite_frames = _build_frames()
	_sprite.scale = Vector2(2.0, 2.0)
	_sprite.position = Vector2(0, -46)
	add_child(_sprite)

	_label = UIKit.make_label("PORTAL", 16, UIKit.ACCENT, true)
	_label.name = "PortalLabel"
	_label.position = Vector2(-34, -112)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("open")
	frames.set_animation_speed("open", 12.0)
	frames.set_animation_loop("open", true)
	for i in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = PORTAL_SHEET
		atlas.region = Rect2(i * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame("open", atlas)
	return frames


## Authored sheet sprite: cycle hframes/frame instead of a SpriteFrames resource.
func _play_sheet() -> void:
	if _sheet == null or _frame_timer != null:
		return
	_frame_timer = Timer.new()
	_frame_timer.wait_time = 1.0 / 12.0
	_frame_timer.autostart = true
	_frame_timer.timeout.connect(_next_frame)
	add_child(_frame_timer)


func _next_frame() -> void:
	if _sheet == null:
		return
	_frame = (_frame + 1) % FRAME_COUNT
	_sheet.frame = _frame


func _build_collision() -> void:
	var shape := CollisionShape2D.new()
	shape.name = "InteractShape"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(90, 130)
	shape.shape = rect
	shape.position = Vector2(0, -46)
	add_child(shape)


func set_active(value: bool) -> void:
	is_active = value
	monitoring = value
	if not value:
		visible = false


## Plays the appearance animation and enables interaction.
func activate() -> void:
	visible = true
	scale = Vector2(0.15, 0.15)
	modulate.a = 0.0
	if _sprite != null:
		_sprite.play("open")
	_play_sheet()
	var sfx := AudioStreamPlayer.new()
	sfx.stream = SFX_OPEN
	sfx.volume_db = -10.0
	add_child(sfx)
	sfx.finished.connect(sfx.queue_free)
	sfx.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.6)
	await tween.finished
	set_active(true)
	_pulse()


func _pulse() -> void:
	var visual: Node2D = _sprite if _sprite != null else _sheet
	if visual == null:
		return
	var base_scale := visual.scale
	var tween := create_tween().set_loops()
	tween.tween_property(visual, "scale", base_scale * 1.06, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(visual, "scale", base_scale, 0.8).set_trans(Tween.TRANS_SINE)


# --------------------------------------------------------------------------
# Interactable API
# --------------------------------------------------------------------------
func can_interact() -> bool:
	return is_active and not _entering


func get_prompt() -> String:
	return Story.PROMPT_PORTAL % UIKit.key_name("interact")


func interact(_player: Node) -> void:
	if not can_interact():
		return
	_entering = true
	Hud.hide_prompt()
	portal_entered.emit()