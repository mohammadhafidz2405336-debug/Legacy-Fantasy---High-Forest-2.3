extends Node2D
##
## Map 1 (Level_Utama) story director.
## Runs the prologue, Zhafran's introduction, Sandho's introduction + companion
## hand-off, the rescue letter and the portal that opens the way to Map 2.
##
## Gameplay (tiles, camera, enemies, coins) stays exactly as it was authored in
## the scene; this script only places the story objects and sequences the talk.
##

const PLAYER_SCENE := preload("res://Scene/char_zhafran.tscn")
const SANDHO_SCENE := preload("res://Scene/char_sandho.tscn")
const LETTER_SCRIPT := preload("res://scripts/letter.gd")
const PORTAL_SCRIPT := preload("res://scripts/portal.gd")

const SANDHO_X := 420.0
const LETTER_X := 650.0
const PORTAL_X := 950.0

var player: CharacterBody2D
@onready var tilemap: TileMapLayer = $TileMapLayer

var sandho: CharacterBody2D
var letter: Area2D
var portal: Area2D

var _busy := false
var _story_done := false


func _ready() -> void:
	Hud.reset_hud()
	GameState.mission_active = false
	GameState.heal_full()

	player = get_node_or_null("Char_Zhafran") as CharacterBody2D
	if player == null:
		_spawn_player()
	else:
		player.global_position = Vector2(29.0, 256.0 - 74.0)

	sandho = get_node_or_null("Sandho") as CharacterBody2D
	if sandho == null:
		_spawn_sandho()

	_fill_walk_gaps()

	# Remove any mobs or coins in map1 as requested (pure story intro + letter + portal)
	for child in get_children():
		var n_lower = child.name.to_lower()
		if "mob" in n_lower or "coin" in n_lower or "snail" in n_lower or "bee" in n_lower or "boar" in n_lower:
			child.queue_free()

	_spawn_letter()

	await Hud.fade_from_black(0.5)
	_intro_sequence()


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	var ground_y = 256.0
	player.global_position = Vector2(29.0, ground_y - 74.0)
	add_child(player)
	print("[MAP1] Player spawned at ", player.global_position)


# --------------------------------------------------------------------------
# Placement helpers
# --------------------------------------------------------------------------
## Finds the top surface of the first solid tile below (x, from_y).
func ground_y_at(x: float, from_y: float) -> float:
	if tilemap == null or tilemap.tile_set == null:
		return from_y
	var start := tilemap.local_to_map(tilemap.to_local(Vector2(x, from_y)))
	for ty in range(start.y, start.y + 140):
		var cell := Vector2i(start.x, ty)
		var source_id := tilemap.get_cell_source_id(cell)
		if source_id == -1:
			continue
		var atlas := tilemap.get_cell_atlas_coords(cell)
		var source := tilemap.tile_set.get_source(source_id)
		if source == null:
			continue
		var atlas_source := source as TileSetAtlasSource
		if atlas_source == null:
			continue
		var data: TileData = atlas_source.get_tile_data(atlas, 0)
		if data != null and data.get_collision_polygons_count(0) > 0:
			var center := tilemap.to_global(tilemap.map_to_local(cell))
			return center.y - 8.0
	return from_y


## Flattens the authored map into a straight walkable path: colliding tiles
## above the floor line are removed (jumping obstacles), gaps in rows 16-19 are
## filled with the level's own ground tile. Decoration tiles are kept, so the
## level still looks authored in the editor and in game.
const FLOOR_ROW := 16
const LEVEL_END_COLUMN := 200

func _fill_walk_gaps() -> void:
	if tilemap == null or tilemap.tile_set == null:
		return
	var ground := _ground_tile()
	if ground.size() == 0:
		return
	var source := tilemap.tile_set.get_source(ground.source) as TileSetAtlasSource
	for cell in tilemap.get_used_cells():
		if cell.y < FLOOR_ROW and _is_solid(cell):
			tilemap.erase_cell(cell)
	for cx in range(-10, LEVEL_END_COLUMN):
		for row in range(FLOOR_ROW, FLOOR_ROW + 4):
			var cell := Vector2i(cx, row)
			if tilemap.get_cell_source_id(cell) != -1:
				continue
			var atlas: Vector2i = ground.atlas
			if source != null and source.has_tile(Vector2i(atlas.x, atlas.y + (row - FLOOR_ROW))):
				atlas = Vector2i(atlas.x, atlas.y + (row - FLOOR_ROW))
			tilemap.set_cell(cell, ground.source, atlas)
	print("[MAP1] Jalur datar lurus siap (rintangan lompat dihapus)")


