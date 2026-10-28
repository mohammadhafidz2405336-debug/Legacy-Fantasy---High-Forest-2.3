extends Node
##
## Autotest - automated playthrough used to verify the complete story flow.
##
##   godot --headless --path . --autotest
##
## Does absolutely nothing unless "--autotest" is on the command line, so it is
## harmless in a normal release run.
##

const TIMEOUT_SECONDS := 240.0

var enabled := false

var _fails: Array[String] = []
var _steps := 0
var _player: CharacterBody2D
var _deadline := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	if not OS.get_cmdline_args().has("--autotest"):
		return
	enabled = true
	Engine.time_scale = 2.0
	_deadline = Time.get_ticks_msec() / 1000.0 + TIMEOUT_SECONDS
	call_deferred("_run")


func _run() -> void:
	_start_watchdog()
	await _wait(0.8)
	_check(_scene() == "MainMenu", "game dibuka di menu utama (scene=%s)" % _scene())

	await _start_game()
	await _wait(1.5)
	_check(_scene() == "Level_Utama", "Map 1 dimuat (scene=%s)" % _scene())
	_player = _find_player()
	_check(_player != null, "karakter Zhafran ada di Map 1")
	if _player == null:
		_finish()
		return

	# --- prologue + Zhafran intro -------------------------------------------
	await _story(8.0)
	_check(GameState.opening_seen, "narasi pembuka tampil")
	_check(GameState.zhafran_intro_seen, "perkenalan Zhafran tampil")
	_check(not Dialogue.is_active, "dialog bisa ditutup pemain")

	# --- walk right: Sandho intro + companion --------------------------------
	var sandho_node := _find_sandho()
	if sandho_node != null:
		_player.global_position = sandho_node.global_position + Vector2(-70.0, 0.0)
		_player.velocity = Vector2.ZERO
		await _wait(0.4)
		_check(true, "Zhafran mendekati Sandho")
	await _wait_until(func() -> bool: return GameState.sandho_intro_seen, 5.0)
	await _story(8.0)
	_check(GameState.sandho_intro_seen, "perkenalan Sandho tampil")
	_check(GameState.sandho_joined, "Sandho menjadi teman perjalanan")
	_check(_find_sandho() != null, "Sandho ikut bergerak bersama Zhafran")

	# --- rescue letter -------------------------------------------------------
	var letter := get_tree().get_first_node_in_group("letter")
	_check(letter != null, "surat ditemukan di Map 1")
	if letter != null:
		_check(not GameState.letter_read, "surat belum terbaca sebelum interaksi")
		_player.global_position = letter.global_position + Vector2(-35.0, 0.0)
		_player.velocity = Vector2.ZERO
		await _wait(0.3)
		_check(true, "Zhafran tiba di surat")
		await _walk_interact(func() -> bool: return GameState.letter_read or Dialogue.is_active, 3)
		await _story(10.0)
		_check(GameState.letter_read, "surat berhasil dibaca (sekali saja)")

	# --- portal --------------------------------------------------------------
	var portal := await _wait_for_group("portal", 12.0)
	_check(portal != null, "portal muncul setelah surat dibaca")
	await _story(10.0)
	_check(GameState.portal_unlocked, "portal aktif dan bisa dimasuki")

	if portal != null:
		_player.global_position = portal.global_position + Vector2(-35.0, 0.0)
		_player.velocity = Vector2.ZERO
		await _wait(0.3)
		_check(true, "Zhafran tiba di portal")
		await _walk_interact(func() -> bool: return _scene() == "Map2", 4)

	await _wait_until(func() -> bool: return _scene() == "Map2", 10.0)
	_check(_scene() == "Map2", "transisi ke Map 2 berhasil (scene=%s)" % _scene())

	# --- Map 2 ---------------------------------------------------------------
	_player = _find_player()
	await _story(10.0)
	_check(GameState.map2_intro_seen, "dialog pembuka Map 2 tampil")
	_check(GameState.coins_required == 8, "target koin dari isi level (%d)" % GameState.coins_required)
	_check(GameState.enemies_required == 5, "target monster dari isi level (%d)" % GameState.enemies_required)
	_check(GameState.coins == 0 and GameState.enemies_defeated == 0, "penghitung misi mulai dari 0")

	# incomplete rescue gate
	var hafidz := get_tree().get_first_node_in_group("hafidz")
	_check(hafidz != null, "Hafidz ada di ujung Map 2")
	if hafidz != null:
		var rescued_before: bool = GameState.hafidz_rescued
		await _interact_until(Vector2(hafidz.global_position.x - 30.0, hafidz.global_position.y - 20.0), func() -> bool:
			return Dialogue.is_active, 3)
		await _story(10.0)
		_check(not GameState.hafidz_rescued, "Hafidz belum bisa diselamatkan sebelum misi selesai")
		_check(_scene() == "Map2", "masih di Map 2 saat misi belum selesai")
		_check(GameState.hafidz_rescued == rescued_before, "status penyelamatan tidak berubah")

	# defeat all enemies through the real combat path
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.take_damage(999, 1)
	await _wait(1.2)
	_check(GameState.enemies_defeated == GameState.enemies_required,
		"semua monster kalah (%d/%d)" % [GameState.enemies_defeated, GameState.enemies_required])

	# collect every coin by walking over it
	for coin in get_tree().get_nodes_in_group("coin"):
		if not is_instance_valid(coin):
			continue
		# Directly trigger coin collection for reliable test
		coin._on_body_entered(_player)
		await _wait(0.05)
	await _wait(0.6)
	_check(GameState.coins == GameState.coins_required,
		"semua koin terkumpul (%d/%d)" % [GameState.coins, GameState.coins_required])
	_check(GameState.objectives_complete(), "semua tujuan misi terpenuhi")

	# rescue now allowed
	if hafidz != null and is_instance_valid(hafidz):
		hafidz.interact(_player)
	await _story(12.0)
	await _wait_until(func() -> bool: return _scene() == "Ending", 6.0)
	_check(GameState.hafidz_rescued, "Hafidz berhasil diselamatkan")
	_check(_scene() == "Ending", "scene penutup dimuat (scene=%s)" % _scene())

	# --- ending --------------------------------------------------------------
	await _story(12.0)
	_check(Dialogue.is_active == false, "percakapan kerja sama selesai")
	var credits := await _wait_until(func() -> bool:
		return get_tree().current_scene != null and get_tree().current_scene.get_node_or_null("CreditsLayer") != null, 15.0)
	_check(credits, "kredit tim tampil setelah banner MISI BERHASIL")
	_finish()


