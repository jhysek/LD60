extends Node2D

var ProgramInterpreter = preload("res://scripts/program_interpreter.gd")
var interpreter = null
var parsed_program = []

@onready var punch_tape = $UI/PunchTape
@onready var clock = $Clock

func _ready():
	interpreter = ProgramInterpreter.new()
	interpreter.on_program_ended.connect(_on_program_ended)
	interpreter.on_program_error.connect(_on_program_error)
		
	Transition.openScene()
	initialize_actors()
	$Printout.start()
	
func initialize_actors():
	for actor in get_tree().get_nodes_in_group("Actor"):
		interpreter.on_actor_instruction.connect(actor.perform_instruction)

func _on_clock_on_tick(time: Variant, ticks: Variant) -> void:
	punch_tape.set_interpreted_line(interpreter.current_line)
	interpreter.tick()
	print("TICK #" + str(ticks))
	
func _on_program_ended() -> void:
	print("PROGRAM FINISHED")
	punch_tape.set_interpreted_line(null)
	clock.stop()

func _on_program_error(line, message) -> void:
	print("PROGRAM ERROR on line " + str(line) + ": " + message)
	punch_tape.set_interpreter_error(line, message)
	clock.stop()


func _on_btn_play_pressed() -> void:
	var parsed = punch_tape.parse_program()
	print(str(parsed))
	interpreter.init_program(parsed)
	punch_tape.set_interpreted_line(0)
	punch_tape.hide_editor_indicators()
	clock.start()


func _on_btn_stop_pressed() -> void:
	punch_tape.set_interpreted_line(null)
	clock.stop()
	
