extends Control

@onready var volume_control
@onready var button

@export var hover_color = Color("ffffffff")
@export var opened_color = Color("ffffffff")
@export var closed_color = Color("ffffff7e")

var opened = false

func _ready():
	volume_control = $MusicVolumeControl
	button = $TextureButton
	
func _on_h_slider_value_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(bus_index, $HSlider.value / 100.0)

func _on_texture_button_pressed() -> void:
	opened = not opened
	volume_control.visible = opened
	
	if opened:
		button.self_modulate = opened_color
	else:
		button.self_modulate = closed_color

func _on_texture_button_mouse_entered() -> void:
	button.self_modulate = hover_color
	
func _on_texture_button_mouse_exited() -> void:
	if opened:
		button.self_modulate = opened_color
	else:
		button.self_modulate = closed_color
