## Script that will tween the object to flip like a card
class_name Flipper extends Node

@export_category("Groups")
@export var front_group: Control
@export var back_group: Control

@export_category("Settings")
@export var animation_duration: float = 0.15
@export var start_face_up: bool = false

@export var target_root: Control

enum FlipState {FACE_UP, FLIPPING, FACE_DOWN}
var _current_flip_state: FlipState

signal card_flipped(is_up: bool)

func _ready() -> void:
	# Initialize state
	_current_flip_state = FlipState.FACE_UP if start_face_up else FlipState.FACE_DOWN
	_update_texture(_current_flip_state == FlipState.FACE_UP)

func flip_to(face: FlipState) -> void:
	if _current_flip_state == face:
		return # Same face
	
	if _current_flip_state == FlipState.FLIPPING:
		return # Animation in progress
	
	_current_flip_state = FlipState.FLIPPING
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK) 
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(target_root, "scale:x", 0.0, animation_duration * 0.5)
	tween.tween_callback(_update_texture.bind(face == FlipState.FACE_UP))
	tween.tween_property(target_root, "scale:x", 1.0, animation_duration * 0.5)
	
	await tween.finished
	
	_current_flip_state = face
	card_flipped.emit(_current_flip_state)

func toggle_flip() -> void:
	var toggled_face = FlipState.FACE_DOWN if _current_flip_state == FlipState.FACE_UP else FlipState.FACE_UP
	flip_to(toggled_face)

func _update_texture(is_face_up: bool) -> void:
	front_group.visible = is_face_up
	front_group.set_process(is_face_up)
	
	back_group.visible = not is_face_up
	back_group.set_process(not is_face_up)

# -- INPUT TESTING (Remove later) --
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_flip()
