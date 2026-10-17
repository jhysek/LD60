extends Object
class_name ProgramInterpreter

signal on_program_error(line, message)
signal on_actor_instruction(command, argument)
signal on_program_ended

const TOTAL_INSTRUCTIONS = 10
const ACTOR_INTERPRETABLE = [Instruction.STEP, Instruction.TURN]

var registry_a = 0
var registry_b = 0
var current_registry = 0

var current_line = 0
var current_program = []

var ended = true

func init_program(program):
	ended = false
	current_line = 0
	current_program = program
	
func tick():
	print("INTERPRETER TICK")
	if ended:
		print("ERROR: no program initialized (or ended)")
		return
	
	interpret_current_line()


func interpret_current_line():
	if ended:
		print("INTERPRETER ERROR: program already ended")
		return
		
	if current_line >= 0 && current_line < current_program.size():
		var current_line = current_program[current_line]
		interpret_instruction(current_line.line, current_line.instruction, current_line.argument)
		
	else:
		print("INTERPRETER ERROR: no such line " + str(current_line) + " in program")
		emit_signal("on_program_ended")

func interpret_instruction(line, instruction, argument):
	if instruction < 0 || instruction >= TOTAL_INSTRUCTIONS:
		print("Interpreter: unknown instruction: " + str(instruction))
		emit_signal("on_program_error", line, "Invalid instruction: " + str(instruction))
		return
		
	match instruction:
		Instruction.STEP: 
			print("STEP " + str(argument))
			emit_signal("on_actor_instruction", instruction, argument)
			current_line += 1
			
		Instruction.TURN: 
			print("TURN " + str(argument))
			if argument != 1 && argument != 2:
				emit_signal("on_program_error", line, "Invalid argument: " + str(argument) + ".\n Allowed: 0001, 0010")
				return
				
			emit_signal("on_actor_instruction", instruction, argument)
			current_line += 1
			
		Instruction.JUMP: 
			print("JUMP to " + str(argument))
			if argument > current_program.size():
				emit_signal("on_program_error", line, "NO SUCH LINE: " + str(argument) + ". Total lines " + str(current_program.size()))
				return
				
			current_line = argument
	
		var other: 
			print("other.. " + str(instruction))
			current_line += 1
	
	if current_line >= current_program.size():
		program_ended()

func stop():
	program_ended()
	
func program_ended():
	emit_signal("on_program_ended")
	ended = true

func set_next_nonempty_line():
	while is_empty_line() || current_line >= current_program.size():
		current_line += 1
	
func is_empty_line():
	var line = current_program[current_line]
	return line.instruction == Instruction.NOOP

func validate_instruction(instruction, argument):
	pass

func decimal_to_binary(decimal):
	pass
	
func interpret_line_preview(instruction, argument):
	if Instruction.DESCRIPTIONS.has(instruction):
		return {
			instruction = Instruction.NAMES[instruction],
			argument = argument_interpretation(instruction, argument),
			description = Instruction.DESCRIPTIONS[instruction]
		}
	else:
		return {
			instruction = "INVALID",
			argument = str(argument),
			description = "Unknown instruction"
		}
		
func argument_interpretation(instruction, argument):
	if instruction == Instruction.TURN:
		match argument:
			1: return "RIGHT"
			2: return "LEFT"
			_: return "ERR"
		return
	
	if instruction == Instruction.STEP:
		if argument == 0:
			return "FORWARD"
		return "ERR"
		
	return str(argument)
