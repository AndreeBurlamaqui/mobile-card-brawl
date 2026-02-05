class_name DraggableComponent extends Control

## Node you want to copy for the drag preview (usually the parent)
@export var visual : Control
## Root node, will be used on the droppable to transfer data
@export var target : Control
## If true, the original object hides while dragging
@export var _hide_on_drag: bool = true

func _ready() -> void:
	# Auto-find parent if not assigned
	if not target: target = get_parent() as Control
	if not visual: visual = target
	
	# Ensure this component covers the parent so it catches the mouse
	mouse_filter = MouseFilter.MOUSE_FILTER_PASS
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			DragDropManager.start_drag(self)

# Drag states called by manager
func on_drag_started():
	if _hide_on_drag: target.modulate.a = 0.0

func on_drag_ended():
	if _hide_on_drag: target.modulate.a = 1.0
