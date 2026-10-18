extends Node2D

func _ready():
	Transition.openScene()
	$Printout/Paper/Objectives.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	$Printout.start("PUNCH CORP\n------------\nWe regret to inform you that your employment has been terminated.")


func _on_btn_play_pressed() -> void:
	Sfx.play("BtnClick")
	Transition.switchTo("res://scenes/menu.tscn")


func _on_btn_step_pressed() -> void:
	Sfx.play("BtnClick")


func _on_btn_stop_pressed() -> void:
	Sfx.play("BtnClick")
