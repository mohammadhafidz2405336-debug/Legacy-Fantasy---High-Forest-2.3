extends SceneTree

## ASCII dump of the solid tiles in the horizontal band the player walks in.

func _init() -> void:
	var ps: PackedScene = load("res://Scene/node_2d.tscn")
	var level: Node = ps.instantiate()
	var tm: TileMapLayer = level.get_node("TileMapLayer")
	var ts: TileSet = tm.tile_set
	var header := "     "
	var x := 0
	while x <= 1500:
		header += str(x / 100 % 10)
		x += 16
	print(header)
	for y in range(144, 340, 16):
		var line := "%4d " % y
		var cx := 0
		while cx <= 1500:
			var cell := tm.local_to_map(tm.to_local(Vector2(cx, y)))
			line += "#" if _solid(tm, ts, cell) else "."
			cx += 16
		print(line)
	level.free()
	quit()


func _solid(tm: TileMapLayer, ts: TileSet, cell: Vector2i) -> bool:
	var source_id := tm.get_cell_source_id(cell)
	if source_id == -1:
		return false
	var src := ts.get_source(source_id) as TileSetAtlasSource
	if src == null:
		return false
	var data := src.get_tile_data(tm.get_cell_atlas_coords(cell), 0)
	return data != null and data.get_collision_polygons_count(0) > 0
