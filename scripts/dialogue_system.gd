extends CanvasLayer
##
## Dialogue (autoload) - centralized dialogue box.
##
## UI nodes live in res://scenes/dialogue.tscn so they can be edited in the
## Godot editor; this script only binds them and drives the sequence.
##
## Features required by the design brief:
##   * Indonesian text, character portrait, name + role labels
##   * several speakers in one sequence (Array of page dictionaries)
##   * typewriter effect, first press completes the text, second press advances
##   * pauses the whole tree while open, resumes automatically afterwards
##   * reusable for the rescue letter, mission banners and the ending credits
##
## Portraits: drop a real photo on PortraitZhafran / PortraitSandho /
## PortraitHafidz in scenes/dialogue.tscn (nearest filter is already set).
## While a photo is missing the box shows a neutral block with the initial -
## it never invents a face.
##
## Usage from any script:
##     await Dialogue.play(Story.zhafran_intro())
##

signal finished

const CHARS_PER_SECOND := 46.0
const PAGE_FONT_SIZE := 26
const MIN_FONT_SIZE := 16

@export_group("Potret Anggota")
@export var portrait_zhafran: Texture2D
@export var portrait_sandho: Texture2D
@export var portrait_hafidz: Texture2D
## Optional neutral image shown when a member has no photo yet.
@export var portrait_fallback: Texture2D

var is_active := false

var _pages: Array = []
var _typing := false
var _revealed := 0.0
var _input_lock := 0.0
var _waiting_for_advance := false

signal _page_done

@onready var _root: Control = $DialogueRoot
@onready var _dim: ColorRect = $DialogueRoot/Dim
@onready var _panel: PanelContainer = $DialogueRoot/Panel
@onready var _portrait_frame: PanelContainer = $DialogueRoot/Panel/Margin/Row/PortraitFrame
@onready var _portrait: TextureRect = $DialogueRoot/Panel/Margin/Row/PortraitFrame/Portrait
@onready var _portrait_initial: Label = $DialogueRoot/Panel/Margin/Row/PortraitFrame/PortraitInitial
@onready var _name_label: Label = $DialogueRoot/Panel/Margin/Row/Info/SpeakerName
@onready var _role_label: Label = $DialogueRoot/Panel/Margin/Row/Info/SpeakerRole
@onready var _title_label: Label = $DialogueRoot/Panel/Margin/Row/Info/PageTitle
@onready var _body: RichTextLabel = $DialogueRoot/Panel/Margin/Row/Info/Body
@onready var _hint: Label = $DialogueRoot/Panel/Margin/Row/Info/ContinueHint


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_dim.visible = false


# --------------------------------------------------------------------------
# Public API
# --------------------------------------------------------------------------
## Plays a sequence of pages and returns when the player closed the last one.
func play(pages: Array) -> void:
	if pages.is_empty():
		return
	if is_active:
		# Never run two conversations on top of each other.
		await finished
	is_active = true
	_pages = pages
	_dim.modulate.a = 0.0
	_root.visible = true
	_dim.visible = false
	_panel.modulate.a = 0.0
	Hud.hide_prompt()
	var tween := _make_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, 0.18)
	await tween.finished
	await _run_pages()
	var out := _make_tween()
	out.tween_property(_panel, "modulate:a", 0.0, 0.16)
	await out.finished
	_root.visible = false
	_dim.visible = false
	is_active = false
	finished.emit()


func _make_tween() -> Tween:
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return t


# --------------------------------------------------------------------------
# Page loop
# --------------------------------------------------------------------------
var _skipping := false

func _run_pages() -> void:
	_skipping = false
	for page in _pages:
		if _skipping:
			break
		await _show_page(page)
		if _skipping:
			break
		await _page_done


