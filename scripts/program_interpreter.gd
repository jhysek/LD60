extends Object
class_name ProgramInterpreter

signal on_program_error(line, message)
signal on_actor_instruction(command, argument)
signal on_program_ended
signal on_memory_updated(user_memory)

const MAX_USER_MEM = 8
const TOTAL_INSTRUCTIONS = 16
const ACTOR_INTERPRETABLE = [Instruction.STEP, Instruction.TURN, Instruction.WRITE]

var COMPARE_RESULT_ADDRESS = 8
var CALL_RETURN_ADDRESS = 9

var memory = [
	0, 0, 0, 0,  0, 0, 0, 0,
	0, 0, 0, 0,  0, 0, 0, 0
]

var current_line = 0
var current_program = []

var ended = true
var last_memory_write_line = 0

func init_program(program):
	ended = false
	clear_memory()
	current_line = 0
	current_program = program

func clear_memory():
	memory = [
		0, 0, 0, 0,  0, 0, 0, 0,
		0, 0, 0, 0,  0, 0, 0, 0
	]
	
func tick():
	print("INTERPRETER TICK")
	if ended:
		print("ERROR: no program initialized (or ended)")
		return
	
	interpret_current_line()
	
func store_to_memory(address, value):
	update_memory(address, value, last_memory_write_line)

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
			emit_signal("on_actor_instruction", instruction, argument)
			current_line += 1
			
		Instruction.TURN: 
			if argument != 1 && argument != 2:
				emit_signal("on_program_error", line, "Invalid argument: " + str(argument) + ".\n Allowed: 0001, 0010")
				return
				
			emit_signal("on_actor_instruction", instruction, argument)
			current_line += 1
			
		Instruction.JUMP: 
			if argument > current_program.size():
				emit_signal("on_program_ended")
				return
				
			current_line = argument
	
		Instruction.READ:
			if argument >= MAX_USER_MEM:
				emit_signal("on_program_error", line, "OUT OF MEMORY - argument has to be less than 8")
				return
				
			print("INTERPRETER: READING...")
			# Can cause race conditions if we add multiple actors, 
			# but I doubt I can do multiple actors during Compo, so screw it...
			last_memory_write_line = current_line
			emit_signal("on_actor_instruction", instruction, argument)
			current_line += 1
			
		Instruction.ADD:			
			update_memory(0, memory[argument] + memory[0],line)
			current_line += 1
			
		Instruction.SET:
			update_memory(0, argument, line)
			current_line += 1
			
		Instruction.COPY:
			update_memory(argument, 0, line)
			current_line += 1
			
		Instruction.WRITE:
			if argument > MAX_USER_MEM:
				emit_signal("on_program_error", line, "OUT OF MEMORY - argument has to be less than 8")
				return
				
			print("CALLING WRITE")
			emit_signal("on_actor_instruction", instruction, memory[argument])
			current_line += 1
		
		Instruction.CMP:
			if argument > MAX_USER_MEM:
				emit_signal("on_program_error", line, "OUT OF MEMORY - argument has to be less than 8")
				return
				
			if memory[0] == memory[argument]:
				memory[COMPARE_RESULT_ADDRESS] = 0
				
			if memory[0] > memory[argument]:
				memory[COMPARE_RESULT_ADDRESS] = 1
				
			if memory[0] < memory[argument]:
				memory[COMPARE_RESULT_ADDRESS] = 2
				
			current_line += 1
			
		Instruction.JEQ:
			# exit
			if argument > current_program.size():
				emit_signal("on_program_ended")
				return
				
			if memory[COMPARE_RESULT_ADDRESS] == 0:
				current_line = argument
			else:
				current_line = current_line + 1
				
		Instruction.JNE:
			if argument > current_program.size():
				emit_signal("on_program_ended")
				return
				
			if memory[COMPARE_RESULT_ADDRESS] != 0:
				current_line = argument
			else:
				current_line = current_line + 1
				
		Instruction.JGE:
			if argument > current_program.size():
				emit_signal("on_program_ended")
				return
				
			if memory[COMPARE_RESULT_ADDRESS] == 0 || memory[COMPARE_RESULT_ADDRESS] == 2:
				current_line = argument
			else:
				current_line = current_line + 1			
		
		Instruction.JL:
			if argument > current_program.size():
				emit_signal("on_program_ended")
				return
				
			if memory[COMPARE_RESULT_ADDRESS] == 1:
				current_line = argument
			else:
				current_line = current_line + 1			
		
		Instruction.CALL:
			if argument > current_program.size():
				emit_signal("on_program_error", line, "NO SUCH LINE: " + str(argument) + ". Total lines " + str(current_program.size()))
				return
				
			memory[CALL_RETURN_ADDRESS] = current_line + 1
			current_line = argument
		
		Instruction.RET:
			if memory[CALL_RETURN_ADDRESS] > current_program.size():
				emit_signal("on_program_error", line, "INTERNAL ERROR, return address not exist " + str(memory[CALL_RETURN_ADDRESS]) + ". Total lines " + str(current_program.size()))
				return	
			
			current_line = memory[CALL_RETURN_ADDRESS]
		
		var other: 
			print("other.. " + str(instruction))
			current_line += 1
	
	if current_line >= current_program.size():
		program_ended()

func update_memory(address, value, line):
	if address > MAX_USER_MEM:
		emit_signal("on_program_error", line, "OUT OF MEMORY - argument has to be less than " + str(MAX_USER_MEM))
		return
				
	memory[address] = value
	emit_signal("on_memory_updated", memory.slice(0,8), memory[COMPARE_RESULT_ADDRESS], memory[CALL_RETURN_ADDRESS])

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
