extends Node

signal on_tick(time, ticks)

@export var bpm = 90
var tick_cooldown = 0
var running = false
var time = 0
var ticks = 0

func _ready():
	pass
	
func start():
	time = 0
	ticks = 0
	running = true
	set_process(true)
	
func stop():
	running = false
	time = 0
	ticks = 0
	set_process(false)
	
func pause():
	running = false
	
func resume():
	running = true
	
func set_bpm(new_bpm):
	bpm = new_bpm
	
func _process(delta):
	if running:
		time += delta
		tick_cooldown -= delta
		
		if tick_cooldown <= 0:
			ticks += 1
			tick()
			tick_cooldown = 60.0 / float(bpm)
			

func tick():
	emit_signal("on_tick", time, ticks)
	
