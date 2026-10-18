extends TextureRect

signal on_program_updated(lines)

const ROW_HEIGHT = 26.5
const COLUMN_WIDTH = 22.5
const MAX_ROWS = 32

var Hole = preload("res://components/punch_tape_hole/hole.tscn")
var Parser = preload("res://scripts/program_parser.gd")
var Interpreter = preload("res://scripts/program_interpreter.gd")

@onready var row_indicator = $row_indicator
@onready var column_indicator = $column_indicator
@onready var program = $program
@onready var interpreter_cursor = $interpreter_cursor
@onready var interpreter_error = $interpreter_error
@onready var compiler_panel = $CompilerPanel

@onready var start_row_position = row_indicator.position
@onready var start_column_position = column_indicator.position
@onready var start_tape_position = position
@onready var start_compiler_panel_position = compiler_panel.position

var row = 0
var column = 0
var parser = null
var interpreter = null
var last_row = 0

func _ready():
	parser = Parser.new()
	interpreter = Interpreter.new()
	init_column_indicator()
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
		if row < MAX_ROWS - 1:
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
	
func move_to(_row):
	row = _row
	var diff = Vector2(0, row * ROW_HEIGHT)
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(self, 'position', start_tape_position - diff, 0.2).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(row_indicator, 'position', start_row_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(compiler_panel, 'position', start_compiler_panel_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)
	update_compiler_info()
	
func move_to_column(_column):
	column = _column
	var diff = Vector2(column * COLUMN_WIDTH, 0)
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(column_indicator, 'position', start_column_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)
		
func move_down():
	row += 1
	var diff = Vector2(0, row * ROW_HEIGHT)
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(self, 'position', start_tape_position - diff, 0.2).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(row_indicator, 'position', start_row_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(compiler_panel, 'position', start_compiler_panel_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)
	update_compiler_info()
		
func move_up():
	row -= 1
	var diff = Vector2(0, row * ROW_HEIGHT)
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(self, 'position', start_tape_position - diff, 0.2).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(row_indicator, 'position', start_row_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(compiler_panel, 'position', start_compiler_panel_position + diff, 0.2).set_trans(Tween.TRANS_EXPO)
	update_compiler_info()
		
func init_column_indicator():
	column = 3 
	column_indicator.position.x = column * COLUMN_WIDTH + 5
	
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
	update_compiler_info()
	var parsed_prog = parse_program()
	emit_signal("on_program_updated", parsed_prog.size())
	
	
func set_interpreted_line(line_number): 
	interpreter_error.hide()
	
	if line_number == null:
		show_editor_indicators()
		move_to(last_row)
		var tween = get_tree().create_tween()
		tween.tween_property($interpreter_cursor, 'self_modulate', Color(1,1,1,0), 1)
		return

	last_row = line_number
	interpreter_cursor.self_modulate = Color(1,1,1,1)
	var new_pos = Vector2(interpreter_cursor.position.x, start_row_position.y + line_number * ROW_HEIGHT)
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_EXPO)
	tween.tween_property($interpreter_cursor, 'position', new_pos, 0.2)

	move_to(line_number)

func set_interpreter_error(line_number, message):
	move_to(line_number)

	$interpreter_cursor.self_modulate = Color(1,1,1,0)

	interpreter_error.get_node("message").text = message
	$interpreter_error.position.y = start_row_position.y + line_number * ROW_HEIGHT
	interpreter_error.show()
	move_to(line_number)
	show_editor_indicators()
	$CompilerPanel/LineInfo.hide()
	
func redraw_program():
	var program_container = $program
	var holes = PackedVector2Array()
	
	for row in range(0, MAX_ROWS):
		for column in range(0,10):
			if !program.value_at(column, row):
				continue 
				
			var coords = Vector2(start_column_position.x + column * COLUMN_WIDTH, 
								 start_row_position.y + row * ROW_HEIGHT)
									
			holes.append(coords + Vector2(COLUMN_WIDTH/2, ROW_HEIGHT/2))
		
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter("holes", holes)
	shader_material.set_shader_parameter("hole_count", holes.size())

func hide_editor_indicators():
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(column_indicator, 'self_modulate', Color(1,1,1,0), 0.5)
	tween.tween_property(row_indicator, 'self_modulate', Color(1,1,1,0), 0.5)
	tween.tween_property(compiler_panel, 'self_modulate', Color(1,1,1,0), 0.5)
		
	
func show_editor_indicators():
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(column_indicator, 'self_modulate', Color(1,1,1,1), 0.5)
	tween.tween_property(row_indicator, 'self_modulate', Color(1,1,1,1), 0.5)
	tween.tween_property(compiler_panel, 'self_modulate', Color(1,1,1,1), 0.5)
	
func init_row_indicator():
	var x_offset = start_column_position.x - row_indicator.position.x + 6
	for dot in row_indicator.get_children():
		var coords = Vector2(start_column_position.x + int(dot.name) * COLUMN_WIDTH + x_offset, ROW_HEIGHT /2)
		dot.position = coords

func update_compiler_info():
	$CompilerPanel/LineInfo.show()
	var program_line = program.get_line(row)
	var parsed_line = parser.parse_line(program_line)
	var interpreted = interpreter.interpret_line_preview(parsed_line.instruction, parsed_line.argument)
	
	if interpreted.instruction == "INVALID":
		$CompilerPanel/LineInfo/Instruction.set("theme_override_colors/font_color", Color("#8b2019"))
		
	else:
		$CompilerPanel/LineInfo/Instruction.set("theme_override_colors/font_color", Color("#4d4d4d"))
		
	if interpreted.argument == "ERR":
		$CompilerPanel/LineInfo/Argument.set("theme_override_colors/font_color", Color("#8b2019"))
	else:
		$CompilerPanel/LineInfo/Argument.set("theme_override_colors/font_color", Color("#4d4d4d"))
		
	$CompilerPanel/LineInfo/Instruction.text = str(interpreted.instruction)
	$CompilerPanel/LineInfo/Argument.text = str(interpreted.argument)
	$CompilerPanel/LineInfo/Description.text = str(interpreted.description)

# Yeah I know... I attempted to code it like decent man but it didn't work and I had no time.. 
# So it is what it is. Actually, it might be a bug in connecting function to pressed() signal on button. 

func _on_button_0_pressed() -> void:
	move_to_column(0)
	punch()

func _on_button_1_pressed() -> void:
	move_to_column(1)
	punch()

func _on_button_2_pressed() -> void:
	move_to_column(2)
	punch()

func _on_button_3_pressed() -> void:
	move_to_column(3)
	punch()

func _on_button_5_pressed() -> void:
	move_to_column(5)
	punch()

func _on_button_6_pressed() -> void:
	move_to_column(6)
	punch()

func _on_button_7_pressed() -> void:
	move_to_column(7)
	punch()

func _on_button_8_pressed() -> void:
	move_to_column(8)
	punch()
	
func _on_button_9_pressed() -> void:
	move_to_column(9)
	punch()
