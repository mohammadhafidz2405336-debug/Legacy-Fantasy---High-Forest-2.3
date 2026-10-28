extends Node
##
## GameState (autoload) - single source of truth for the run.
##
## Holds the mission counters, the story flags that make introductions
## one-time-only, and the team data loaded from res://config/team.json.
## UI nodes listen to the signals below instead of polling.
##

signal health_changed(current: int, maximum: int)
signal coins_changed(collected: int, required: int)
signal enemies_changed(defeated: int, required: int)
signal objectives_changed()          ## any mission counter moved
signal player_died

const MAX_HEALTH := 100
const TEAM_CONFIG_PATH := "res://config/team.json"

# --- live run state ---
var player_health: int = MAX_HEALTH
var coins: int = 0
var coins_required: int = 0
var enemies_defeated: int = 0
var enemies_required: int = 0
var mission_active := false          ## only true inside Map 2, so Map 1 kills don't count

# --- story flags (one-time events, survive scene changes) ---
var opening_seen := false
var zhafran_intro_seen := false
var sandho_intro_seen := false
var sandho_joined := false
var letter_read := false
var portal_unlocked := false
var map2_intro_seen := false
var hafidz_rescued := false

var team_name := "Tim"
var members: Dictionary = {}         ## key -> {name, role, nim, portrait}


func _ready() -> void:
	load_team()


# --------------------------------------------------------------------------
# Team data
# --------------------------------------------------------------------------
func load_team() -> void:
	members.clear()
	var f := FileAccess.open(TEAM_CONFIG_PATH, FileAccess.READ)
	if f == null:
		push_warning("Tidak bisa membuka %s" % TEAM_CONFIG_PATH)
		_default_team()
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Format %s tidak valid, memakai data bawaan." % TEAM_CONFIG_PATH)
		_default_team()
		return
	team_name = String(parsed.get("team_name", "Tim"))
	for entry in parsed.get("members", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var key := String(entry.get("key", ""))
		if key.is_empty():
			continue
		members[key] = {
			"name": String(entry.get("name", key.capitalize())),
			"role": String(entry.get("role", "")),
			"nim": String(entry.get("nim", "")),
			"portrait": String(entry.get("portrait", "")),
		}
	if members.is_empty():
		_default_team()


func _default_team() -> void:
	members = {
		"zhafran": {"name": "Zhafran", "role": "Artist", "nim": "", "portrait": "res://portraits/zhafran.png"},
		"sandho": {"name": "Sandho", "role": "Project Manager & Level Manager", "nim": "", "portrait": "res://portraits/sandho.png"},
		"hafidz": {"name": "Hafidz", "role": "Programmer", "nim": "", "portrait": "res://portraits/hafidz.png"},
	}


func member(key: String) -> Dictionary:
	return members.get(key, {"name": key.capitalize(), "role": "", "nim": "", "portrait": ""})


func member_name(key: String) -> String:
	return String(member(key)["name"])


func member_role(key: String) -> String:
	return String(member(key)["role"])


## Returns "" when the NIM has not been filled in yet - never invent a number.
func member_nim(key: String) -> String:
	return String(member(key)["nim"]).strip_edges()


func member_portrait(key: String) -> Texture2D:
	var path := String(member(key)["portrait"])
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


# --------------------------------------------------------------------------
# Health
# --------------------------------------------------------------------------
func set_health(value: int) -> void:
	player_health = clampi(value, 0, MAX_HEALTH)
	health_changed.emit(player_health, MAX_HEALTH)


func heal_full() -> void:
	set_health(MAX_HEALTH)


## Applies damage. Returns true when this hit emptied the health bar.
func damage_player(amount: int) -> bool:
	if player_health <= 0:
		return false
	set_health(player_health - amount)
	return player_health <= 0


# --------------------------------------------------------------------------
# Mission counters
# --------------------------------------------------------------------------
## Called by Map 2 with the real number of coins/enemies found in the scene,
## so the HUD counters can never drift away from the actual level content.
func start_mission(coin_total: int, enemy_total: int) -> void:
	mission_active = true
	coins = 0
	enemies_defeated = 0
	coins_required = coin_total
	enemies_required = enemy_total
	coins_changed.emit(coins, coins_required)
	enemies_changed.emit(enemies_defeated, enemies_required)
	objectives_changed.emit()


func add_coin() -> void:
	coins += 1
	coins_changed.emit(coins, coins_required)
	objectives_changed.emit()


func register_enemy_defeated() -> void:
	if not mission_active:
		return
	enemies_defeated += 1
	enemies_changed.emit(enemies_defeated, enemies_required)
	objectives_changed.emit()


func coins_done() -> bool:
	return coins >= coins_required


func enemies_done() -> bool:
	return enemies_defeated >= enemies_required


func objectives_complete() -> bool:
	return coins_done() and enemies_done()


## Human readable list of what is still missing, used by the rescue gate.
func remaining_objectives_text() -> String:
	var parts: Array[String] = []
	if not coins_done():
		parts.append("koin %d/%d" % [coins, coins_required])
	if not enemies_done():
		parts.append("monster %d/%d" % [enemies_defeated, enemies_required])
	if parts.is_empty():
		return ""
	return "Masih kurang: " + ", ".join(parts) + "."


# --------------------------------------------------------------------------
# Run lifecycle
# --------------------------------------------------------------------------
func reset_run() -> void:
	player_health = MAX_HEALTH
	coins = 0
	coins_required = 0
	enemies_defeated = 0
	enemies_required = 0
	mission_active = false
	opening_seen = false
	zhafran_intro_seen = false
	sandho_intro_seen = false
	sandho_joined = false
	letter_read = false
	portal_unlocked = false
	map2_intro_seen = false
	hafidz_rescued = false
	health_changed.emit(player_health, MAX_HEALTH)
	coins_changed.emit(coins, coins_required)
	enemies_changed.emit(enemies_defeated, enemies_required)
