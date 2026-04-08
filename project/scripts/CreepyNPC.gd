extends Node3D
# CREEPY_NPC.GD
# Appears suddenly in doorways / hallways, stares, disappears.
# Inspired by RE9 "The Girl" stalker — silent dread.
# Does NOT attack — just psychological horror.

@onready var face_sprite  : Sprite3D  = $FaceSprite3D
@onready var label        : Label3D   = $Label3D
@onready var appear_timer : Timer     = $AppearTimer
@onready var hide_timer   : Timer     = $HideTimer
@onready var stare_sfx    : AudioStreamPlayer3D = $StareSFX

const APPEAR_PHRASES := [
	"...",
	"ты видишь меня?",
	"я здесь.",
	"беги.",
	"он идёт.",
	"gg.",
	"РОНЕН",
]

var player = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	face_sprite.visible = false
	label.visible = false
	_schedule_appear()
	appear_timer.timeout.connect(_on_appear)
	hide_timer.timeout.connect(_on_hide)

func _schedule_appear() -> void:
	appear_timer.wait_time = randf_range(22.0, 50.0)
	appear_timer.start()

func _on_appear() -> void:
	if player == null:
		return
	# Teleport to just in front of player, offset sideways
	var offset := player.transform.basis.z * -4.0 + Vector3(randf_range(-2.5, 2.5), 0.0, 0.0)
	global_position = player.global_position + offset
	global_position.y = player.global_position.y

	face_sprite.visible = true
	label.visible = true
	label.text = APPEAR_PHRASES[randi() % APPEAR_PHRASES.size()]

	# Face toward player
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	rotate_y(PI)

	if stare_sfx:
		stare_sfx.play()

	hide_timer.wait_time = randf_range(1.8, 3.5)
	hide_timer.start()

func _on_hide() -> void:
	face_sprite.visible = false
	label.visible = false
	_schedule_appear()
