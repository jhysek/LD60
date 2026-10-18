extends Node2D

@export var randomized = true
@export var value = 0
@export var type = "WallTerminal"

@onready var number = get_node(type + "/Number")

var blocking = true
var map_pos: Vector2 
var map

func _ready():
	# !! Must be placed in TilemapLayer -> Objects
	map = get_parent().get_parent()
	map_pos = Vector2(map.world_to_map(position))
	position = map.map_to_world(map_pos)
	randomize()
	number.text = str(value)
	
	$WallTerminal.hide()
	$Computer.hide()
	get_node(type).show()
	
	if randomized:
		$Timer.start()

func set_value(_value):
	$Timer.stop()
	value = _value
	randomized = false 
	number.text = str(value)
	
func get_value():
	$Timer.stop()
	randomized = false 
	return value

func _on_timer_timeout() -> void:
	if randomized:
		value = randi_range(0,16)
		number.text = str(value)
