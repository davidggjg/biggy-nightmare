extends StaticBody3D
# DOOR.GD — Hospital door. Requires keys to open.

@onready var label         : Label3D  = $Label3D
@onready var interact_area : Area3D   = $InteractArea
@onready var creak_sfx     : AudioStreamPlayer3D = $CreakSFX
@onready var game_manager  = get_tree().get_first_node_in_group("game_manager")

var keys_required := 3
var is_open := false
var player_nearby := false

func _ready() -> void:
	label.text = "🔒 EXIT — Need %d keys" % keys_required
	label.visible = false
	interact_area.body_entered.connect(func(b):
		if b.is_in_group("player"):
			player_nearby = true
			label.visible = true
			if game_manager:
				game_manager.show_interact_prompt("[E]  Open Exit")
	)
	interact_area.body_exited.connect(func(b):
		if b.is_in_group("player"):
			player_nearby = false
			label.visible = false
			if game_manager:
				game_manager.hide_interact_prompt()
	)

func _process(_delta: float) -> void:
	if is_open or not player_nearby:
		return
	if Input.is_action_just_pressed("interact"):
		var p = get_tree().get_first_node_in_group("player")
		if p and p.keys_collected >= keys_required:
			_open(p)
		else:
			label.text = "🔒 Need %d keys! (%d)" % [keys_required, 0 if not p else p.keys_collected]

func _open(player) -> void:
	is_open = true
	label.text = "✅ ESCAPED!"
	if creak_sfx:
		creak_sfx.play()
	var tween := create_tween()
	tween.tween_property(self, "rotation:y", rotation.y + PI / 2.0, 0.7)
	tween.tween_callback(func():
		collision_layer = 0
		# Trigger win
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm:
			gm._win()
	)
