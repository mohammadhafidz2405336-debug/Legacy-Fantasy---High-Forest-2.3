extends Node2D
##
## Map 2 - tempat Hafidz terjebak.
## The terrain, background, enemies, coins and NPC are laid out from code so the
## level content (and therefore the mission counters) is always known exactly.
##

const PLAYER_SCENE := preload("res://Scene/char_zhafran.tscn")
const SANDHO_SCENE := preload("res://Scene/char_sandho.tscn")
const HAFIDZ_SCENE := preload("res://Scene/char_hafidz.tscn")
const SNAIL_SCENE := preload("res://Scene/snail_mob.tscn")
const BEE_SCENE := preload("res://Scene/mob_bee.tscn")
const COIN_SCENE := preload("res://Scene/coin.tscn")

const GROUND_TEXTURE := preload("res://Aset2d/Aset1 lengkap/1 Tiles/Tile_22.png")
const BG_NIGHT := [
	preload("res://Aset2d/Aset1 lengkap/2 Background/Night/1.png"),
	preload("res://Aset2d/Aset1 lengkap/2 Background/Night/2.png"),
	preload("res://Aset2d/Aset1 lengkap/2 Background/Night/3.png"),
	preload("res://Aset2d/Aset1 lengkap/2 Background/Night/4.png"),
	preload("res://Aset2d/Aset1 lengkap/2 Background/Night/5.png"),
]

const GROUND_Y := 400.0

var tilemap: TileMapLayer
var player: CharacterBody2D
var sandho: CharacterBody2D
var hafidz: CharacterBody2D

var _busy := false
var _intro_done := false
var _coins: Array = []
var _enemies: Array = []
var _checkpoint_segment := -1

# x, top y, width, height (pixels)
var ground_rects: Array = [
	Rect2(0, GROUND_Y, 720, 190),
	Rect2(830, GROUND_Y, 700, 190),
	Rect2(1620, GROUND_Y, 800, 190),
]
var platform_rects: Array = [
	Rect2(300, 330, 130, 26),
	Rect2(520, 262, 120, 26),
	Rect2(1050, 330, 150, 26),
	Rect2(1300, 262, 120, 26),
	Rect2(1750, 330, 140, 26),
	Rect2(1980, 262, 120, 26),
]
# x, surface y (coin floats ~42px above it)
var coin_spots: Array = [
	Vector2(180, GROUND_Y),
	Vector2(360, 330),
	Vector2(580, 262),
	Vector2(900, GROUND_Y),
	Vector2(1120, 330),
	Vector2(1360, 262),
	Vector2(1700, GROUND_Y),
	Vector2(1810, 330),
]
var enemy_spots: Array = [
	{"type": "snail", "pos": Vector2(470, GROUND_Y - 20)},
	{"type": "snail", "pos": Vector2(1150, GROUND_Y - 20)},
	{"type": "snail", "pos": Vector2(1880, GROUND_Y - 20)},
	{"type": "bee", "pos": Vector2(700, 300)},
	{"type": "bee", "pos": Vector2(1520, 280)},
]


func _ready() -> void:
	Hud.reset_hud()
	GameState.heal_full()
	GameState.mission_active = true

	# Use pre-built scene elements (ParallaxBackground and TileMapLayer from map2.tscn)
	tilemap = $TileMapLayer
	# TileMapLayer already populated by bake_levels.gd, do NOT rebuild tiles
	# Actors already placed in the baked scene; get references instead of spawning new ones.
	_coins = get_node_or_null("Coins").get_children() if get_node_or_null("Coins") else []
	_enemies = get_node_or_null("Enemies").get_children() if get_node_or_null("Enemies") else []
	player = get_node_or_null("Char_Zhafran") as CharacterBody2D
	sandho = get_node_or_null("Sandho") as CharacterBody2D
	hafidz = get_node_or_null("Hafidz") as CharacterBody2D

	# Safety: buang Zhafran/Sandho ganda, TAPI jangan hapus yang asli (player, sandho, hafidz)
	for node in get_children():
		if node == player or node == sandho or node == hafidz:
			continue
		if node is CharacterBody2D:
			var name_lower = node.name.to_lower()
			if "zhafran" in name_lower:
				print("[MAP2] Removing duplicate player: ", node.name)
				node.queue_free()
			elif "sandho" in name_lower:
				print("[MAP2] Removing duplicate Sandho: ", node.name)
				node.queue_free()

	# Sandho selalu ikut Zhafran di Map 2 (juga kalau Map 2 dijalankan langsung dari editor)
	if sandho != null and is_instance_valid(sandho):
		sandho.start_following()

	# mission counters come from the real level content
	GameState.start_mission(_coins.size(), _enemies.size())
	Hud.show_mission()

	GameState.objectives_changed.connect(_on_objectives_changed)
	if hafidz != null and hafidz.has_signal("talk_requested"):
		hafidz.talk_requested.connect(_on_hafidz_talk)
	await Hud.fade_from_black(0.6)
	_intro_sequence()


