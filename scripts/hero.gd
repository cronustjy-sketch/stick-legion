class_name Hero
extends CharacterBody3D
## The player's stickman hero: WASD move, Shift sprint, Space dodge roll (brief invincibility),
## left click 3-hit combo, right click block. Movement is relative to the camera heading.

signal hp_changed(current: float, maximum: float)
signal lives_changed(lives: int)
signal died
signal out_of_lives
signal struck(hit_count: int, combo_index: int)

enum State { FREE, ATTACK, ROLL, BLOCK, DEAD }

var terrain: Terrain
var camera: HeroCamera
var spawn_position: Vector3 = Vector3.ZERO

var max_hp: float = float(HeroData.STATS.max_hp)
var hp: float = max_hp
var lives: int = int(HeroData.STATS.lives)
var state: State = State.FREE
var invincible: bool = false
var model: Stickman

var _face_yaw: float = 0.0
var _combo: int = 0
var _combo_timer: float = 0.0
var _attack_t: float = 0.0
var _struck: bool = false
var _queued: bool = false
var _roll_t: float = 0.0
var _roll_cd: float = 0.0
var _roll_dir: Vector3 = Vector3.FORWARD
var _stun: float = 0.0
var mouse_gate: bool = true  # ignore attack/block unless the mouse is captured (so HUD clicks do not swing the sword)
var _dead_t: float = 0.0


func _ready() -> void:
	add_to_group("hero")
	collision_layer = 4
	collision_mask = 2  # fortress bodies
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var cs: CollisionShape3D = CollisionShape3D.new()
	var cap: CapsuleShape3D = CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.9
	cs.shape = cap
	cs.position.y = 0.95
	add_child(cs)
	model = Stickman.new()
	model.name = "Model"
	model.setup("hero", 0)
	add_child(model)
	spawn_position = global_position


func forward_vector() -> Vector3:
	return Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))


func _physics_process(delta: float) -> void:
	_roll_cd -= delta
	_stun -= delta
	if state == State.DEAD:
		_dead_t += delta
		if _dead_t >= float(HeroData.STATS.respawn_time) and lives > 0:
			_respawn()
		return
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_yaw: float = camera.yaw if camera != null else 0.0
	var move_dir: Vector3 = Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, cam_yaw)
	var attack_pressed: bool = Input.is_action_just_pressed("attack")
	if attack_pressed and camera != null and camera.swallow_click:
		camera.swallow_click = false
		attack_pressed = false
	var dodge_pressed: bool = Input.is_action_just_pressed("dodge")
	var block_held: bool = Input.is_action_pressed("block")
	if mouse_gate and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		attack_pressed = false
		block_held = false
	if camera != null and camera.tactical:  # the hero stands still while you look at the battlefield
		move_dir = Vector3.ZERO
		attack_pressed = false
		dodge_pressed = false
		block_held = false
	invincible = false
	match state:
		State.FREE:
			_combo_timer -= delta
			if _combo_timer <= 0.0:
				_combo = 0
			_state_free(delta, move_dir, attack_pressed, dodge_pressed, block_held)
		State.BLOCK:
			_state_block(delta, move_dir, cam_yaw, attack_pressed, dodge_pressed, block_held)
		State.ATTACK:
			_state_attack(delta, move_dir, attack_pressed, dodge_pressed)
		State.ROLL:
			_state_roll(delta)
	move_and_slide()
	_snap_to_ground()


# --- States -------------------------------------------------------------------------------------------

func _state_free(delta: float, move_dir: Vector3, attack: bool, dodge: bool, block: bool) -> void:
	if _stun > 0.0:
		velocity = Vector3.ZERO
		return
	if dodge and _roll_cd <= 0.0:
		_start_roll(move_dir)
		return
	if attack:
		_start_attack()
		return
	if block:
		state = State.BLOCK
		return
	var moving: bool = move_dir.length() > 0.1
	var sprint: bool = Input.is_action_pressed("sprint") and moving
	var speed: float = float(HeroData.STATS.sprint_speed) if sprint else float(HeroData.STATS.walk_speed)
	if moving:
		velocity = move_dir.normalized() * speed
		_turn_towards(atan2(-move_dir.x, -move_dir.z), delta)
		if sprint:
			model.play("run", speed / 8.0)
		else:
			model.play("walk", speed / 4.5)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, 40.0 * delta)
		model.play("idle")


