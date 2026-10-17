extends Node2D

var interpreter = null

var direction_idx = 0
var directions = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]


func _ready():
	pass

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


func step():
	var direction = directions[direction_idx]
	var tween = create_tween()
	tween.tween_property(self, "position", self.position + direction * 50, 0.5).set_trans(Tween.TRANS_EXPO)

func turn_right():
	direction_idx = (direction_idx + 1) % directions.size()
	
func turn_left():
	direction_idx = (direction_idx - 1) % directions.size()
