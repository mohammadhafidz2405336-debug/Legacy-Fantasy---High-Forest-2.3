extends SceneTree

## Dumps the exact floor height per 16px column of Map 1, scanning downward
## from the height the player actually stands on.

func _init() -> void:
	var ps: PackedScene = load("res://Scene/node_2d.tscn")
	var level: Node = ps.instantiate()
	var tm: TileMapLayer = level.get_node("TileMapLayer")
	var ts: TileSet = tm.tile_set
	print("tilemap position=", tm.position, " scale=", tm.scale)
	var start := 292.0
	var x := 0.0
	var out: Array[String] = []
	while x <= 1500.0:
		var ground := _ground_y(tm, ts, x, start)
		out.append("%d:%s" % [int(x), ("-" if ground < 0.0 else str(int(ground)))])
		x += 32.0
	print("FROM %.0f" % start)
	print(" ".join(out))
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