func _state_block(delta: float, move_dir: Vector3, cam_yaw: float, attack: bool, dodge: bool, block: bool) -> void:
	if dodge and _roll_cd <= 0.0:
		_start_roll(move_dir)
		return
	if attack:
		_start_attack()
		return
	if not block:
		state = State.FREE
		return
	velocity = move_dir.normalized() * float(HeroData.STATS.block_speed) if move_dir.length() > 0.1 else Vector3.ZERO
	_turn_towards(cam_yaw, delta)  # face where the camera looks while guarding
	model.play("block")


func _start_attack() -> void:
	state = State.ATTACK
	_attack_t = 0.0
	_struck = false
	_queued = false
	var swing: Dictionary = HeroData.COMBO[_combo]
	_assist_aim()
	model.play(StringName(swing.anim), float(HeroData.STATS.attack_speed), true)


func _state_attack(delta: float, move_dir: Vector3, attack: bool, dodge: bool) -> void:
	var swing: Dictionary = HeroData.COMBO[_combo]
	var spd: float = float(HeroData.STATS.attack_speed)
	_attack_t += delta * spd
	var strike_t: float = float(swing.strike)
	var length: float = float(swing.length)
	# Lunge forward into the swing, then settle.
	if _attack_t < strike_t and _nearest_enemy_dist() > 1.4:
		velocity = forward_vector() * float(swing.lunge) * (1.0 - _attack_t / strike_t * 0.5)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, 30.0 * delta)
	if not _struck and _attack_t >= strike_t:
		_struck = true
		_strike(float(swing.damage))
	if attack and _attack_t > 0.05:  # buffered click: counts as soon as the swing has started
		_queued = true
	if dodge and _struck and _roll_cd <= 0.0:
		_start_roll(move_dir)
		return
	if _attack_t >= length * 0.88:
		if _queued and _combo < HeroData.COMBO.size() - 1:
			_combo += 1
			_start_attack()
		else:
			# A fresh press within combo_reset continues the chain; after the last swing it starts over.
			_combo = 0 if _combo >= HeroData.COMBO.size() - 1 else _combo + 1
			_combo_timer = float(HeroData.STATS.combo_reset)
			state = State.FREE


func _start_roll(move_dir: Vector3) -> void:
	state = State.ROLL
	_roll_t = 0.0
	_roll_dir = move_dir.normalized() if move_dir.length() > 0.1 else forward_vector()
	_face_yaw = atan2(-_roll_dir.x, -_roll_dir.z)
	rotation.y = _face_yaw
	_combo = 0
	model.play("roll", 0.6 / float(HeroData.STATS.roll_time), true)


func _state_roll(delta: float) -> void:
	_roll_t += delta
	invincible = _roll_t < float(HeroData.STATS.roll_iframes)
	velocity = _roll_dir * float(HeroData.STATS.roll_speed) * (1.0 - _roll_t / float(HeroData.STATS.roll_time) * 0.35)
	if _roll_t >= float(HeroData.STATS.roll_time):
		_roll_cd = float(HeroData.STATS.roll_cooldown)
		state = State.FREE


# --- Combat -------------------------------------------------------------------------------------------

func _strike(damage: float) -> void:
	var fwd: Vector3 = forward_vector()
	var arc_cos: float = cos(deg_to_rad(float(HeroData.STATS.attack_arc_deg) * 0.5))
	var reach: float = float(HeroData.STATS.attack_range)
	var hits: int = 0
	for n: Node in get_tree().get_nodes_in_group("hittable_enemy"):
		if not n.call("is_alive"):
			continue
		var p: Vector3 = n.call("nearest_point", global_position)
		var to: Vector3 = p - global_position
		to.y = 0.0
		var dist: float = to.length() - float(n.get("hit_radius"))
		if dist > reach:
			continue
		if to.length() > 0.6 and fwd.dot(to.normalized()) < arc_cos:
			continue
		n.call("take_damage", damage, global_position)
		hits += 1
	struck.emit(hits, _combo)


