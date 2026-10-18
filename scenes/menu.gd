extends Node2D

func _ready():
	Transition.openScene()


func _on_button_pressed() -> void:
	LevelSwitcher.start_level()

func _process(delta):
	$Bg.rotation += delta * 0.02
