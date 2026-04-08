extends Area3D
# KEY.GD — Collectable key item
# Floats and glows. RE9 style: emits light when nearby.

@onready var mesh         : MeshInstance3D = $MeshInstance3D
@onready var collect_label: Label3D        = $Label3D
@onready var glow_light   : OmniLight3D   = $OmniLight3D
@onready var sfx          : AudioStreamPlayer3D = $CollectSFX

var collected := false
var float_timer := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collect_label.visible = false

func _process(delta: float) -> void:
	if collected:
		return
	float_timer += delta
	# Float up and down
	mesh.position.y = sin(float_timer * 1.8) * 0.12
	rotation.y += delta * 1.2
	# Pulse glow
	if glow_light:
		glow_light.light_energy = 1.5 + sin(float_timer * 3.0) * 0.5

func _on_body_entered(body: Node3D) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	mesh.visible = false
	if glow_light:
		glow_light.visible = false
	collect_label.text = "🔑 KEY!"
	collect_label.visible = true
	if sfx:
		sfx.play()
	body.collect_key()
	await get_tree().create_timer(1.2).timeout
	queue_free()
