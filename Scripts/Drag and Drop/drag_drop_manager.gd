extends Node

signal drag_started(draggable: DraggableComponent)
signal drag_ended(draggable: DraggableComponent)

# -- Configuration --
var drag_drop_canvas: CanvasLayer
var drag_speed: float = 35

# -- State --
var current_drag: Control = null
var current_visual: Control = null
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Create canvas to show what's being dragged
	drag_drop_canvas = CanvasLayer.new()
	drag_drop_canvas.layer = 100 # Ensure it's above everything else
	add_child(drag_drop_canvas)

func _process(delta: float) -> void:
	if current_visual:
		# Move the visual to follow the mouse
		var mouse_pos = get_viewport().get_mouse_position()
		var lerpTime = (1 - cos(PI * (delta * drag_speed))) / 2 #ease in-out
		current_visual.global_position = current_visual.global_position.lerp(mouse_pos - drag_offset, lerpTime)

func start_drag(draggable: DraggableComponent, offset: Vector2) -> void:
	current_drag = draggable
	
	# Duplicate the Visual
	current_visual = current_drag.visual.duplicate(8) # 8 use instantiate()
	current_visual.global_position = current_drag.global_position
	drag_offset = current_visual.size * current_visual.pivot_offset_ratio + current_visual.pivot_offset
	create_tween().tween_property(current_visual, "rotation", 0, 0.15)
	
	drag_drop_canvas.add_child(current_visual)
	drag_started.emit(draggable)

func end_drag(success: bool = false) -> void:
	if not current_drag:
		return
	
	var drag_dropped = current_drag
	if not success:
		# Quick tween it back to og pos
		var lastVisual = current_visual
		var initial_position = drag_dropped.target.global_position
		var move_back_tween = create_tween()
		move_back_tween.tween_property(lastVisual, "global_position", initial_position, 0.15)
		await move_back_tween.finished
	
	drag_dropped.on_drag_failed()
	_finish_drag()

func _finish_drag() -> void:
	current_visual.queue_free()
	drag_ended.emit(current_drag)
	current_drag = null
