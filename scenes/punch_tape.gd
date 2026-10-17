extends TextureRect

const ROW_HEIGHT = 26.5
const COLUMN_WIDTH = 22.5
const MAX_ROWS = 32

var Hole = preload("res://components/punch_tape_hole/hole.tscn")

@onready var row_indicator = $row_indicator
@onready var column_indicator = $column_indicator
@onready var program = $program

@onready var start_row_position = row_indicator.position
@onready var start_column_position = column_indicator.position
@onready var start_tape_position = position

var row = 0
var column = 0

func _ready():
	init_row_indicator()
	program.initialize_empty_program(MAX_ROWS)

func _process(delta): 
	process_inputs()
	
	
func process_inputs():
	if Input.is_action_just_pressed("ui_down"):
		if row < MAX_ROWS:
			move_down()
		else: 
			print("TODO: sound, you are already on bottom")
			
	if Input.is_action_just_pressed("ui_up"):
		if row > 0:
			move_up()
		else:
			print("TODO: sound, your are already on top")
		
	if Input.is_action_just_pressed("ui_left"):
		if column > 0:
			move_left()
		else:
			print("TODO: sound, your are already on the first row")
	
	if Input.is_action_just_pressed("ui_right"):
		if column < 9:
			move_right()
		else:
			print("TODO: sound, your are already on the last row")	
			
	if Input.is_action_just_pressed("ui_accept"):
		punch()
			
func move_down():
	row += 1
	var diff = Vector2(0, row * ROW_HEIGHT)
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(self, 'position', start_tape_position - diff, 0.2).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(row_indicator, 'position', start_row_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)

func move_up():
	row -= 1
	var diff = Vector2(0, row * ROW_HEIGHT)
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(self, 'position', start_tape_position - diff, 0.2).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(row_indicator, 'position', start_row_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)

func move_left():
	column -= 1
	var diff = Vector2(column * COLUMN_WIDTH, 0)
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(column_indicator, 'position', start_column_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)

func move_right():
	column += 1
	var diff = Vector2(column * COLUMN_WIDTH, 0)
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(column_indicator, 'position', start_column_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)

func punch():
	program.punch_at(column, row)
	redraw_program()

func redraw_program():
	var program_container = $program
	
	for hole in program_container.get_children():
		hole.queue_free()
			
	for column in range(0,10):
		for row in range(0, MAX_ROWS):
			if !program.value_at(column, row):
				continue 
				
			var coords = Vector2(start_column_position.x + column * COLUMN_WIDTH, 
								 start_row_position.y + row * ROW_HEIGHT)

			var hole = Hole.instantiate()
			program_container.add_child(hole)
			hole.position = coords + Vector2(COLUMN_WIDTH/2, ROW_HEIGHT/2 - program_container.position.y)
			hole.name = "hole_" + str(column) + "_" + str(row)
			
func init_row_indicator():
	var x_offset = start_column_position.x - row_indicator.position.x + 6
	for dot in row_indicator.get_children():
		var coords = Vector2(start_column_position.x + int(dot.name) * COLUMN_WIDTH + x_offset, ROW_HEIGHT /2)
		dot.position = coords
