extends TileMapLayer

@onready var tile_size = Vector2(tile_set.tile_size)

	
func _input(event):
	update_mouse_pos(event)
		
func update_mouse_pos(event):
	if event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		var local_mouse_pos = mouse_pos - position
		$Label.text = str(local_mouse_pos) + " --- " + str($Actors/Actor.position) + " MAP: " + str(local_to_map(local_mouse_pos))
	
func can_jump_to(map_position):
	var cell_id = get_cell_source_id(map_position)
	print("JUMPING TO: ", get_cell_source_id(map_position))
	return cell_id >= 0
		
func world_to_map(local_position):
	return local_to_map(local_position)
	
func map_to_world(map_position):
	return map_to_local(map_position) #+ Vector2(tile_set.tile_size / 2)
