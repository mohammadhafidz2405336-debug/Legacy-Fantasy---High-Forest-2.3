extends SceneTree
## Verifies authored physics/combat config. Run:
## godot --headless --path . --script res://tools/check_physics.gd

const CASES := {
	"res://Scene/char_zhafran.tscn": [2, 74.0],
	"res://Scene/char_sandho.tscn": [8, 74.0],
	"res://Scene/char_hafidz.tscn": [8, 74.0],
	"res://Scene/snail_mob.tscn": [4, 14.0],
	"res://Scene/mob_bee.tscn": [4, 11.0],
}
var failures := 0


func _initialize() -> void:
	for path in CASES:
		var body: CharacterBody2D = load(path).instantiate()
		var shape: CollisionShape2D = body.get_node("CollisionShape2D")
		var bottom: float = shape.position.y + (shape.shape as RectangleShape2D).size.y * 0.5
		_check(path, body.collision_layer == CASES[path][0], "layer=%d" % body.collision_layer)
		_check(path, body.collision_mask == 1, "mask=%d" % body.collision_mask)
		_check(path, is_equal_approx(bottom, CASES[path][1]), "bottom=%.1f" % bottom)
		if "sandho" in path:
			for method in ["can_interact", "get_prompt", "interact"]:
				_check(path, body.has_method(method), "missing " + method)
		if "snail" in path or "bee" in path:
			_check(path, body.get_node_or_null("HealthBar") is ProgressBar, "no authored HealthBar")
		if "zhafran" in path:
			var hitbox: Area2D = body.get_node_or_null("AttackHitbox")
			_check(path, hitbox != null and hitbox.collision_mask == 4 and not hitbox.monitoring, "bad AttackHitbox")
			_check(path, hitbox.position.y + (hitbox.get_node("CollisionShape2D").shape as RectangleShape2D).size.y * 0.5 >= 70.0, "hitbox not low enough for snail")
		if "hafidz" in path:
			_check(path, body.get_node_or_null("Camera2D") == null, "camera still authored")
		body.free()
	print("PHYSICS %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)


func _check(path: String, ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL %s: %s" % [path, detail])
