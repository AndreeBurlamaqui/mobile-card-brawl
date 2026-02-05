## This creates a parallax on UI. Moving every children of the attached Node
## It'll use either the cursor in desktop or accelerator in mobile
class_name Parallax extends Control

@export var max_offset: Vector2
@export var smoothing: float = 2.0

func _process(delta: float) -> void:
	var center: Vector2 = get_viewport_rect().size / 2.0
	var dist = _get_parallax_distance(center)
	var offset: Vector2 = dist / center
	
	# Clamp to ensure we never overshoot even if mouse leaves window
	offset = offset.clamp(Vector2(-1, -1), Vector2(1, 1))
	var target_pos: Vector2 = max_offset * -offset
	
	position = position.lerp(target_pos, smoothing * delta)

func _get_parallax_distance(center: Vector2) -> Vector2:
	
	if OS.has_feature("mobile"):
		var gravity = Input.get_gravity()
		# Normalize gravity (roughly 9.8 m/s) to -1.0 to 1.0 range
		var x_tilt = (gravity.x / 9.8) * smoothing
		var y_tilt = (gravity.y / 9.8) * smoothing
		
		# Invert Y because tilting phone "forward" (negative Y) should look "up"
		var tilt_vector = Vector2(x_tilt, -y_tilt)
		
		# Multiply by center to fake a pixel distance (like mouse)
		# effectively saying "The tilt is at this pixel coordinate"
		return tilt_vector * center
	
	return get_global_mouse_position() - center