## Called by enemies. Returns true if the hit landed (false when dodged).
func take_damage(amount: float, from_pos: Vector3) -> bool:
	if state == State.DEAD or invincible:
		return false
	var dealt: float = amount
	if state == State.BLOCK:
		var to: Vector3 = from_pos - global_position
		to.y = 0.0
		var arc_cos: float = cos(deg_to_rad(float(HeroData.STATS.block_arc_deg) * 0.5))
		if to.length() < 0.05 or forward_vector().dot(to.normalized()) >= arc_cos:
			dealt *= 1.0 - float(HeroData.STATS.block_reduction)
	hp = maxf(hp - dealt, 0.0)
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		_die()
	elif state != State.BLOCK and state != State.ROLL:
		_stun = float(HeroData.STATS.hurt_stun)
		state = State.FREE
		model.play("hit", 1.0, true)
	return true


func _die() -> void:
	state = State.DEAD
	_dead_t = 0.0
	velocity = Vector3.ZERO
	lives -= 1
	lives_changed.emit(lives)
	model.play("die", 1.0, true)
	died.emit()
	if lives <= 0:
		out_of_lives.emit()


func _respawn() -> void:
	global_position = spawn_position
	hp = max_hp
	state = State.FREE
	model.play("idle", 1.0, true)
	hp_changed.emit(hp, max_hp)


# --- Helpers ------------------------------------------------------------------------------------------

func _turn_towards(target_yaw: float, delta: float) -> void:
	_face_yaw = target_yaw
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(float(HeroData.STATS.turn_speed) * delta, 0.0, 1.0))


func _snap_to_ground() -> void:
	var p: Vector3 = global_position
	p.x = clampf(p.x, -(BattlefieldData.VALLEY_HALF_WIDTH + 6.0), BattlefieldData.VALLEY_HALF_WIDTH + 6.0)
	p.z = clampf(p.z, -(BattlefieldData.FORTRESS_Z + 14.0), BattlefieldData.FORTRESS_Z + 14.0)
	if terrain != null:
		p.y = terrain.height_at(p.x, p.z)
	global_position = p


## Distance on the ground to the closest living enemy (edge to edge), ignoring facing.
func _nearest_enemy_dist() -> float:
	var best: float = INF
	for n: Node in get_tree().get_nodes_in_group("hittable_enemy"):
		if not n.call("is_alive"):
			continue
		var p: Vector3 = n.call("nearest_point", global_position)
		var to: Vector3 = p - global_position
		to.y = 0.0
		best = minf(best, to.length() - float(n.get("hit_radius")))
	return best


## Light aim assist: swings turn towards the closest enemy in front of the hero.
func _assist_aim() -> void:
	var fwd: Vector3 = forward_vector()
	var best: float = 4.5
	var best_dir: Vector3 = Vector3.ZERO
	for n: Node in get_tree().get_nodes_in_group("hittable_enemy"):
		if not n.call("is_alive") or n is Fortress:
			continue
		var to: Vector3 = (n.call("nearest_point", global_position) as Vector3) - global_position
		to.y = 0.0
		var d: float = to.length()
		if d < best and d > 0.05 and fwd.dot(to / d) > cos(deg_to_rad(80.0)):
			best = d
			best_dir = to / d
	if best_dir != Vector3.ZERO:
		rotation.y = atan2(-best_dir.x, -best_dir.z)


# --- "hittable" interface shared with Unit and Fortress (used by enemy AI) ---------------------------------

var hit_radius: float = 0.45


func is_alive() -> bool:
	return state != State.DEAD


func nearest_point(_from: Vector3) -> Vector3:
	return global_position


## Seconds until the hero is back on the field (0 when alive).
func respawn_remaining() -> float:
	if state != State.DEAD:
		return 0.0
	return maxf(float(HeroData.STATS.respawn_time) - _dead_t, 0.0)
