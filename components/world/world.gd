extends TileMapLayer

func _input(event):
	update_mouse_pos(event)
	
	
func update_mouse_pos(event):
	if event is InputEventMouseMotion:
		print("Mouse Motion at: ", event.position)
		$Label.text = str(event.position)
	