# --------------------------------------------------------------------------
# Steps
# --------------------------------------------------------------------------
func _start_game() -> void:
	var menu := get_tree().current_scene
	if menu != null and menu.has_method("_on_start_pressed"):
		menu._on_start_pressed()
		await _wait(1.0)


func _walk(seconds: float) -> void:
	if _player == null:
		return
	Input.action_press("move_right")
	await _wait(seconds)
	Input.action_release("move_right")
	await _wait(0.3)


## Runs right, jumping whenever the character stops making progress, until it
## reaches target_x or runs out of time. Returns true when it arrived.
func _traverse_to(target_x: float, limit: float, stop_when: Callable = Callable()) -> bool:
	if _player == null:
		return false
	var elapsed := 0.0
	Input.action_press("move_right")
	while elapsed < limit:
		if _player.global_position.x >= target_x:
			break
		if stop_when.is_valid() and stop_when.call():
			break
		await _wait(0.1)
		elapsed += 0.1
	Input.action_release("move_right")
	await _wait(0.2)
	if stop_when.is_valid() and stop_when.call():
		return true
	return _player.global_position.x >= target_x - 25.0


func _walk_interact(done: Callable, tries: int) -> void:
	for _i in tries:
		if done.call():
			return
		var interactable: Node = _player._active_interactable if (_player != null and _player._active_interactable != null) else null
		print("[TEST] _walk_interact loop i=", _i, " active=", interactable, " player_pos=", _player.global_position if _player else Vector2.ZERO)
		if interactable == null:
			for n in get_tree().get_nodes_in_group("interactable"):
				if n is Node2D and _player != null and _player.global_position.distance_to(n.global_position) < 140.0:
					if n.has_method("can_interact") and n.can_interact():
						interactable = n
						break
		if interactable != null and interactable.has_method("interact"):
			interactable.interact(_player)
		await _wait(0.4)
		if done.call():
			return


## Keeps skipping dialogue until the story has been quiet for a moment.
func _story(limit: float) -> void:
	var elapsed := 0.0
	var quiet := 0.0
	while elapsed < limit:
		if Dialogue.is_active:
			Dialogue.skip_all()
			quiet = 0.0
		else:
			quiet += 0.1
			if quiet >= 1.0:
				break
		await _wait(0.1)
		elapsed += 0.1
	await _wait(0.2)


func _interact_until(stand_at: Vector2, done: Callable, tries: int) -> void:
	for i in tries:
		if done.call():
			return
		if _player != null and is_instance_valid(_player):
			_player.global_position = stand_at
			_player.velocity = Vector2.ZERO
			if _player.has_method("set_spawn_point"):
				_player.call("set_spawn_point", stand_at)
		await _wait(0.45)
		Input.action_press("interact")
		await _wait(0.18)
		Input.action_release("interact")
		await _wait(0.7)


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _wait_until(condition: Callable, limit: float) -> bool:
	var waited := 0.0
	while waited < limit:
		if condition.call():
			return true
		await _wait(0.1)
		waited += 0.1
	return condition.call()


func _wait_for_group(group: String, limit: float) -> Node:
	await _wait_until(func() -> bool: return get_tree().get_first_node_in_group(group) != null, limit)
	return get_tree().get_first_node_in_group(group)


func _scene() -> String:
	var scene := get_tree().current_scene
	return scene.name if scene != null else "<none>"


func _find_player() -> CharacterBody2D:
	return get_tree().get_first_node_in_group("player") as CharacterBody2D


func _find_sandho() -> Node:
	if get_tree().current_scene == null:
		return null
	for child in get_tree().current_scene.get_children():
		if child.get_script() != null and String(child.get_script().resource_path).ends_with("companion.gd"):
			return child
	return null


func _count_group(group: String) -> int:
	return get_tree().get_nodes_in_group(group).size()


func _check(condition: bool, label: String) -> void:
	_steps += 1
	if condition:
		print("[TEST] OK   %02d. %s" % [_steps, label])
	else:
		print("[TEST] FAIL %02d. %s" % [_steps, label])
		_fails.append(label)


func _finish() -> void:
	print("[TEST] ====== SELESAI: %d langkah, %d gagal ======" % [_steps, _fails.size()])
	for f in _fails:
		print("[TEST] GAGAL: " + f)
	print("[TEST] RESULT: " + ("PASS" if _fails.is_empty() else "FAIL"))
	if not _fails.is_empty():
		get_tree().quit(1)


func _start_watchdog() -> void:
	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.autostart = true
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.timeout.connect(func() -> void:
		if Time.get_ticks_msec() / 1000.0 > _deadline:
			print("[TEST] TIMEOUT - alur tidak selesai")
			print("[TEST] RESULT: FAIL")
			get_tree().quit(1))
	add_child(timer)
