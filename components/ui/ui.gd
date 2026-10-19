extends CanvasLayer

signal on_btn_play
signal on_btn_step
signal on_btn_stop
signal on_bpm_changed(bpm)

var stats = {
	ticks = 0,
	lines = 0
}

func _ready():
	load_program()
		
func _on_btn_play_pressed() -> void:
	Sfx.play("BtnClick")
	hide_man()
	emit_signal("on_btn_play")


func _on_btn_step_pressed() -> void:
	Sfx.play("BtnClick")
	emit_signal("on_btn_step")


func _on_btn_stop_pressed() -> void:
	Sfx.play("BtnClick")
	show_man()
	emit_signal("on_btn_stop")
	
func refresh_stats():
	$ControlPanel/Screen/Stats.text = "LINES: " + str(stats.lines) + "\n\nTICKS: " + str(stats.ticks)

func update_ticks_stats(ticks):
	stats.ticks = ticks
	refresh_stats()

func raw_program():
	return $PunchTape.program.program

func load_program():
	var best = LevelSwitcher.get_score_for(LevelSwitcher.current_level)
	if best:
		print("BEST for this level: ", best)
		$PunchTape.load_program(best.program)
	else:
		print("not finished...")
	
func refresh_memory(memory, cmp, ret, cnt_idx):
	for i in range(8):
		var node_name = "%02d" % i
		if $ControlPanel/Memory.has_node(node_name):
			$ControlPanel/Memory.get_node(node_name).text = "%02d: %d" % [i, memory[i]]
			if i == cnt_idx: 
				$ControlPanel/Memory.get_node(node_name).text = "%02d> %d" % [i, memory[i]]
			
	$ControlPanel/Memory/CMP.text = "CMP: " + str(cmp)
	$ControlPanel/Memory/RET.text = "RET: %2d" % ret
	
func _on_punch_tape_on_program_updated(lines: Variant) -> void:
	stats.lines = lines
	refresh_stats()
	
func show_man():
	$Manual.open()
	
func hide_man():
	$Manual.open()

func filter_instructions(instructions):
	$Manual.filter_instructions(instructions)

func _on_h_slider_value_changed(value: float) -> void:
	emit_signal("on_bpm_changed", $ControlPanel/HSlider.value)
	$ControlPanel/HSlider/Label.text = str(value) + " BPM"
