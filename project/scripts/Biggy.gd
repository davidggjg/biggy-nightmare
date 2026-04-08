extends CharacterBody3D
# ═══════════════════════════════════════════════
#  BIGGY.GD  —  The Ethiopian Nightmare
#  Inspired by RE9 "The Girl" stalker enemy:
#  • Always knows approximately where you are
#  • Gets FASTER the longer he chases
#  • Yells in Russian while chasing
#  • Has RAGE MODE (like RE9 elite variants)
#  • Footsteps audible before you see him
# ═══════════════════════════════════════════════

const PATROL_SPEED  := 2.2
const CHASE_SPEED   := 4.8
const RAGE_SPEED    := 7.5   # RE9: escalating threat
const CATCH_DIST    := 1.6
const HEAR_DIST     := 9.0
const SEE_DIST      := 16.0
const GRAVITY       := -22.0

@onready var nav_agent   : NavigationAgent3D       = $NavigationAgent3D
@onready var speech_node : Label3D                 = $SpeechBubble/Label3D
@onready var speech_root : Node3D                  = $SpeechBubble
@onready var speech_timer: Timer                   = $SpeechTimer
@onready var footstep_audio : AudioStreamPlayer3D  = $FootstepAudio
@onready var growl_audio    : AudioStreamPlayer3D  = $GrowlAudio

var player     : CharacterBody3D = null
var is_chasing := false
var is_raging  := false
var rage_timer := 0.0
var speech_cooldown := 0.0
var chase_duration  := 0.0   # gets faster the longer chase goes
var last_known_pos  := Vector3.ZERO
var step_timer      := 0.0

# ── Russian phrases ──
const IDLE_PHRASES := [
	"ищу тебя, бро... 👀",
	"BIGGY ON THE WAY",
	"я чую тебя...",
	"где ты??? 🤔",
]
const CHASE_PHRASES := [
	"СТОЯТЬ!!! BIGGY ИДЁТ!!!",
	"ТЫ НЕ УБЕЖИШЬ!!!",
	"AHAHAHA ПОЙМАЮ!!!",
	"ДАВАЙ ДАВАЙ ДАВАЙ!!!",
	"ЭТО BIGGY!!! ЭТО Я!!!",
	"РОНЕН GG!!! GG!!!",
	"ТЫ МОЙ ТЕПЕРЬ!!!",
	"ФИНИТА, ДРУГ!!!",
]
const RAGE_PHRASES := [
	"🔥 RAGE MODE 🔥",
	"BIGGY ЗЛОЙ СЕЙЧАС!!!",
	"ХВАТИТ УБЕГАТЬ!!!",
	"ТЫ УСТАЛ? Я НЕТ!!!",
]
const CLOSE_PHRASES := [
	"АА НАШЁЛ!!!",
	"ВИЖУ ТЕБЯ!!!",
	"GG РОНЕН!!!",
	"АААААААА!!!",
]

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	speech_root.visible = false
	speech_timer.timeout.connect(_on_speech_timer_timeout)
	# Random ambient speech while idle
	var ambient := Timer.new()
	add_child(ambient)
	ambient.wait_time = randf_range(8.0, 16.0)
	ambient.timeout.connect(_ambient_speech)
	ambient.start()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if player == null or player.is_caught:
		return

	var dist := global_position.distance_to(player.global_position)

	# ── Catch check ──
	if dist < CATCH_DIST:
		player.get_caught()
		_say(CLOSE_PHRASES[randi() % CLOSE_PHRASES.size()])
		return

	# ── Detection (RE9: enemy retains memory of last position) ──
	if dist < SEE_DIST:
		is_chasing = true
		last_known_pos = player.global_position
		chase_duration += delta
	elif dist > SEE_DIST + 6.0:
		is_chasing = false
		chase_duration = max(0.0, chase_duration - delta * 0.5)

	# Hearing (running player) — chase even if not visible
	if dist < HEAR_DIST and player.velocity.length() > 4.5:
		is_chasing = true
		last_known_pos = player.global_position

	# ── Rage mode ── (RE9: elite enemy behaviour after long chase)
	if chase_duration > 18.0:
		is_raging = true
	if rage_timer > 0.0:
		rage_timer -= delta
		is_raging = true
	elif is_raging and chase_duration < 5.0:
		is_raging = false

	# ── Speed (escalates the longer he chases — RE9 mechanic) ──
	var chase_boost := min(chase_duration * 0.08, 1.8)
	var speed := PATROL_SPEED
	if is_raging:
		speed = RAGE_SPEED
	elif is_chasing:
		speed = CHASE_SPEED + chase_boost

	# ── Navigation ──
	if is_chasing:
		nav_agent.target_position = last_known_pos
		var next := nav_agent.get_next_path_position()
		var dir := (next - global_position).normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		# Face player
		if dist < SEE_DIST:
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 0.8)
		velocity.z = move_toward(velocity.z, 0.0, 0.8)

	move_and_slide()

	# ── Speech during chase ──
	speech_cooldown -= delta
	if is_chasing and speech_cooldown <= 0.0:
		speech_cooldown = randf_range(3.0, 6.5)
		if is_raging:
			_say(RAGE_PHRASES[randi() % RAGE_PHRASES.size()])
		elif dist < SEE_DIST * 0.5:
			_say(CLOSE_PHRASES[randi() % CLOSE_PHRASES.size()])
		else:
			_say(CHASE_PHRASES[randi() % CHASE_PHRASES.size()])

	# ── Footstep audio (louder when closer) ──
	step_timer += delta
	var step_interval := 0.55 if not is_raging else 0.32
	if step_timer >= step_interval and is_chasing:
		step_timer = 0.0
		footstep_audio.volume_db = linear_to_db(clamp(1.0 - dist / 20.0, 0.0, 1.0))
		footstep_audio.play()

func _say(text: String) -> void:
	speech_node.text = text
	speech_root.visible = true
	speech_timer.wait_time = 2.5
	speech_timer.start()
	if growl_audio:
		growl_audio.play()

func _on_speech_timer_timeout() -> void:
	speech_root.visible = false

func _ambient_speech() -> void:
	if not is_chasing:
		_say(IDLE_PHRASES[randi() % IDLE_PHRASES.size()])
	var t := get_node_or_null("../..") as Timer
	if t == null:
		var new_t := Timer.new()
		add_child(new_t)
		new_t.wait_time = randf_range(10.0, 20.0)
		new_t.timeout.connect(_ambient_speech)
		new_t.one_shot = true
		new_t.start()

func trigger_rage() -> void:
	is_raging = true
	rage_timer = 6.0
	_say(RAGE_PHRASES[randi() % RAGE_PHRASES.size()])
