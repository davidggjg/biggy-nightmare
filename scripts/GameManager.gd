extends Node
# ═══════════════════════════════════════════════
#  GAME_MANAGER.GD  —  BIGGY NIGHTMARE
#  RE9 Requiem inspired systems:
#  • Red screen vignette on damage (fades out)
#  • Dynamic music layers by danger level
#  • Random ambient horror events
#  • Russian grandma ambient voice (text + synth)
#  • Jumpscare system (timed, not spam)
#  • Win / Game Over flows
# ═══════════════════════════════════════════════

const KEYS_NEEDED := 3

# ── RE9: danger thresholds ──
const DANGER_NONE    := 0.0
const DANGER_WARN    := 0.35   # music shifts, mild vignette
const DANGER_HIGH    := 0.65   # strong vignette, flickering
const DANGER_EXTREME := 0.85   # max heartbeat, red screen

@onready var player               = get_tree().get_first_node_in_group("player")
@onready var biggy                = get_tree().get_first_node_in_group("biggy")

# HUD nodes
@onready var health_bar           : ProgressBar  = $HUD/HealthBar
@onready var stamina_bar          : ProgressBar  = $HUD/StaminaBar
@onready var key_label            : Label        = $HUD/KeyLabel
@onready var objective_label      : Label        = $HUD/ObjectiveLabel
@onready var interact_label       : Label        = $HUD/InteractLabel

# Vignette / damage overlays
@onready var damage_vignette      : ColorRect    = $HUD/DamageVignette
@onready var danger_vignette      : ColorRect    = $HUD/DangerVignette
@onready var white_flash          : ColorRect    = $HUD/WhiteFlash
@onready var jumpscare_overlay    : Control      = $HUD/JumpscareOverlay
@onready var jumpscare_image      : TextureRect  = $HUD/JumpscareOverlay/JumpscareImage
@onready var jumpscare_label      : Label        = $HUD/JumpscareOverlay/Label

# Ambient
@onready var grandma_label        : Label        = $HUD/GrandmaLabel
@onready var jumpscare_timer      : Timer        = $JumpscareTimer
@onready var ambient_timer        : Timer        = $AmbientTimer
@onready var damage_fade_timer    : Timer        = $DamageFadeTimer

# Audio
@onready var music_layer_calm     : AudioStreamPlayer = $Audio/MusicCalm
@onready var music_layer_tense    : AudioStreamPlayer = $Audio/MusicTense
@onready var music_layer_chase    : AudioStreamPlayer = $Audio/MusicChase
@onready var sfx_heartbeat        : AudioStreamPlayer = $Audio/Heartbeat
@onready var sfx_jumpscare        : AudioStreamPlayer = $Audio/JumpscareSound
@onready var sfx_grandma          : AudioStreamPlayer = $Audio/GrandmaVoice
@onready var sfx_ambient_thud     : AudioStreamPlayer = $Audio/AmbientThud

@onready var game_over_screen     : Control      = $HUD/GameOverScreen
@onready var win_screen           : Control      = $HUD/WinScreen

var keys_found     := 0
var danger_level   := 0.0
var _damage_vign   := 0.0   # current red flash intensity
var _jumpscare_cd  := 0.0

# ── Russian grandma lines (ambient horror — RE9 atmosphere) ──
const GRANDMA_LINES := [
	"ронен... ронен, приди домой...",
	"здесь холодно, мальчик...",
	"уходи... пока не поздно...",
	"он идёт за тобой... старуха знает...",
	"gg, мальчик... gg...",
	"я слышу шаги... тяжёлые шаги...",
	"беги быстрее, глупый...",
	"тшшш... тихо... он рядом...",
	"не открывай эту дверь, мальчик...",
	"BIGG BIGG BIGG... аааа...",
	"он найдёт тебя... он всегда находит...",
]

const JUMPSCARE_TEXTS := [
	"БУ!!!",
	"BIGGY!!!",
	"ТЫ ТУТ!!!",
	"НАШЁЛ!!!",
	"АААА!!!",
]

func _ready() -> void:
	game_over_screen.visible = false
	win_screen.visible       = false
	jumpscare_overlay.visible = false
	damage_vignette.modulate.a = 0.0
	danger_vignette.modulate.a = 0.0
	white_flash.modulate.a    = 0.0
	grandma_label.visible     = false

	# Connect player signals
	if player:
		player.player_caught.connect(_on_player_caught)
		player.key_collected.connect(_on_key_collected)
		player.health_changed.connect(_on_health_changed)
		player.stamina_changed.connect(_on_stamina_changed)

	_schedule_jumpscare()
	_schedule_ambient()

	# Start calm music
	music_layer_calm.play()

func _process(delta: float) -> void:
	if not player or not biggy:
		return

	# ── Calculate danger level (0..1) ──
	var dist := player.global_position.distance_to(biggy.global_position)
	danger_level = clamp(1.0 - dist / 14.0, 0.0, 1.0)
	player.set_danger_level(danger_level)

	# ── Dynamic music layers (RE9 style) ──
	_update_music_layers(delta)

	# ── Danger vignette (red edges when Biggy close) ──
	var target_vign_a := danger_level * 0.55
	danger_vignette.modulate.a = lerp(danger_vignette.modulate.a, target_vign_a, delta * 3.0)

	# ── Damage vignette fade out ──
	if _damage_vign > 0.0:
		_damage_vign = max(0.0, _damage_vign - delta * 1.2)
		damage_vignette.modulate.a = _damage_vign

	# ── Heartbeat ──
	if danger_level > DANGER_WARN:
		if not sfx_heartbeat.playing:
			sfx_heartbeat.play()
		sfx_heartbeat.pitch_scale = 1.0 + danger_level * 0.9
	else:
		sfx_heartbeat.stop()

	# ── White flash fade ──
	if white_flash.modulate.a > 0.0:
		white_flash.modulate.a = max(0.0, white_flash.modulate.a - delta * 8.0)

