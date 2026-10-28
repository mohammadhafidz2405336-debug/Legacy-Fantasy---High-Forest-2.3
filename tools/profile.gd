extends SceneTree

## Prints the walkable floor height for a range of x coordinates of Map 1,
## so story objects can be placed on ground the player can actually reach.

func _init() -> void:
	var ps: PackedScene = load("res://Scene/node_2d.tscn")
	var level: Node = ps.instantiate()
	var tm: TileMapLayer = level.get_node("TileMapLayer")
	var ts: TileSet = tm.tile_set
	var player: Node2D = level.get_node("Char_Zhafran")
	var start_y: float = player.global_position.y
	print("PLAYER START ", player.global_position)

	var last := -9999.0
	var line := ""
	var x := 0.0
	while x < 1600.0:
		var ground := _ground_y(tm, ts, x, start_y)
		var marker := "."
		if ground < 0.0:
			marker = "v"     # pit / nothing solid below
		else:
			if last > -9000.0 and absf(ground - last) > 1.0:
				marker = "^" if ground < last else "v"
		last = ground
		line += marker
		x += 16.0
	print("PROFILE (16px steps, x=0..1600, start_y=%.0f)" % start_y)
	print(line)
	for probe in [80.0, 300.0, 560.0, 800.0, 980.0, 1180.0]:
		print("  x=%4d -> floor %s" % [int(probe), str(_ground_y(tm, ts, probe, start_y))])
	level.free()
	quit()


func _ground_y(tm: TileMapLayer, ts: TileSet, x: float, from_y: float) -> float:
	var start := tm.local_to_map(tm.to_local(Vector2(x, from_y)))
	for ty in range(start.y, start.y + 140):
		var cell := Vector2i(start.x, ty)
		var source_id := tm.get_cell_source_id(cell)
		if source_id == -1:
			continue
		var src := ts.get_source(source_id) as TileSetAtlasSource
		if src == null:
			continue
		var data := src.get_tile_data(tm.get_cell_atlas_coords(cell), 0)
		if data != null and data.get_collision_polygons_count(0) > 0:
			return tm.to_global(tm.map_to_local(cell)).y - 8.0
	return -1.0
