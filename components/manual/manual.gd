extends Panel

func _ready():
	position.x = -205
	open()

func _on_item_list_item_selected(index: int) -> void:
	var description = Instruction.DESCRIPTIONS[index + 1]

	$Panel/Instruction.text = $ItemList.get_item_text(index)
	$Panel/Description.text = description

func select_index(idx):
	$ItemList.select(idx)

func open():
	var tween = get_tree().create_tween()
	$Button.text = "hide"
	tween.tween_property(self, 'position', Vector2(0, position.y), 0.5).set_trans(Tween.TRANS_EXPO)

func close():
	var tween = get_tree().create_tween()
	$Button.text = "manual"
	tween.tween_property(self, 'position', Vector2(-205, position.y), 0.5).set_trans(Tween.TRANS_EXPO)


func _on_button_pressed() -> void:
	if position.x < -10:
		open()
	else:
		close()

func filter_instructions(instructions): 
	for i in range(16):
		$ItemList.set_item_disabled(i, true)
		
	for i in instructions:
		$ItemList.set_item_disabled(i, false)
		
