extends Control
##
## Menu utama (Bahasa Indonesia).
## UI nodes live in res://scenes/main_menu.tscn so they can be edited in the
## Godot editor; this script binds them and handles button presses.
##

var _starting := false

@onready var _start_button: Button = $Center/Column/StartButton
@onready var _credits_button: Button = $Center/Column/CreditsButton
@onready var _quit_button: Button = $Center/Column/QuitButton
@onready var _credits_panel: Control = $CreditsPanel
@onready var _credits_list: VBoxContainer = $CreditsPanel/CreditsBox/CreditsScroll/CreditsList
@onready var _members_box: VBoxContainer = $CreditsPanel/CreditsBox/CreditsScroll/CreditsList/Members
@onready var _back_button: Button = $CreditsPanel/CreditsBox/CreditsScroll/CreditsList/BackButton


func _ready() -> void:
	GameState.reset_run()
	_start_button.pressed.connect(_on_start_pressed)
	_credits_button.pressed.connect(_toggle_credits)
	_quit_button.pressed.connect(_on_quit_pressed)
	_back_button.pressed.connect(_toggle_credits)
	_build_credits_panel_content()
	_start_button.grab_focus()
	Hud.fade_from_black(0.6)


# --------------------------------------------------------------------------
# Credits Panel Content (driven by GameState / team.json)
# --------------------------------------------------------------------------
func _build_credits_panel_content() -> void:
	for child in _members_box.get_children():
		child.queue_free()

	for key in ["zhafran", "sandho", "hafidz"]:
		var member := GameState.member(key)
		var nim := GameState.member_nim(key)

		var role := Label.new()
		role.text = String(member["role"]).to_upper()
		role.theme_type_variation = &"Role"
		role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_members_box.add_child(role)

		var name_label := Label.new()
		name_label.text = String(member["name"])
		name_label.theme_type_variation = &"MemberName"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_members_box.add_child(name_label)

		var nim_label := Label.new()
		nim_label.text = "NIM: " + (nim if not nim.is_empty() else "(belum diisi)")
		nim_label.theme_type_variation = &"Nim"
		nim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_members_box.add_child(nim_label)

		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 12)
		_members_box.add_child(gap)


func _toggle_credits() -> void:
	_credits_panel.visible = not _credits_panel.visible
	if _credits_panel.visible:
		_back_button.grab_focus()
	else:
		_credits_button.grab_focus()


# --------------------------------------------------------------------------
# Actions
# --------------------------------------------------------------------------
func _on_start_pressed() -> void:
	if _starting:
		return
	_starting = true
	GameState.reset_run()
	await Hud.fade_to_black(0.6)
	get_tree().change_scene_to_file("res://scenes/map1.tscn")


func _on_quit_pressed() -> void:
	await Hud.fade_to_black(0.4)
	get_tree().quit()
