extends Node
## Runtime check of movement/combat. Run:
## godot --headless --path . --script res://tools/physics_smoke.gd

const FLOOR_Y := 400.0
var failures := 0
var _player: Node
var _sandho: Node
var _snail: Node
var _hafidz: Node
var _last_sandho := Vector2.ZERO
var _max_step := 0.0


func _ready() -> void:
	_floor_slab(-650.0, 1140.0)
	_floor_slab(700.0, 1440.0)

	_player = load("res://Scene/char_zhafran.tscn").instantiate()
	_player.position = Vector2(100, FLOOR_Y - 74)
	_player.set("controls_enabled", false)
	add_child(_player)

	_sandho = load("res://Scene/char_sandho.tscn").instantiate()
	_sandho.position = Vector2(-200, FLOOR_Y - 74)
	add_child(_sandho)
	_last_sandho = (_sandho as Node2D).global_position

	_snale_setup()



	_hafidz = load("res://Scene/char_hafidz.tscn").instantiate()
	_hafidz.position = Vector2(300, FLOOR_Y - 74)
	add_child(_hafidz)

	_sandho.call("start_following")
	await get_tree().create_timer(0.6).timeout
	_sandho_catchup()
	await get_tree().create_timer(1.2).timeout
	_sandho_report()
	_attack_test()
	await get_tree().create_timer(0.8).timeout
	_hafidz_report()
	print("SMOKE %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func _floor_slab(center_x: float, width: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 40)
	col.shape = rect
	col.position = Vector2(center_x, FLOOR_Y + 20)
	body.add_child(col)
	add_child(body)


func _snale_setup() -> void:
	_snail = load("res://Scene/snail_mob.tscn").instantiate()
	(_snail as Node2D).global_position = Vector2(62, FLOOR_Y - 14)
	_snail.set("patrol_radius", 60.0)
	add_child(_snail)


func _sandho_catchup() -> void:
	pass


func _sandho_report() -> void:
	_check((_sandho as CharacterBody2D).is_on_floor(), "companion not grounded")
	_check(absf((_sandho as Node2D).global_position.x - ((_player as Node2D).global_position.x - int(_player.get("facing")) * 52.0)) < 70.0, "companion did not follow: %.0f" % (_sandho as Node2D).global_position.x)
	_check((_sandho as Node2D).global_position.y < FLOOR_Y, "companion sank through floor")
	_check(_max_step < 120.0, "companion teleported (%.0f px)" % _max_step)
	var api := _sandho.has_method("can_interact") and _sandho.has_method("get_prompt") and _sandho.has_method("interact")
	_check(api, "companion missing interaction API")
	GameState.sandho_intro_seen = true
	_check(not bool(_sandho.call("can_interact")), "companion interactable after intro")
	GameState.sandho_intro_seen = false
	_check(bool(_sandho.call("can_interact")), "companion not interactable before intro")


func _attack_test() -> void:
	(_snail as Node2D).global_position.x = (_player as Node2D).global_position.x + 35.0
	_snail.set("speed", 0.0)
	await get_tree().physics_frame
	var before: int = int(_snail.get("health"))
	_player.call("_attack")
	await get_tree().create_timer(0.3).timeout
	_check(before - int(_snail.get("health")) == 25, "one swing dealt %d damage" % (before - int(_snail.get("health"))))


func _hafidz_report() -> void:
	_check((_hafidz as CharacterBody2D).is_on_floor(), "Hafidz not grounded")
	_check(absf((_hafidz as Node2D).global_position.y - (FLOOR_Y - 74)) < 4.0, "Hafidz y drift %.1f" % (_hafidz as Node2D).global_position.y)
	_check(absf((_hafidz as Node2D).global_position.x - 300.0) < 1.0, "Hafidz drifted")
	_check(absf((_snail as Node2D).global_position.x - 62.0) <= 100.0, "snail left patrol bounds: %.0f" % (_snail as Node2D).global_position.x)
	var bar := (_snail as Node).get_node_or_null("HealthBar") as ProgressBar
	_check(bar != null and bar.value == int(_snail.get("health")), "enemy health bar out of sync")


func _physics_process(_delta: float) -> void:
	if _sandho == null:
		return
	_max_step = maxf(_max_step, (_sandho as Node2D).global_position.distance_to(_last_sandho))
	_last_sandho = (_sandho as Node2D).global_position


func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: " + detail)
