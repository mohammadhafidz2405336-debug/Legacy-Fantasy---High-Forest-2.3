extends SceneTree

# One-shot helper: writes the input map into project.godot using Godot's own
# serializer so the syntax is guaranteed correct. Safe to delete after running.

func _init() -> void:
	_define("move_left", [KEY_A, KEY_LEFT])
	_define("move_right", [KEY_D, KEY_RIGHT])
	_define("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_define("attack", [KEY_K])
	_define("interact", [KEY_E])
	_define("ui_advance_dialogue", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E])
	var err := ProjectSettings.save()
	print("input map written, save err=", err)
	quit()


func _define(action: String, keys: Array) -> void:
	var events: Array = []
	for k in keys:
		var ev := InputEventKey.new()
		ev.device = -1
		ev.physical_keycode = k
		events.append(ev)
	ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": events})
