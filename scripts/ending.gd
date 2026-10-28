extends Node2D
##
## Layar penutup: percakapan kerja sama tim, banner "MISI BERHASIL!",
## kredit, lalu fade out dan keluar dari game secara otomatis.
## Gunakan argumen --no-quit untuk mempertahankan layar (mode debug).
##
## UI nodes live in res://scenes/ending.tscn so they can be edited in the
## Godot editor; this script binds them and populates the credits dynamically.
##

const BG_DAY := preload("res://Aset2d/Aset1 lengkap/2 Background/Day/1.png")
const GROUND_TEXTURE := preload("res://Aset2d/Aset1 lengkap/1 Tiles/Tile_22.png")

const CHARACTER_Y := 470.0
const CREDITS_SPEED := 46.0   # piksel per detik

var _finished := false

@onready var _sky: Sprite2D = $Sky
@onready var _ground: TextureRect = $Ground
@onready var _title: Label = $EndTitle
@onready var _subtitle: Label = $EndSubtitle
@onready var _credits_layer: CanvasLayer = $CreditsLayer
@onready var _credits_box: Control = $CreditsLayer/CreditsFrame/CreditsContent
@onready var _credits_list: VBoxContainer = $CreditsLayer/CreditsFrame/CreditsContent/CreditsList
var _hint: Label


func _ready() -> void:
	Hud.reset_hud()
	GameState.mission_active = false
	_build_background_fallback()
	_build_characters()
	Hud.fade_from_black(0.8)
	_run_ending()


# --------------------------------------------------------------------------
# Visuals
# --------------------------------------------------------------------------
func _build_background_fallback() -> void:
	if _sky.texture == null:
		_sky.texture = BG_DAY
	if _ground.texture == null:
		_ground.texture = GROUND_TEXTURE
	_title.text = Story.TITLE_GAME
	_subtitle.text = Story.SUBTITLE_GAME


func _build_characters() -> void:
	var specs := [
		{"path": "res://Scene/char_sandho.tscn", "x": 400.0, "scale": 1.5, "flip": false},
		{"path": "res://Scene/char_zhafran.tscn", "x": 576.0, "scale": 1.6, "flip": false},
		{"path": "res://Scene/char_hafidz.tscn", "x": 760.0, "scale": 0.62, "flip": true},
	]
	for spec in specs:
		var sprite := _extract_sprite(spec["path"])
		if sprite == null:
			continue
		var scale_value: float = spec["scale"]
		sprite.scale = Vector2(scale_value, scale_value)
		sprite.flip_h = bool(spec["flip"])
		var frame_height := 160.0
		if sprite.sprite_frames != null and sprite.sprite_frames.get_frame_count(sprite.animation) > 0:
			frame_height = sprite.sprite_frames.get_frame_texture(sprite.animation, 0).get_height()
		sprite.position = Vector2(spec["x"], CHARACTER_Y - frame_height * scale_value * 0.5)
		add_child(sprite)


## Pulls the AnimatedSprite2D out of a character scene so the ending can show
## the characters without their physics, camera or player script.
func _extract_sprite(scene_path: String) -> AnimatedSprite2D:
	var packed: PackedScene = load(scene_path)
	if packed == null:
		return null
	var instance := packed.instantiate()
	var sprite := instance.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		instance.free()
		return null
	instance.remove_child(sprite)
	instance.free()
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("Idle"):
		sprite.play("Idle")
	elif sprite.sprite_frames != null and sprite.sprite_frames.has_animation("default"):
		sprite.play("default")
	return sprite


# --------------------------------------------------------------------------
# Flow
# --------------------------------------------------------------------------
func _run_ending() -> void:
	await get_tree().create_timer(0.5).timeout
	await Dialogue.play(Story.final_teamwork())
	await Hud.show_banner(Story.BANNER_SUCCESS_TITLE, Story.BANNER_SUCCESS_TEXT, 3.0)
	await _show_credits()
	await _finish()


func _show_credits() -> void:
	for child in _credits_list.get_children():
		child.queue_free()

	for line in Story.credits_lines():
		_credits_list.add_child(_credit_label(line))

	_credits_layer.visible = true
	await get_tree().process_frame
	var content_height := _credits_list.size.y + 200.0
	_credits_box.position = Vector2(0, 648.0)

	var duration: float = maxf(6.0, (648.0 + content_height) / CREDITS_SPEED)
	print("[ENDING] kredit: tinggi konten %.0f px, durasi %.1f s" % [content_height, duration])
	var tween := create_tween()
	tween.tween_property(_credits_box, "position:y", -content_height, duration)
	await tween.finished
	print("[ENDING] kredit selesai digulir")
	await get_tree().create_timer(0.6).timeout


func _credit_label(line: Dictionary) -> Control:
	var kind := String(line.get("kind", "body"))
	var text := String(line.get("text", ""))
	match kind:
		"title":
			var title := Label.new()
			title.text = text
			title.theme_type_variation = &"Title"
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			return title
		"subtitle":
			var subtitle := Label.new()
			subtitle.text = text
			subtitle.theme_type_variation = &"Subtitle"
			subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			return subtitle
		"role":
			var role := Label.new()
			role.text = text
			role.theme_type_variation = &"Role"
			role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			return role
		"name":
			var name_label := Label.new()
			name_label.text = text
			name_label.theme_type_variation = &"MemberName"
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			return name_label
		"nim":
			var nim := Label.new()
			nim.text = text
			nim.theme_type_variation = &"Nim"
			nim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			return nim
		"gap":
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(0, 26)
			return spacer
		_:
			var body := Label.new()
			body.text = text
			body.theme_type_variation = &"BodyText"
			body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			return body


func _finish() -> void:
	_finished = true
	print("[ENDING] fade out lalu keluar (boleh_keluar=%s)" % _can_quit())
	await Hud.fade_to_black(1.4)
	await get_tree().create_timer(0.4).timeout
	if _can_quit():
		get_tree().quit()
	else:
		_show_quit_hint()


func _can_quit() -> bool:
	return not OS.get_cmdline_args().has("--no-quit")


func _show_quit_hint() -> void:
	_hint = Label.new()
	_hint.text = "Kredit selesai. Tekan Esc untuk keluar."
	_hint.theme_type_variation = &"BodyText"
	_hint.set_anchors_preset(Control.PRESET_CENTER)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	layer.add_child(_hint)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _finished:
		get_tree().quit()
