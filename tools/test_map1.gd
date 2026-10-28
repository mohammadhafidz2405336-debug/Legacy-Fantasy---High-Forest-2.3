extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	print("[TEST] Loading res://scenes/map1.tscn...")
	var scn := load("res://scenes/map1.tscn")
	if scn == null:
		print("[TEST] ERROR: Failed to load scenes/map1.tscn")
		quit(1)
		return
	var inst = scn.instantiate()
	print("[TEST] Instantiated root name: ", inst.name, " script: ", inst.get_script())
	inst.free()
	print("[TEST] SUCCESS")
	quit(0)
