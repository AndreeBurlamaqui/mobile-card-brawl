extends Node

signal drag_started(draggable: DraggableComponent)
signal drag_ended(draggable: DraggableComponent, success: bool)

# -- Configuration --
var drag_drop_canvas: CanvasLayer
var drag_speed: float = 35
var shadow_offset := Vector2(0, 15)

# -- State --
var current_drag: DraggableComponent = null
var current_visual: Control = null
var current_shadow: Control = null
var drag_offset: Vector2 = Vector2.ZERO

var _all_droppables: Array[DroppableComponent] = []
var _last_hovered_droppable: DroppableComponent = null

func _ready() -> void:
	# Create canvas to show what's being dragged
	drag_drop_canvas = CanvasLayer.new()
	drag_drop_canvas.layer = 100 # Ensure it's above everything else
	add_child(drag_drop_canvas)

func register_droppable(drop: DroppableComponent) -> void:
	if not drop in _all_droppables:
		_all_droppables.append(drop)
		print("Dropped registered: ", drop.name)

func unregister_droppable(drop: DroppableComponent) -> void:
	_all_droppables.erase(drop)

func _input(event: InputEvent) -> void:
	if current_drag and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_try_drop()

func _process(delta: float) -> void:
	if current_visual:
		# Move the visual to follow the mouse
		var mouse_pos = get_viewport().get_mouse_position()
		var lerpTime = (1 - cos(PI * (delta * drag_speed))) / 2 #ease in-out
		current_visual.global_position = current_visual.global_position.lerp(mouse_pos - drag_offset, lerpTime)
		
		if current_shadow:
			current_shadow.global_position = current_visual.global_position + shadow_offset
	
	# Search for droppable zones
	if current_drag:
		var mouse_pos = get_viewport().get_mouse_position()
		var found = get_droppable_at_position(mouse_pos)
		
		# 3. Handle Hover States
		if found != _last_hovered_droppable:
			if is_instance_valid(_last_hovered_droppable):
				_last_hovered_droppable.on_hover_exit.emit()
			
			if is_instance_valid(found):
				found.on_hover_enter.emit(current_drag)
			
			print("Focus Drop Change: %s -> %s" % [str(_last_hovered_droppable), str(found)])
			_last_hovered_droppable = found

func get_droppable_at_position(screen_pos: Vector2) -> DroppableComponent:
	for droppable in _all_droppables:
		if not droppable.is_visible_in_tree():
			continue
		
		# Check collision manually
		var dropRect = droppable.get_global_rect()
		if dropRect.has_point(screen_pos):
			return droppable
	
	return null

func start_drag(draggable: DraggableComponent) -> void:
	current_drag = draggable
	
	# Store original visual info
	var original_size = current_drag.visual.size
	var original_pos = current_drag.visual.global_position
	var final_scale = current_drag.visual.scale * 1.35
	
	# Duplicate the Visual
	current_visual = current_drag.visual.duplicate(8) # 8 use instantiate()
	current_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_visual.set_anchors_preset(Control.PRESET_TOP_LEFT) # Neutral layout
	current_visual.size = original_size
	drag_offset = original_size * current_visual.pivot_offset_ratio + current_visual.pivot_offset
	
	# Create the shadow for "lifting effect"
	current_shadow = current_visual.duplicate(8)
	current_shadow.modulate = Color(0, 0, 0, 0.4)
	current_shadow.rotation = 0
	current_shadow.scale = final_scale
	
	# Prepare tweening
	var pickTween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	pickTween.tween_property(current_visual, "rotation", 0, 0.15)
	pickTween.tween_property(current_visual, "scale", final_scale, 0.2)
	
	# Finish setup
	shadow_parallax.add_child(current_shadow)
	drag_drop_canvas.add_child(current_visual)
	
	# Start position for tweening
	current_visual.global_position = original_pos
	current_shadow.global_position = original_pos
	
	pickTween.play()
	draggable.on_drag_started()
	drag_started.emit(draggable)

func _try_drop() -> void:
	var success = false
	if _last_hovered_droppable:
		_last_hovered_droppable.on_drop_received.emit(current_drag)
		success = true
	end_drag(success)

func end_drag(success: bool = false) -> void:
	if not current_drag:
		return
	
	var drag_dropped = current_drag
	if not success:
		# Quick tween it back to og pos
		var lastVisual = current_visual
		var initial_position = drag_dropped.target.global_position
		var move_back_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		move_back_tween.tween_property(lastVisual, "global_position", initial_position, 0.25)
		await move_back_tween.finished
	
	drag_dropped.on_drag_ended()
	current_visual.queue_free()
	current_shadow.queue_free()
	drag_ended.emit(drag_dropped, success)
	current_drag = null
	_last_hovered_droppable = null