# --------------------------------------------------------------------------
# Level construction
# --------------------------------------------------------------------------
func _build_background() -> void:
	# Background already built in map2.tscn scene, nothing to do here
	pass


func _build_tilemap_ground() -> void:
	if tilemap == null:
		tilemap = $TileMapLayer
	tilemap.tile_set = _build_tileset()
	tilemap.modulate = Color(0.82, 0.88, 1.0)

	for rect in ground_rects:
		_fill_rect(rect, true)
	for rect in platform_rects:
		_fill_rect(rect, true)


func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 1)

	var source := TileSetAtlasSource.new()
	source.texture = GROUND_TEXTURE
	source.texture_region_size = Vector2i(16, 16)
	ts.add_source(source, 0)

	var polygon := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	for coords in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		source.create_tile(coords)
		var data := source.get_tile_data(coords, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, polygon)
	return ts


func _fill_rect(rect: Rect2, solid: bool) -> void:
	if tilemap == null:
		return
	var start := tilemap.local_to_map(rect.position)
	var end := tilemap.local_to_map(rect.position + rect.size)
	for tx in range(start.x, end.x + 1):
		for ty in range(start.y, end.y + 1):
			var atlas := Vector2i(0, 0) if ty == start.y else Vector2i(0, 1)
			tilemap.set_cell(Vector2i(tx, ty), 0, atlas)


func _build_bounds() -> void:
	_add_wall(-24.0, 200.0, 24.0, 1200.0)
	_add_wall(2432.0, 200.0, 24.0, 1200.0)


func _add_wall(x: float, y: float, w: float, h: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, h)
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


# --------------------------------------------------------------------------
# Actors
# --------------------------------------------------------------------------
func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = Vector2(80, GROUND_Y - 74)
	add_child(player)
	player.set_spawn_point(player.global_position)


func _spawn_companion() -> void:
	if not GameState.sandho_joined:
		return
	sandho = SANDHO_SCENE.instantiate()
	sandho.global_position = Vector2(40, GROUND_Y - 74)
	add_child(sandho)
	sandho.start_following()


func _spawn_coins() -> void:
	for spot in coin_spots:
		var coin := COIN_SCENE.instantiate()
		coin.position = Vector2(spot.x, spot.y - 44)
		add_child(coin)
		_coins.append(coin)


func _spawn_enemies() -> void:
	for spot in enemy_spots:
		var scene: PackedScene = SNAIL_SCENE if spot["type"] == "snail" else BEE_SCENE
		var enemy := scene.instantiate()
		enemy.position = spot["pos"]
		if spot["type"] == "bee":
			enemy.flying = true
			enemy.max_health = 30
			enemy.speed = 34.0
			enemy.patrol_radius = 90.0
		else:
			enemy.max_health = 40
			enemy.speed = 24.0
			enemy.patrol_radius = 70.0
		add_child(enemy)
		_enemies.append(enemy)


func _spawn_hafidz() -> void:
	hafidz = HAFIDZ_SCENE.instantiate()
	hafidz.scale = Vector2(0.32, 0.32)
	hafidz.global_position = Vector2(2280, GROUND_Y - 58)
	add_child(hafidz)
	hafidz.talk_requested.connect(_on_hafidz_talk)


# --------------------------------------------------------------------------
# Story
# --------------------------------------------------------------------------
func _intro_sequence() -> void:
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout
	_busy = true
	player.disable_controls()
	if not GameState.map2_intro_seen:
		await Dialogue.play(Story.map2_intro())
		GameState.map2_intro_seen = true
		await Dialogue.play(Story.attack_hint())
	else:
		await Dialogue.play(Story.attack_hint())
	player.enable_controls()
	_busy = false
	_intro_done = true

func _process(_delta: float) -> void:
	if not _intro_done or _busy:
		return
	_update_checkpoint()


func _update_checkpoint() -> void:
	if player == null or not is_instance_valid(player):
		return
	for i in ground_rects.size():
		var rect: Rect2 = ground_rects[i]
		if player.global_position.x >= rect.position.x and player.global_position.x <= rect.position.x + rect.size.x:
			if _checkpoint_segment != i and player.is_on_floor():
				_checkpoint_segment = i
				player.set_spawn_point(Vector2(rect.position.x + 40.0, rect.position.y - 74.0))
			return


func _on_objectives_changed() -> void:
	pass


func _on_hafidz_talk() -> void:
	if _busy:
		return
	_busy = true
	player.disable_controls()
	if GameState.objectives_complete():
		await Dialogue.play(Story.hafidz_rescue())
		GameState.hafidz_rescued = true
		if hafidz != null and is_instance_valid(hafidz):
			hafidz.celebrate()
		await get_tree().create_timer(0.8).timeout
		await Hud.fade_to_black(0.8)
		get_tree().change_scene_to_file("res://scenes/ending.tscn")
		return

	var remaining := GameState.remaining_objectives_text()
	await Dialogue.play(Story.rescue_incomplete(remaining))
	Hud.toast(remaining, 3.2)
	player.enable_controls()
	_busy = false
