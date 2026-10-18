extends Marker2D

var blocking = false
var map_pos: Vector2 
var map

func _ready():
	# !! Must be laced in TilemapLayer -> Actors
	map = get_parent().get_parent()
	map_pos = Vector2(map.world_to_map(position))
	position = map.map_to_world(map_pos)

func reset():
	pass