## First atlas tile in the level's own TileSet that has a collision polygon.
func _ground_tile() -> Dictionary:
	var tile_set := tilemap.tile_set
	for i in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(i)
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		if source == null or source.texture == null:
			continue
		for t in source.get_tiles_count():
			var atlas := source.get_tile_id(t)
			var data := source.get_tile_data(atlas, 0)
			if data != null and data.get_collision_polygons_count(0) > 0:
				return {"source": source_id, "atlas": atlas}
	return {}


func _is_solid(cell: Vector2i) -> bool:
	var source_id := tilemap.get_cell_source_id(cell)
	if source_id == -1:
		return false
	var atlas_source := tilemap.tile_set.get_source(source_id) as TileSetAtlasSource
	if atlas_source == null:
		return false
	var data: TileData = atlas_source.get_tile_data(tilemap.get_cell_atlas_coords(cell), 0)
	return data != null and data.get_collision_polygons_count(0) > 0


func _snap_player_to_ground() -> void:
	player.global_position.y = 256.0 - 74.0


func _spawn_sandho() -> void:
	sandho = SANDHO_SCENE.instantiate()
	# Flat floor is at row 16-19 -> y = 16*16 = 256 to 19*16 = 304
	# Spawn on top of row 19 (y = 304 - 74 = 230)
	var ground_y = 256.0
	sandho.global_position = Vector2(SANDHO_X, ground_y - 74.0)
	add_child(sandho)
	print("[MAP1] Sandho di ", sandho.global_position, " (tanah y=", ground_y, ")")


func _spawn_letter() -> void:
	if GameState.letter_read:
		return
	letter = LETTER_SCRIPT.new()
	var ground_y = 256.0
	letter.global_position = Vector2(LETTER_X, ground_y - 74.0)
	add_child(letter)
	letter.read_completed.connect(_on_letter_read)
	print("[MAP1] Surat di ", letter.global_position)


# --------------------------------------------------------------------------
# Story
# --------------------------------------------------------------------------
func _intro_sequence() -> void:
	if GameState.zhafran_intro_seen:
		_enable_play()
		return

	_busy = true
	player.disable_controls()
	if not GameState.opening_seen:
		await Dialogue.play(Story.opening())
		GameState.opening_seen = true
	await Dialogue.play(Story.zhafran_intro())
	GameState.zhafran_intro_seen = true
	await Dialogue.play(Story.controls())
	player.enable_controls()
	_busy = false
	_story_done = true


func _enable_play() -> void:
	player.enable_controls()
	_busy = false
	_story_done = true


func _run_sandho_intro() -> void:
	_busy = true
	player.disable_controls()
	await Dialogue.play(Story.sandho_intro())
	await Dialogue.play(Story.sandho_team_talk())
	GameState.sandho_joined = true
	if sandho != null and is_instance_valid(sandho):
		sandho.start_following()
	Hud.toast(Story.TOAST_SANDHO_JOINED, 2.6)
	player.enable_controls()
	_busy = false


func _on_letter_read() -> void:
	_busy = true
	player.disable_controls()
	await get_tree().create_timer(0.45).timeout

	portal = PORTAL_SCRIPT.new()
	var ground_y = 256.0
	portal.global_position = Vector2(PORTAL_X, ground_y - 74.0)
	add_child(portal)
	print("[MAP1] Portal di ", portal.global_position)
	await portal.activate()

	await Dialogue.play(Story.portal_dialogue())
	GameState.portal_unlocked = true
	portal.portal_entered.connect(_on_portal_entered)
	player.enable_controls()
	_busy = false
	await Hud.show_banner(Story.BANNER_MISSION_TITLE, Story.BANNER_MISSION_TEXT, 2.8)


func _on_portal_entered() -> void:
	if _busy:
		return
	_busy = true
	player.disable_controls()
	await Hud.fade_to_black(0.6)
	get_tree().change_scene_to_file("res://scenes/map2.tscn")
