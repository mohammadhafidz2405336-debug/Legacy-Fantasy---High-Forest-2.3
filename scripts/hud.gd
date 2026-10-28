extends CanvasLayer
##
## Hud (autoload) - health bar, coin counter, mission objectives, interaction
## prompts, notifications, mission banners and the screen fade used for
## scene transitions. Everything on screen during gameplay is Indonesian.
##
## UI nodes live in res://scenes/hud.tscn so they can be edited in the
## Godot editor; this script only binds them and drives the sequence.
##

const COIN_TEXTURE := preload("res://brackeys_platformer_assets/sprites/coin.png")

@onready var _root: Control = $HudRoot
@onready var _health_bar: ProgressBar = $HudRoot/HealthBox/HealthRow/HealthBar
@onready var _health_value: Label = $HudRoot/HealthBox/HealthRow/HealthValue
@onready var _coin_label: Label = $HudRoot/StatusColumn/CoinBox/CoinLabel
@onready var _mission_panel: PanelContainer = $HudRoot/StatusColumn/MissionPanel
@onready var _mission_coin: Label = $HudRoot/StatusColumn/MissionPanel/MissionBox/MissionCoins
@onready var _mission_enemy: Label = $HudRoot/StatusColumn/MissionPanel/MissionBox/MissionEnemies
@onready var _mission_hint: Label = $HudRoot/StatusColumn/MissionPanel/MissionBox/MissionHint
@onready var _prompt_center: CenterContainer = $HudRoot/PromptCenter
@onready var _prompt_label: Label = $HudRoot/PromptCenter/PromptPanel/PromptLabel
@onready var _toast_box: VBoxContainer = $HudRoot/ToastBox
@onready var _banner_center: CenterContainer = $HudRoot/BannerCenter
@onready var _banner_title: Label = $HudRoot/BannerCenter/BannerPanel/BannerBox/BannerTitle
@onready var _banner_text: Label = $HudRoot/BannerCenter/BannerPanel/BannerBox/BannerText
@onready var _fade: ColorRect = $HudRoot/Fade


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.health_changed.connect(_on_health_changed)
	GameState.coins_changed.connect(func(_a, _b): _refresh_mission())
	GameState.enemies_changed.connect(func(_a, _b): _refresh_mission())
	_on_health_changed(GameState.player_health, GameState.MAX_HEALTH)
	_refresh_mission()


# --------------------------------------------------------------------------
# Public API
# --------------------------------------------------------------------------
func show_mission() -> void:
	_mission_panel.visible = true
	_refresh_mission()


func hide_mission() -> void:
	_mission_panel.visible = false


func _refresh_mission() -> void:
	_coin_label.text = "Koin: %d" % GameState.coins
	_mission_coin.text = "Koin terkumpul: %d / %d" % [GameState.coins, GameState.coins_required]
	_mission_enemy.text = "Monster dikalahkan: %d / %d" % [GameState.enemies_defeated, GameState.enemies_required]


func _on_health_changed(current: int, maximum: int) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_value.text = str(current)
	var fill := (_health_bar.get_theme_stylebox("fill") as StyleBoxFlat).duplicate() as StyleBoxFlat
	if current > maximum * 0.5:
		fill.bg_color = UIKit.GOOD
	elif current > maximum * 0.25:
		fill.bg_color = UIKit.ACCENT
	else:
		fill.bg_color = UIKit.DANGER
	_health_bar.add_theme_stylebox_override("fill", fill)


func show_prompt(text: String) -> void:
	_prompt_label.text = text
	_prompt_center.visible = not text.is_empty()


func hide_prompt() -> void:
	_prompt_center.visible = false


func toast(text: String, duration: float = 2.2) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_type_variation = &"Toast"
	_toast_box.add_child(label)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(duration)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(label.queue_free)


## Big centered banner, e.g. "MISI PENYELAMATAN". Waits for it to disappear.
func show_banner(title: String, subtitle: String, duration: float = 2.6) -> void:
	_banner_title.text = title
	_banner_text.text = subtitle
	_banner_center.visible = true
	_banner_center.modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_banner_center, "modulate:a", 1.0, 0.3)
	await tween.finished
	await _wait(duration)
	var out := create_tween()
	out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	out.tween_property(_banner_center, "modulate:a", 0.0, 0.4)
	await out.finished
	_banner_center.visible = false


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


# --------------------------------------------------------------------------
# Screen fade (scene transitions)
# --------------------------------------------------------------------------
func fade_to_black(duration: float = 0.5) -> void:
	if _fade == null:
		return
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade, "modulate:a", 1.0, duration)
	await tween.finished


func fade_from_black(duration: float = 0.5) -> void:
	if _fade == null:
		return
	_fade.modulate.a = 1.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade, "modulate:a", 0.0, duration)
	await tween.finished
	_fade.modulate.a = 0.0


func reset_hud() -> void:
	hide_mission()
	hide_prompt()
	_banner_center.visible = false
	if _fade != null:
		_fade.modulate.a = 0.0
		# Stop any running tweens on fade (e.g., from previous scene transition)
		_fade.create_tween().kill()
	_refresh_mission()
