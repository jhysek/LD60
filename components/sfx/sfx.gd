extends Node

func play(name, pitch = null):
	if has_node(name):
		var player = get_node(name)
		if pitch:
			player.pitch_scale = pitch
		player.play()
