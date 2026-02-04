class_name DroppableComponent extends Control

signal on_drop_received(draggable: DraggableComponent)
signal on_hover_enter(draggable: DraggableComponent)
signal on_hover_exit

func _ready() -> void:
	mouse_filter = MouseFilter.MOUSE_FILTER_PASS
	set_anchors_preset(Control.PRESET_FULL_RECT)

# 1. Can we drop here?
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# 'data' is the return value from _get_drag_data (the DraggableComponent instance)
	var draggable = data as DraggableComponent
	
	if draggable:
		on_hover_enter.emit(draggable)
		return true
	return false

# 2. Receive Drop
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var draggable = data as DraggableComponent
	if draggable:
		# Notify the slot logic
		on_drop_received.emit(draggable)
		
		# Notify the manager the drag is done
		DragDropManager.end_drag(true)
