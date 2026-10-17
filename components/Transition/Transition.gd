extends CanvasLayer

var scene: String = "";

func _ready():
	$AnimationPlayer.play_backwards("Fade")

func openScene():
	scene = ""
	$AnimationPlayer.play_backwards("Fade")

func switchTo(target_scene):
	scene = target_scene
	$AnimationPlayer.play("Fade")

func _on_animation_player_animation_finished(anim_name):
	if scene != "":
		get_tree().change_scene_to_file(scene)
