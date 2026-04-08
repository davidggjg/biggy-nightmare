extends CharacterBody3D
# ═══════════════════════════════════════════════
#  PLAYER.GD  —  BIGGY NIGHTMARE FPS
#  Inspired by RE9 Requiem: Grace Ashcroft mode
#  • First-person camera with head bob
#  • Red vignette damage feedback
#  • Shaking hands when low health / scared
#  • Stamina system (sprint drains, recovers)
#  • Breathing audio speeds up near Biggy
# ═══════════════════════════════════════════════

# ── Movement constants (tuned for horror pacing) ──
const WALK_SPEED    := 3.8   # slow = tense atmosphere
const SPRINT_SPEED  := 6.5
const CROUCH_SPEED  := 1.8
const GRAVITY       := -22.0
const JUMP_FORCE    := 6.0   # kept but rarely used in horror
const MOUSE_SENS    := 0.002

# ── Health & Stamina ──
const MAX_HEALTH    := 100.0
const MAX_STAMINA   := 100.0
const STAMINA_DRAIN := 28.0  # per second while sprinting
const STAMINA_REGEN := 14.0

# ── Head bob (RE9 style — stronger when scared) ──
const BOB_FREQ_WALK   := 1.8
const BOB_FREQ_SPRINT := 3.0
const BOB_AMP_WALK    := 0.04
const BOB_AMP_SPRINT  := 0.08

@onready var camera          : Camera3D       = $Camera3D
@onready var flashlight      : SpotLight3D    = $Camera3D/SpotLight3D
@onready var hand_mesh       : MeshInstance3D = $Camera3D/HandMesh  # shaking hands
@onready var flicker_timer   : Timer          = $FlickerTimer
@onready var footstep_player : AudioStreamPlayer3D = $FootstepPlayer
@onready var breath_player   : AudioStreamPlayer3D = $BreathPlayer
@onready var heartbeat_player: AudioStreamPlayer3D = $HeartbeatPlayer

# Signals to GameManager
signal player_caught
signal key_collected(total: int)
signal health_changed(new_hp: float)
signal stamina_changed(new_st: float)

var health  : float = MAX_HEALTH
var stamina : float = MAX_STAMINA
var is_caught   := false
var is_crouching := false
var keys_collected := 0

var _cam_pitch     := 0.0
var _bob_timer     := 0.0
var _bob_origin    := Vector3.ZERO
var _step_timer    := 0.0
var _flicker_on    := true
var _danger_level  := 0.0   # 0..1, set by GameManager

# RE9: hand shake increases with low health + nearby enemy
var _shake_amount   := 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_bob_origin = camera.position
	flicker_timer.timeout.connect(_on_flicker_timeout)

func _input(event: InputEvent) -> void:
	if is_caught:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		_cam_pitch = clamp(_cam_pitch - event.relative.y * MOUSE_SENS, -1.4, 1.4)
		camera.rotation.x = _cam_pitch

func _physics_process(delta: float) -> void:
	if is_caught:
		return

	# ── Gravity ──
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# ── Crouch ──
	is_crouching = Input.is_action_pressed("crouch")

	# ── Sprint ──
	var sprinting := Input.is_action_pressed("sprint") and stamina > 0 and not is_crouching
	var speed := SPRINT_SPEED if sprinting else (CROUCH_SPEED if is_crouching else WALK_SPEED)

	# Stamina drain / regen
	if sprinting and (Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward")):
		stamina = max(0.0, stamina - STAMINA_DRAIN * delta)
	else:
		stamina = min(MAX_STAMINA, stamina + STAMINA_REGEN * delta)
	emit_signal("stamina_changed", stamina)

	# ── Movement direction ──
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		dir -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		dir += transform.basis.x
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()

	# ── Head bob ──
	_update_head_bob(delta, dir.length() > 0.1, sprinting)

	# ── Footstep sounds ──
	_update_footsteps(delta, dir.length() > 0.1, sprinting)

	# ── RE9: hand shake ──
	_update_hand_shake(delta)

	# ── Flashlight toggle ──
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = not flashlight.visible

# ── Head bob — RE9 comfort mode style ──
func _update_head_bob(delta: float, moving: bool, sprinting: bool) -> void:
	if moving and is_on_floor():
		var freq := BOB_FREQ_SPRINT if sprinting else BOB_FREQ_WALK
		var amp  := BOB_AMP_SPRINT  if sprinting else BOB_AMP_WALK
		# Extra bob when scared (RE9 Grace stumble effect)
		amp += _danger_level * 0.03
		_bob_timer += delta * freq * TAU
		camera.position = _bob_origin + Vector3(
			sin(_bob_timer) * amp * 0.5,
			abs(sin(_bob_timer)) * amp,
			0.0
		)
	else:
		_bob_timer = 0.0
		camera.position = camera.position.lerp(_bob_origin, delta * 8.0)

# ── Footsteps ──
func _update_footsteps(delta: float, moving: bool, sprinting: bool) -> void:
	if not moving or not is_on_floor():
		_step_timer = 0.0
		return
	_step_timer += delta
	var interval := 0.32 if sprinting else 0.52
	if _step_timer >= interval:
		_step_timer = 0.0
		footstep_player.play()

# ── RE9: shaking hands when scared / low health ──
func _update_hand_shake(delta: float) -> void:
	var health_fear := 1.0 - (health / MAX_HEALTH)
	_shake_amount = lerp(_shake_amount, _danger_level * 0.6 + health_fear * 0.4, delta * 3.0)
	if hand_mesh:
		hand_mesh.position = Vector3(
			0.25 + randf_range(-1, 1) * _shake_amount * 0.012,
			-0.22 + randf_range(-1, 1) * _shake_amount * 0.008,
			-0.45
		)

# ── Called by GameManager ──
func set_danger_level(level: float) -> void:
	_danger_level = level
	# Speed up breathing
	if breath_player:
		breath_player.pitch_scale = 1.0 + level * 0.8
	# Flashlight flickers when very close to Biggy
	if level > 0.75 and not flicker_timer.is_stopped():
		pass
	elif level > 0.75:
		flicker_timer.wait_time = randf_range(0.05, 0.25)
		flicker_timer.start()
	else:
		flicker_timer.stop()
		flashlight.visible = true

func _on_flicker_timeout() -> void:
	flashlight.visible = not flashlight.visible
	flicker_timer.wait_time = randf_range(0.04, 0.3)
	flicker_timer.start()

func take_damage(amount: float) -> void:
	if is_caught:
		return
	health = max(0.0, health - amount)
	emit_signal("health_changed", health)
	if health <= 0.0:
		get_caught()

func get_caught() -> void:
	if is_caught:
		return
	is_caught = true
	emit_signal("player_caught")

func collect_key() -> void:
	keys_collected += 1
	emit_signal("key_collected", keys_collected)
