extends SceneTree
func _initialize() -> void:
	call_deferred("probe")

func probe() -> void:
	print("[P] load scene")
	var map1: Node2D = load("res://Scene/node_2d.tscn").instantiate()
	print("[P] instantiated")
	map1.tilemap = map1.get_node("TileMapLayer")
	print("[P] used cells: ", map1.tilemap.get_used_cells().size())
	var t := Time.get_ticks_msec()
	map1._fill_walk_gaps()
	print("[P] flatten ms=", Time.get_ticks_msec() - t)
	quit()