extends SceneTree

func _init() -> void:
	var ps: PackedScene = load("res://Scene/node_2d.tscn")
	var n: Node = ps.instantiate()
	var tm: TileMapLayer = n.get_node("TileMapLayer")
	var ts: TileSet = tm.tile_set
	for sid in [22, 45, 46, 21, 23, 30, 44]:
		var src := ts.get_source(sid) as TileSetAtlasSource
		if src == null:
			continue
		print("SOURCE %d -> %s  region=%s" % [sid, src.texture.resource_path, src.texture_region_size])
	n.free()
	quit()
