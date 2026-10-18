extends CanvasLayer

signal on_btn_play
signal on_btn_step
signal on_btn_stop

var stats = {
	ticks = 0,
	lines = 0
}

func _on_btn_play_pressed() -> void:
	emit_signal("on_btn_play")


func _on_btn_step_pressed() -> void:
	emit_signal("on_btn_step")


func _on_btn_stop_pressed() -> void:
	emit_signal("on_btn_stop")
	
func refresh_stats():
	$ControlPanel/Screen/Stats.text = "LINES: " + str(stats.lines) + "\n\nTICKS: " + str(stats.ticks)

func update_ticks_stats(ticks):
	stats.ticks = ticks
	refresh_stats()

func refresh_memory(memory):
	for i in range(8):
		var node_name = "%02d" % i
		if $ControlPanel/Memory.has_node(node_name):
			$ControlPanel/Memory.get_node(node_name).text = "%02d: %d" % [i, memory[i]]
	
func _on_punch_tape_on_program_updated(lines: Variant) -> void:
	stats.lines = lines
	refresh_stats()
	