func _update_music_layers(delta: float) -> void:
	# RE9: seamless music transitions by danger level
	var calm_vol  := 0.0
	var tense_vol := 0.0
	var chase_vol := 0.0

	if danger_level < DANGER_WARN:
		calm_vol = 1.0
	elif danger_level < DANGER_HIGH:
		calm_vol  = 1.0 - (danger_level - DANGER_WARN) / (DANGER_HIGH - DANGER_WARN)
		tense_vol = (danger_level - DANGER_WARN) / (DANGER_HIGH - DANGER_WARN)
	elif danger_level < DANGER_EXTREME:
		tense_vol = 1.0 - (danger_level - DANGER_HIGH) / (DANGER_EXTREME - DANGER_HIGH)
		chase_vol = (danger_level - DANGER_HIGH) / (DANGER_EXTREME - DANGER_HIGH)
	else:
		chase_vol = 1.0

	if music_layer_calm.is_playing():
		music_layer_calm.volume_db  = linear_to_db(lerp(db_to_linear(music_layer_calm.volume_db),  calm_vol,  delta * 2.0))
	if music_layer_tense.is_playing():
		music_layer_tense.volume_db = linear_to_db(lerp(db_to_linear(music_layer_tense.volume_db), tense_vol, delta * 2.0))
	if music_layer_chase.is_playing():
		music_layer_chase.volume_db = linear_to_db(lerp(db_to_linear(music_layer_chase.volume_db), chase_vol, delta * 2.0))

# ── Damage feedback (RE9: screen pulses red) ──
func trigger_damage_vignette(intensity: float = 1.0) -> void:
	_damage_vign = intensity
	damage_vignette.modulate.a = intensity
	# Brief white flash
	white_flash.modulate.a = 0.4

# ── Jumpscare (RE9: timed scares, never spam) ──
func _schedule_jumpscare() -> void:
	jumpscare_timer.wait_time = randf_range(30.0, 65.0)
	jumpscare_timer.start()

func _on_jumpscare_timer_timeout() -> void:
	_trigger_jumpscare()

func _trigger_jumpscare() -> void:
	if game_over_screen.visible or win_screen.visible:
		return
	jumpscare_overlay.visible = true
	jumpscare_label.text = JUMPSCARE_TEXTS[randi() % JUMPSCARE_TEXTS.size()]
	sfx_jumpscare.play()
	white_flash.modulate.a = 1.0

	var tween := create_tween()
	tween.tween_property(jumpscare_overlay, "modulate:a", 1.0, 0.05)
	tween.tween_interval(0.35)
	tween.tween_property(jumpscare_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		jumpscare_overlay.visible = false
		_schedule_jumpscare()
	)

# ── Ambient horror events (RE9 atmosphere) ──
func _schedule_ambient() -> void:
	ambient_timer.wait_time = randf_range(12.0, 28.0)
	ambient_timer.start()

func _on_ambient_timer_timeout() -> void:
	var roll := randf()
	if roll < 0.42:
		_play_grandma_voice()
	elif roll < 0.70:
		# Distant thud — RE9 style off-screen audio
		sfx_ambient_thud.play()
	else:
		# Flashlight momentarily cuts out
		if player:
			player.flashlight.visible = false
			await get_tree().create_timer(randf_range(0.6, 1.2)).timeout
			if player:
				player.flashlight.visible = true
	_schedule_ambient()

func _play_grandma_voice() -> void:
	var line := GRANDMA_LINES[randi() % GRANDMA_LINES.size()]
	grandma_label.text = '"' + line + '"'
	grandma_label.visible = true
	if sfx_grandma:
		sfx_grandma.play()
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(grandma_label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(func():
		grandma_label.visible = false
		grandma_label.modulate.a = 1.0
	)

# ── Player signals ──
func _on_health_changed(hp: float) -> void:
	health_bar.value = hp
	trigger_damage_vignette(1.0 - hp / 100.0 + 0.4)
	if hp < 30.0:
		# RE9: persistent low health red vignette
		damage_vignette.modulate.a = max(damage_vignette.modulate.a, 0.3)

func _on_stamina_changed(st: float) -> void:
	stamina_bar.value = st

func _on_key_collected(count: int) -> void:
	keys_found = count
	key_label.text = "🔑  %d / %d" % [keys_found, KEYS_NEEDED]
	if keys_found >= KEYS_NEEDED:
		objective_label.text = "► Find the EXIT door!"

func _on_player_caught() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	white_flash.modulate.a = 1.0
	sfx_jumpscare.play()
	await get_tree().create_timer(0.4).timeout
	game_over_screen.visible = true
	get_tree().paused = true

func _win() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	win_screen.visible = true
	get_tree().paused = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if game_over_screen.visible or win_screen.visible:
			get_tree().paused = false
			get_tree().reload_current_scene()

func show_interact_prompt(text: String) -> void:
	interact_label.text = text
	interact_label.visible = true

func hide_interact_prompt() -> void:
	interact_label.visible = false