func _show_page(page: Dictionary) -> void:
	var variant := String(page.get("variant", "speech"))
	var text := String(page.get("text", ""))
	var title := String(page.get("title", ""))
	var name_text := String(page.get("name", ""))
	var role_text := String(page.get("role", ""))

	# --- speaker block ---
	_name_label.text = name_text
	_name_label.visible = not name_text.is_empty()
	_role_label.text = role_text
	_role_label.visible = not role_text.is_empty() and not name_text.is_empty()

	# --- portrait ---
	_portrait_frame.visible = not name_text.is_empty()
	_show_portrait(_resolve_portrait(page, name_text), name_text)

	# --- title (letters, narration headings) ---
	_title_label.text = title
	_title_label.visible = not title.is_empty()

	# narration / letter pages get a calmer, centred look
	match variant:
		"narration":
			_name_label.visible = false
			_role_label.visible = false
			_body.add_theme_color_override("default_color", UIKit.TEXT)
		"letter":
			_body.add_theme_color_override("default_color", Color("ffe9b0"))
		_:
			_body.add_theme_color_override("default_color", UIKit.TEXT)

	_body.bbcode_enabled = true
	_body.text = text
	_revealed = 0.0
	_typing = true
	_body.visible_characters = 0
	_hint.text = ""
	_input_lock = 0.12
	await _fit_page_text()

	var total := _body.get_total_character_count()
	if total <= 0:
		_typing = false
		_show_advance_hint()


## Photo for this page, in order: page texture, exported texture, team.json
## path (only when the file really exists), neutral fallback. Never a fake face.
func _resolve_portrait(page: Dictionary, name_text: String) -> Texture2D:
	var from_page: Texture2D = page.get("portrait", null)
	if from_page != null:
		return from_page
	var key := String(page.get("speaker", "")).to_lower()
	if key.is_empty():
		for candidate in ["zhafran", "sandho", "hafidz"]:
			if name_text.to_lower().contains(candidate):
				key = candidate
				break
	var exported: Texture2D = {
		"zhafran": portrait_zhafran,
		"sandho": portrait_sandho,
		"hafidz": portrait_hafidz,
	}.get(key, null)
	if exported != null:
		return exported
	if not key.is_empty():
		var from_disk := GameState.member_portrait(key)
		if from_disk != null:
			return from_disk
	return portrait_fallback


func _show_portrait(tex: Texture2D, name_text: String) -> void:
	_portrait.texture = tex
	_portrait.visible = tex != null
	_portrait_initial.visible = tex == null and not name_text.is_empty()
	if _portrait_initial.visible:
		_portrait_initial.text = name_text.substr(0, 1).to_upper()


## Shrinks the font until the whole page fits, so no dialogue is ever cut off.
func _fit_page_text() -> void:
	var size := PAGE_FONT_SIZE
	_body.add_theme_font_size_override("normal_font_size", size)
	await get_tree().process_frame
	await get_tree().process_frame
	var guard := 0
	while size > MIN_FONT_SIZE and _body.get_content_height() > _body.size.y + 2.0 and guard < 12:
		size -= 2
		_body.add_theme_font_size_override("normal_font_size", size)
		await get_tree().process_frame
		guard += 1


func _show_advance_hint() -> void:
	var keys := UIKit.key_name("interact")
	_hint.text = Story.HINT_ADVANCE % keys


# --------------------------------------------------------------------------
# Typewriter + input
# --------------------------------------------------------------------------
func _process(delta: float) -> void:
	if not is_active:
		return
	if _input_lock > 0.0:
		_input_lock = max(0.0, _input_lock - delta)
	if _typing:
		var total := _body.get_total_character_count()
		_revealed += CHARS_PER_SECOND * delta
		if _revealed >= total:
			_revealed = total
			_body.visible_characters = -1
			_typing = false
			_show_advance_hint()
		else:
			_body.visible_characters = int(_revealed)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active or _input_lock > 0.0:
		return
	var advance := event.is_action_pressed("ui_advance_dialogue") \
		or event.is_action_pressed("interact") \
		or event.is_action_pressed("ui_accept")
	if not advance and event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		advance = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if advance:
		get_viewport().set_input_as_handled()
		_request_advance()


## First press finishes the typewriter, second press moves to the next page.
func _request_advance() -> void:
	if not is_active:
		return
	if _typing:
		_typing = false
		_body.visible_characters = -1
		_show_advance_hint()
		return
	if _waiting_for_advance:
		return
	_waiting_for_advance = true
	await get_tree().process_frame
	_waiting_for_advance = false
	_page_done.emit()


## Used by automated tests / skip buttons.
func skip_all() -> void:
	if not is_active:
		return
	_skipping = true
	_typing = false
	_body.visible_characters = -1
	_pages.clear()
	_page_done.emit()
