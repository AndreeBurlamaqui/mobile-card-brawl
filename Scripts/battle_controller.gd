extends Control


func _droppable_on_hover_enter(draggable: DraggableComponent) -> void:
	modulate.a = 0.5


func _droppable_on_hover_exit() -> void:
	modulate.a = 1


func _droppable_on_drop_received(draggable: DraggableComponent) -> void:
	modulate.a = 1
	if draggable.target is Card :
		var cardUsed = draggable.target as Card
		cardUsed.apply()
