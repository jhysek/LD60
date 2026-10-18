extends Node2D


func _ready():
	$Paper.position.y = 0
	
	
func start(objectives):
	$Paper/Objectives.text = str(objectives)
	var tween = get_tree().create_tween()
	tween.tween_property($Paper, 'position', Vector2(0, 150), 3).set_delay(1.0)
	
