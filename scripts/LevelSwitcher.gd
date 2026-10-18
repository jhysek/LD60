extends Node

var current_level = 0

var opened_levels: int = 0

var levels = [
	"res://levels/level00.tscn",
	"res://levels/level01.tscn",
	"res://levels/finished.tscn"
]

var best = {
	'level0' = {
		ticks = 9999,
		lines = 9999
	}
}


func _ready():
	set_process_input(true)

func _input(event):
	if Input.is_action_just_released("ui_restart"):
		restart_level()
	if Input.is_action_just_released("ui_cancel"):
		Transition.switchTo("res://scenes/menu.tscn")

	if Input.is_key_pressed(KEY_N) and Input.is_key_pressed(KEY_SHIFT):
		next_level()

func get_current_level():
	return levels[current_level]

func restart_level():
	start_level()

func start_level():
	if opened_levels < current_level + 1:
		opened_levels = current_level + 1
	Transition.switchTo(levels[current_level])

func next_level():
	current_level += 1

	if current_level < levels.size():
		if opened_levels < current_level + 1:
			opened_levels = current_level + 1
		start_level()
		
func set_score(level, ticks, lines):
	var key = "level" + str(level)
	if !best.has(key):
		best[key] = { ticks = 9999, lines = 9999}

	if best[key].ticks > ticks:
		best[key].ticks = ticks
		
	if best[key].lines > ticks:
		best[key].lines = ticks
