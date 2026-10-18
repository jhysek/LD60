extends Node2D

var ProgramInterpreter = preload("res://scripts/program_interpreter.gd")
var interpreter = null
var parsed_program = []

@onready var punch_tape = $UI/PunchTape
@onready var clock = $Clock
@onready var bg = $Bg
@onready var run_music = $TrackrPlayer
@export_multiline var briefing = ""
@export var current_level = 0

var stepping = false

func win_condition_satisfied():
	print("CHECKING CONDITION FOR LEVEL: ", LevelSwitcher.current_level)
	
	match LevelSwitcher.current_level:
		0: 
			return null
		1: 
			return $World/Objects/WallTerminal.value == $World/Objects/Computer.value && $World/Objects/WallTerminal.value != 0
		2: 
			return $World/Objects/WallTerminal.value == ($World/Objects/Computer.value + 10) && $World/Objects/WallTerminal.value != 0
		3: 
			return $World/Objects/ComputerA.value + $World/Objects/ComputerB.value == $World/Objects/TargetComputer.value && $World/Objects/TargetComputer.value != 0
		4:
			return $World/Objects/WallTerminal.value == ($World/Objects/Computer.value + $World/Objects/Computer2.value + $World/Objects/Computer3.value + $World/Objects/Computer4.value) && $World/Objects/WallTerminal.value != 0
		5:
			var sum = 0
			for obj in $World/Objects.get_children():
				if obj.is_in_group("DataSource"):
					sum += obj.value
			return sum == 0
	return false
	
func _ready():
	$LeaveTimer.wait_time = 2
	randomize()
	interpreter = ProgramInterpreter.new()
	interpreter.on_program_ended.connect(_on_program_ended)
	interpreter.on_program_error.connect(_on_program_error)
	interpreter.on_memory_updated.connect(_on_memory_updated)
		
	Transition.openScene()
	initialize_actors()
	initialize_objects()
	$UI/Printout.start(briefing)
	$UI.on_bpm_changed.connect(_on_bpm_changed)
	
func _process(delta):
	bg.rotation += delta * 0.02
	
func initialize_actors():
	for actor in get_tree().get_nodes_in_group("Actor"):
		interpreter.on_actor_instruction.connect(actor.perform_instruction)
		actor.on_exit_reached.connect(exit_reached)
		actor.memory_store_request.connect(interpreter.store_to_memory)
	
func initialize_objects():
	for obj in get_tree().get_nodes_in_group("Objects"):
		if obj.is_in_group("DataSource"):
			obj.on_value_updated.connect(_on_data_source_updated)
		
func exit_reached(actor):
	var win = win_condition_satisfied()
	if win == null || win:
		actor.fade_out()
		won()
	else:
		failed()

func failed():
	_on_btn_stop_pressed()

func won():
	var stats = $UI.stats
	clock.stop()
	LevelSwitcher.set_score(LevelSwitcher.current_level, stats.ticks, stats.lines)
	$LeaveTimer.start()
	
func _on_clock_on_tick(time: Variant, ticks: Variant) -> void:
	punch_tape.set_interpreted_line(interpreter.current_line)
	interpreter.tick()
	$UI.update_ticks_stats(ticks)
	if win_condition_satisfied():

		won()
	
func _on_program_ended() -> void:
	if stepping: 
		return
		
	print("PROGRAM FINISHED")
	punch_tape.set_interpreted_line(null)
	clock.stop()
	
	if win_condition_satisfied():
		won()

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
			
func _on_btn_stop_pressed() -> void:
	run_music.stop()
	punch_tape.set_interpreted_line(null)
	$World.reset()
	clock.stop()
	stepping = false
	
func _on_clock_on_mid_tick() -> void:
	run_music.tick()

func _on_btn_step_pressed() -> void:
	if !stepping:
		var parsed = punch_tape.parse_program()
		interpreter.init_program(parsed)
		punch_tape.set_interpreted_line(0)
		punch_tape.hide_editor_indicators()
		interpreter.clear_memory()
		$World.reset()
		stepping = true
		
	punch_tape.set_interpreted_line(interpreter.current_line)
	interpreter.tick()
	
func _on_memory_updated(memory, cmp, ret, counter_idx):
	print("UPDATED MEMORY")
	$UI.refresh_memory(memory, cmp, ret, counter_idx)
	
func _on_data_source_updated(new_value):
	print("DATA SOURCE UPDATED TO: ", new_value)
	if win_condition_satisfied():
		won()
		
func _on_bpm_changed(new_bpm):
	print("CLOCK NEW BPM: ", new_bpm)
	clock.set_bpm(new_bpm)

func _on_leave_timer_timeout() -> void:
	LevelSwitcher.next_level()
