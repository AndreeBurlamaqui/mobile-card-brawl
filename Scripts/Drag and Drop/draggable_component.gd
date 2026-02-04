class_name DraggableComponent extends Control

## Node you want to copy for the drag preview (usually the parent)
@export var visual : Control
# Root node, will be used on the droppable to transfer data
@export var target : Control

# If true, the original object hides while dragging
@export var _hide_on_drag: bool = true

func _ready() -> void:
	# Auto-find parent if not assigned
	if not target:
		target = get_parent() as Control
	
	if not visual:
		visual = target
	
	# Ensure this component covers the parent so it catches the mouse
	mouse_filter = MouseFilter.MOUSE_FILTER_PASS
	set_anchors_preset(Control.PRESET_FULL_RECT)

# 1. Start Drag
func _get_drag_data(at_position: Vector2) -> Variant:
	if not (target or visual) : return null
	
	# Notify Manager
	DragDropManager.start_drag(self, at_position)
	
	# Update this visual
	if _hide_on_drag:
		target.modulate.a = 0.0 # Fade out instead of hide() to keep layout space
		
	return self # This is the "data" passed to the Droppable

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		# If the drag failed (didn't drop on a valid Droppable)
		if not is_drag_successful():
			DragDropManager.end_drag(false)

func on_drag_failed():
	if _hide_on_drag:
		target.modulate.a = 1.0
