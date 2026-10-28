class_name UIKit
extends RefCounted
##
## Small helper library for building the game's UI from code.
## Keeps colours, fonts and panel styles in one place so the whole game
## (dialogue box, HUD, menu, credits) looks consistent.
##

const FONT := preload("res://brackeys_platformer_assets/fonts/PixelOperator8.ttf")
const FONT_BOLD := preload("res://brackeys_platformer_assets/fonts/PixelOperator8-Bold.ttf")

const BG := Color("0b1410")
const PANEL := Color("16261d")
const PANEL_SOFT := Color("1d3226")
const EDGE := Color("6fd18a")
const TEXT := Color("f1f7f2")
const MUTED := Color("9db6a5")
const ACCENT := Color("f5c542")
const DANGER := Color("e05656")
const GOOD := Color("7ee08a")


static func panel_style(bg: Color = PANEL, edge: Color = EDGE, border: int = 2, radius: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(14)
	return sb


static func theme(base_size: int = 24) -> Theme:
	var t := Theme.new()
	t.default_font = FONT
	t.default_font_size = base_size
	return t


static func make_label(text: String, size: int = 24, color: Color = TEXT, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT_BOLD if bold else FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func make_panel(bg: Color = PANEL, edge: Color = EDGE, border: int = 2) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(bg, edge, border))
	return p


## Returns "E", "K", "Spasi", ... for a project input action, so prompts always
## match the key that is actually configured in the Input Map.
static func key_name(action: String) -> String:
	if not InputMap.has_action(action):
		return "?"
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "?"
	var ev := events[0]
	if ev is InputEventKey:
		var code: Key = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
		var name := OS.get_keycode_string(code)
		if name == "Space":
			return "Spasi"
		if name == "Enter":
			return "Enter"
		return name
	if ev is InputEventMouseButton:
		return "Klik Kiri"
	return "?"


static func full_rect(node: Control) -> Control:
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
