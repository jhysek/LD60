extends Node2D

func _ready():
	Transition.openScene()
	$Printout/Paper/Objectives.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	$Printout.start("PUNCH CORP\n------------\nCongratulations on your new job! We are sure you'll do great.")
	init_buttons()
	
func init_buttons():
	if LevelSwitcher.opened_levels == 0:
		$Levels.hide()
	else:
		$Levels.show()
		
	print("OPENED: ", LevelSwitcher.opened_levels)
	for i in range(6):
		var btn = $Levels.get_node("BtnPlay" + str(i))
		if LevelSwitcher.opened_levels > i:
			btn.disabled = false
			btn.get_node("Stats").show()
			if LevelSwitcher.best.has("level" + str(i)):
				var best = LevelSwitcher.best["level" + str(i)]
				if best.lines > 9998:
					btn.get_node("Stats").hide()
				else:
					btn.get_node("Stats").text = "L: " + str(best.lines) + "\n" + \
												 "T: " + str(best.ticks)
			else:
				btn.get_node("Stats").hide()
		else:
			btn.disabled = true
			btn.self_modulate = Color("ff7070")
			btn.get_node("Stats").hide()
			
	
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


func _on_btn_play_0_pressed() -> void:
	LevelSwitcher.current_level = 0
	LevelSwitcher.restart_level()
	Sfx.play("BtnClick")


func _on_btn_play_1_pressed() -> void:
	LevelSwitcher.current_level = 1
	LevelSwitcher.restart_level()
	Sfx.play("BtnClick")


func _on_btn_play_2_pressed() -> void:
	LevelSwitcher.current_level = 2
	LevelSwitcher.restart_level()
	Sfx.play("BtnClick")


func _on_btn_play_3_pressed() -> void:
	LevelSwitcher.current_level = 3
	LevelSwitcher.restart_level()
	Sfx.play("BtnClick")


func _on_btn_play_4_pressed() -> void:
	LevelSwitcher.current_level = 4
	LevelSwitcher.restart_level()
	Sfx.play("BtnClick")


func _on_btn_play_5_pressed() -> void:
	LevelSwitcher.current_level = 5
	LevelSwitcher.restart_level()
	Sfx.play("BtnClick")
