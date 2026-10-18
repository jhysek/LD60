extends Node2D

var ProgramInterpreter = preload("res://scripts/program_interpreter.gd")
var interpreter = null
var parsed_program = []
var stats = {
	lines = 0,
	ticks = 0
}

@onready var punch_tape = $UI/PunchTape
@onready var clock = $Clock
@onready var bg = $Bg
@onready var run_music = $TrackrPlayer
var stepping = false

func _ready():
	interpreter = ProgramInterpreter.new()
	interpreter.on_program_ended.connect(_on_program_ended)
	interpreter.on_program_error.connect(_on_program_error)
		
	Transition.openScene()
	initialize_actors()
	$UI/Printout.start()
	
func _process(delta):
	bg.rotation += delta * 0.02
	
func initialize_actors():
	for actor in get_tree().get_nodes_in_group("Actor"):
		interpreter.on_actor_instruction.connect(actor.perform_instruction)
		actor.on_exit_reached.connect(exit_reached)
		actor.memory_store_request.connect(interpreter.store_to_memory)
	
func exit_reached(actor):
	actor.fade_out()
	_on_program_ended()
	LevelSwitcher.set_score(LevelSwitcher.current_level, stats.ticks, stats.lines)
	LevelSwitcher.next_level()

	
func _on_clock_on_tick(time: Variant, ticks: Variant) -> void:
	punch_tape.set_interpreted_line(interpreter.current_line)
	interpreter.tick()
	update_stats_ticks()
	print("TICK #" + str(ticks))
	
func _on_program_ended() -> void:
	if stepping: 
		return
		
	print("PROGRAM FINISHED")
	punch_tape.set_interpreted_line(null)
	clock.stop()

func _on_program_error(line, message) -> void:
	print("PROGRAM ERROR on line " + str(line) + ": " + message)
	punch_tape.set_interpreter_error(line, message)
	clock.stop()


func _on_btn_play_pressed() -> void:
	var parsed = punch_tape.parse_program()
	interpreter.init_program(parsed)
	punch_tape.set_interpreted_line(0)
	punch_tape.hide_editor_indicators()
	$World.reset()
	run_music.start_external()
	clock.start()

func update_stats_lines(lines):
	stats.lines = lines
	refresh_stats()
	
func update_stats_ticks():
	stats.ticks = clock.ticks
	refresh_stats()
	
func refresh_stats():
	$UI/ControlPanel/Screen/Stats.text = "LINES: " + str(stats.lines) + "\n\nTICKS: " + str(stats.ticks)

func _on_btn_stop_pressed() -> void:
	run_music.stop()
	punch_tape.set_interpreted_line(null)
	$World.reset()
	clock.stop()
	stepping = false
	
func _on_punch_tape_on_program_updated(lines: Variant) -> void:
	update_stats_lines(lines)
	

func _on_clock_on_mid_tick() -> void:
	run_music.tick()

func _on_btn_step_pressed() -> void:
	if !stepping:
		var parsed = punch_tape.parse_program()
		interpreter.init_program(parsed)
		punch_tape.set_interpreted_line(0)
		punch_tape.hide_editor_indicators()
		$World.reset()
		stepping = true
		
	punch_tape.set_interpreted_line(interpreter.current_line)
	interpreter.tick()
