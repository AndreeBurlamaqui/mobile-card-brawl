class_name DroppableComponent extends Control

signal on_drop_received(draggable: DraggableComponent)
signal on_hover_enter(draggable: DraggableComponent)
signal on_hover_exit

var _validators: Array[Callable] = []

func _ready() -> void:
	mouse_filter = MouseFilter.MOUSE_FILTER_PASS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	DragDropManager.register_droppable(self)

func _exit_tree() -> void:
	DragDropManager.unregister_droppable(self)

## Adds a check. MUST return bool and take 1 argument (draggable).
func add_validator(checker_func: Callable) -> void:
	_validators.append(checker_func)

func remove_validator(checker_func: Callable) -> void:
	_validators.erase(checker_func)

func can_accept(draggable: DraggableComponent) -> bool:
	# If no validators exist, 
	# then the only check is that it's a droppable
	if _validators.is_empty():
		return true
	
	for check in _validators:
		if check && not check.call(draggable):
			return false # This check don't accept the draggable
	
	return true
