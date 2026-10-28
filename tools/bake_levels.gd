extends SceneTree
func _initialize() -> void:
	call_deferred("bake")

func own(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		own(child, root)

func save_scene(root: Node, path: String) -> void:
	own(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		print("[BAKE] PACK FAILED ", err, " for ", path)
		quit(1)
		return
	err = ResourceSaver.save(packed, path)
	if err != OK:
		print("[BAKE] SAVE FAILED ", err, " for ", path)
		quit(1)
		return
	print("[BAKE] ", path)

func bake() -> void:
	print("[BAKE] start")
	var map1: Node2D = load("res://Scene/node_2d.tscn").instantiate()
	map1.tilemap = map1.get_node("TileMapLayer")
	map1._fill_walk_gaps()
	
	# Remove any previously baked duplicate actors in map1
	for child in map1.get_children():
		if child.name in ["Sandho", "RescueLetter", "Portal"]:
			child.queue_free()
	
	var player = map1.get_node("Char_Zhafran")
	player.set_script(load("res://scripts/player.gd"))
	player.position = Vector2(29, 182)
	
	var sandho = load("res://Scene/char_sandho.tscn").instantiate()
	sandho.name = "Sandho"
	sandho.position = Vector2(420, 182)
	map1.add_child(sandho)
	
	print("[BAKE] map1 scene built cleanly")
	save_scene(map1, "res://Scene/node_2d.tscn")
	map1.free()
	quit()
