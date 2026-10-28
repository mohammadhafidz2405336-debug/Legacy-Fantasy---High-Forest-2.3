extends SceneTree

# One-shot helper: dumps level geometry so story objects can be placed on solid ground.
# Safe to delete after use.

func _init() -> void:
	var ps: PackedScene = load("res://Scene/node_2d.tscn")
	var n: Node = ps.instantiate()
	var tm: TileMapLayer = n.get_node("TileMapLayer")
	var ts: TileSet = tm.tile_set
	print("TILE_SIZE=", ts.tile_size)
	var counts := {}
	var solid := {}
	for c in tm.get_used_cells():
		var sid: int = tm.get_cell_source_id(c)
		var ac: Vector2i = tm.get_cell_atlas_coords(c)
		var key := "%d:%d,%d" % [sid, ac.x, ac.y]
		counts[key] = counts.get(key, 1) + 1
		var src := ts.get_source(sid)
		var td: TileData = src.get_tile_data(ac, 0)
		solid[key] = td != null and td.get_collision_polygons_count(0) > 0

	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	print("--- TOP TILES (key, count, solid) ---")
	for i in min(30, keys.size()):
		print("%s count=%d solid=%s" % [keys[i], counts[keys[i]], solid[keys[i]]])

	# Column profile: for each x in tiles, the y (tiles) of the topmost solid cell.
	print("--- COLUMN PROFILE (x_tile: x_px -> top solid y_tile, y_px) ---")
	var used := tm.get_used_cells()
	var max_x := 0
	for c in used:
		max_x = max(max_x, c.x)
	var profile := {}
	for c in used:
		var sid: int = tm.get_cell_source_id(c)
		var ac: Vector2i = tm.get_cell_atlas_coords(c)
		var key := "%d:%d,%d" % [sid, ac.x, ac.y]
		if solid.get(key, false):
			if not profile.has(c.x) or c.y < profile[c.x]:
				profile[c.x] = c.y
	var x := 0
	while x <= max_x:
		if profile.has(x):
			print("%d: %d -> %d" % [x, x * 16, profile[x] * 16])
		else:
			print("%d: %d -> NONE" % [x, x * 16])
		x += 4
	n.free()
	quit()
