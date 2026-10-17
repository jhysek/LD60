extends Node2D

@onready var anim = $AnimationPlayer
var map
var interpreter = null

@export var direction_idx: int = 0
@export var tie_color: Color = Color("#962d26")
var directions = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var map_pos: Vector2

var initial_map_pos: Vector2
var initial_direction_idx: int = 0


func _ready():
	# !! Must be laced in TilemapLayer -> Actors
	map = get_parent().get_parent()
	
	map_pos = Vector2(map.world_to_map(position))
	position = map.map_to_world(map_pos)
	initial_map_pos = map_pos
	initial_direction_idx = direction_idx
	update_visual_rotation()
	$Visual/Body/Tie.self_modulate = tie_color
	
func reset():
	direction_idx = initial_direction_idx
	map_pos = initial_map_pos
	position = map.map_to_world(map_pos)
	update_visual_rotation()
	
# some instructions are actions that can be performed by actors
func perform_instruction(instruction, parameter):
	print("ACTOR " + str(name) + " has instruction: " + str(instruction) + "(" + str(parameter) + ")")
	match instruction:
		Instruction.STEP:
			step()
			
		Instruction.TURN:
			if parameter == 1:
				turn_right()
			if parameter == 2:
				turn_left()

func update_visual_rotation():
	for arrow in $Visual/Arrows.get_children():
		arrow.hide()
		
	print("DIRECTION IDX: " + str(direction_idx))
	match direction_idx:
		0: # right
			print("-> RIGHT")
			$Visual/Arrows/Right.show()
			$Visual/Body.texture = load("res://components/actor/body_right.png")
			$Visual/Body/Head.texture = load("res://components/actor/head_right.png")
			$Visual/Body/Tie.show()
			$Visual/Body/HandLeft.show_behind_parent = true
			$Visual/Body/HandRight.show_behind_parent = false
			$Visual.scale = Vector2(1, 1)
		1: # down
			print("-> DOWN")
			$Visual/Arrows/Down.show()
			$Visual/Body.texture = load("res://components/actor/body_front.png")
			$Visual/Body/Head.texture = load("res://components/actor/head_front.png")
			$Visual/Body/Tie.show()
			$Visual/Body/HandLeft.show_behind_parent = false
			$Visual/Body/HandRight.show_behind_parent = false
			$Visual.scale = Vector2(-1, 1)
		2: # left
			print("-> LEFT")
			$Visual/Arrows/Right.show()
			$Visual/Body.texture = load("res://components/actor/body_right.png")
			$Visual/Body/Head.texture = load("res://components/actor/head_right.png")
			$Visual/Body/Tie.show()
			$Visual/Body/HandLeft.show_behind_parent = true
			$Visual/Body/HandRight.show_behind_parent = false
			$Visual.scale = Vector2(-1, 1)
		3: # top
			print("-> TOP")
			$Visual/Arrows/Up.show()
			$Visual/Body.texture = load("res://components/actor/body_back.png")
			$Visual/Body/Head.texture = load("res://components/actor/head_back.png")
			$Visual/Body/HandLeft.show_behind_parent = true
			$Visual/Body/HandRight.show_behind_parent = true
			$Visual/Body/Tie.hide()

func step():
	var direction = directions[direction_idx]
	var new_map_pos = map_pos + direction 
	
	if !map.can_jump_to(new_map_pos):
		print("ERROR: NEMUZU TAM SKOCIT!")
		return
		
	anim.play("Jump")
	map_pos = new_map_pos
	var tween = create_tween()
	tween.tween_property(self, "position", map.map_to_world(new_map_pos), 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func turn_right():
	direction_idx = (direction_idx + 1) % 4
	update_visual_rotation()
	
func turn_left():
	direction_idx = (direction_idx - 1) % 4
	if direction_idx == -1:
		direction_idx = 3
	update_visual_rotation()
