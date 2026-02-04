class_name DroppableComponent extends Control

signal on_drop_received(draggable: DraggableComponent)
signal on_hover_enter(draggable: DraggableComponent)
signal on_hover_exit

func _ready() -> void:
	mouse_filter = MouseFilter.MOUSE_FILTER_PASS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	DragDropManager.register_droppable(self)

func _exit_tree() -> void:
	DragDropManager.unregister_droppable(self)
