extends Node2D

signal on_value_updated(new_value)

@export var randomized = true
@export var value = 0
@export var type = "WallTerminal"
@export var rnd_min = 0
@export var rnd_max = 16
@export var hide_number = false
@export var readonly = false 

@onready var number = get_node(type + "/Number")

var initial_value
var initial_randomized

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
	
	initial_value = value
	initial_randomized = randomized
	
	$WallTerminal.hide()
	$Computer.hide()
	$ComputerFront.hide()
	$ComputerBack.hide()
	$ComputerRight.hide()
	get_node(type).show()
	
	if hide_number:
		number.hide()
	
	if randomized:
		$Timer.start()

func reset():
	print("RESETING")
	if !initial_randomized:
		value = initial_value
	randomized = initial_randomized
	if randomized:
		$Timer.start()

func set_value(_value):
	if readonly:
		# Sfx.play("nono")
		return
		
	# Sfx.play("entered")
	$Timer.stop()
	value = _value
	randomized = false 
	number.text = str(value)
	emit_signal("on_value_updated", value)
	
func get_value():
	$Timer.stop()
	randomized = false 
	print("CMP: gettting value: ", value)
	return value

func _on_timer_timeout() -> void:
	if randomized:
		print("CHANGIG COMPUTER VALEU TO : ", value)
		value = randi_range(rnd_min, rnd_max)
		number.text = str(value)
