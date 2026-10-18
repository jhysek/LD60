extends Node2D

func _ready():
	Transition.openScene()
	$Printout/Paper/Objectives.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	$Printout.start("PUNCH CORP\n------------\nCongratulations on your new job! We are sure you'll do great.")


func _on_button_pressed() -> void:
	LevelSwitcher.start_level()

func _process(delta):
	$Bg.rotation += delta * 0.02


func _on_btn_play_pressed() -> void:
	Sfx.play("BtnClick")
	LevelSwitcher.start_level()


func _on_btn_step_pressed() -> void:
	Sfx.play("BtnClick")


func _on_btn_stop_pressed() -> void:
	Sfx.play("BtnClick")
