extends TileMapLayer

@onready var tile_size = Vector2(64, 52)

var objects = {}
	
func _ready():
	initialize_objects()
	
func _input(event):
	update_mouse_pos(event)
		
func update_mouse_pos(event):
	if event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		var local_mouse_pos = mouse_pos - position
		$Label.text = str(local_mouse_pos) + " --- " + str($Actors/Actor.map_pos) + " MAP: " + str(local_to_map(local_mouse_pos))
	
func can_jump_to(map_position):
	var cell_id = get_cell_source_id(map_position)
	var blocking_object = objects.has(map_position) && objects[map_position].blocking
	return cell_id >= 0 || blocking_object
	
func object_at(map_position):
	if objects.has(map_position):
		return objects[map_position]
	
	return null
		
func reset():
	for actor in $Actors.get_children():
		actor.reset()
		
func world_to_map(local_position):
	return local_to_map(local_position)
	
func map_to_world(map_position):
	return map_to_local(map_position) #+ Vector2(tile_set.tile_size / 2)

func initialize_objects():
	for object in $Objects.get_children():
		objects[object.map_pos] = {
			node = object,
			group = object.get_groups()[0],
			blocking = object.blocking
		}
