extends TextureRect

const ROW_HEIGHT = 26.5
const COLUMN_WIDTH = 22.5
const MAX_ROWS = 32

var Hole = preload("res://components/punch_tape_hole/hole.tscn")
var Parser = preload("res://scripts/program_parser.gd")
var Interpreter = preload("res://scripts/program_interpreter.gd")

@onready var row_indicator = $row_indicator
@onready var column_indicator = $column_indicator
@onready var program = $program

@onready var start_row_position = row_indicator.position
@onready var start_column_position = column_indicator.position
@onready var start_tape_position = position

var row = 0
var column = 0
var parser = null
var interpreter = null

func _ready():
	parser = Parser.new()
	interpreter = Interpreter.new()
	
	init_row_indicator()
	program.initialize_empty_program(MAX_ROWS)

func parse_program():
	var parsed = []
	for i in range(MAX_ROWS):
		var program_line = program.get_line(i)
		var parsed_line = parser.parse_line(program_line)
		parsed.append({
			line = i,
			instruction = parsed_line.instruction,
			argument = parsed_line.argument
		})
	return remove_empty_trailing_lines(parsed)
	
func remove_empty_trailing_lines(lines):
	while lines.size() > 0:
		var last_item = lines.pop_back()
		if last_item.instruction != Instruction.NOOP:
			lines.append(last_item)
			return lines
	return lines
	
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
	
func move_to(row):
	var diff = Vector2(0, row * ROW_HEIGHT)
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(self, 'position', start_tape_position - diff, 0.2).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(row_indicator, 'position', start_row_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)
	
		
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
	if column == 4:
		column = 3
	var diff = Vector2(column * COLUMN_WIDTH, 0)
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(column_indicator, 'position', start_column_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)

func move_right():
	column += 1
	if column == 4:
		column = 5
	var diff = Vector2(column * COLUMN_WIDTH, 0)
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(column_indicator, 'position', start_column_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)

func punch():
	program.punch_at(column, row)
	
	var line = program.get_line(row)
	var cmd = parser.parse_line(line)
	interpreter.interpret_instruction(row, cmd.instruction, cmd.argument)
	
	redraw_program()

func set_interpreted_line(line_number): 
	$interpreter_error.hide()
	
	print("SET LINE: " + str(line_number))
	if line_number == null:
		var tween = get_tree().create_tween()
		tween.tween_property($interpreter_cursor, 'self_modulate', Color(1,1,1,0), 1)
		return

	$interpreter_cursor.self_modulate = Color(1,1,1,1)
	$interpreter_cursor.position.y = start_row_position.y + line_number * ROW_HEIGHT

func set_interpreter_error(line_number, message):
	move_to(line_number)
	$interpreter_cursor.self_modulate = Color(1,1,1,0)
	$interpreter_error/message.text = message
	$interpreter_error.position.y = start_row_position.y + line_number * ROW_HEIGHT
	$interpreter_error.show()

func redraw_program():
	var program_container = $program
	
	for hole in program_container.get_children():
		hole.queue_free()
			
	for row in range(0, MAX_ROWS):
		for column in range(0,10):
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
