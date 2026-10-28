extends Area2D
##
## Coin pickup. Adds to the mission counter and shows an Indonesian
## notification. Attached to res://Scene/coin.tscn
##

const SFX := preload("res://brackeys_platformer_assets/sounds/coin.wav")

var _taken := false
var _base_y := 0.0


func _ready() -> void:
	add_to_group("coin")
	monitoring = true
	monitorable = false
	collision_layer = 1
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	_widen_collision()
	_base_y = position.y
	_start_bob()


func _widen_collision() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape_node.shape = circle
	shape_node.disabled = false


func _start_bob() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(self, "position:y", _base_y - 5.0, 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", _base_y, 0.9).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	set_deferred("monitoring", false)
	GameState.add_coin()

	var total := ""
	if GameState.mission_active:
		total = " (%d/%d)" % [GameState.coins, GameState.coins_required]
	Hud.toast(Story.TOAST_COIN + total, 1.2)

	var sfx := AudioStreamPlayer.new()
	sfx.stream = SFX
	sfx.volume_db = -8.0
	get_tree().root.add_child(sfx)
	sfx.finished.connect(sfx.queue_free)
	sfx.play()

	if GameState.mission_active and GameState.coins_done():
		Hud.toast(Story.TOAST_COINS_DONE, 2.4)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 26.0, 0.35)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.35)
	tween.chain().tween_callback(queue_free)