extends Node2D

func _ready():
	Transition.openScene()


func _on_button_pressed() -> void:
	Transition.switchTo("res://scenes/game.tscn")
