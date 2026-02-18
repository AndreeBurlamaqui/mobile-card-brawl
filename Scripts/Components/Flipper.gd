## Script that will tween the object to flip like a card
extends Node

@export_category("Groups")
@export var front_group: Control
@export var back_group: Control

@export_category("Settings")
@export var animation_duration: float = 0.15
@export var start_face_up: bool = false

@export var target_root: Control

var is_face_up: bool = false
var is_flipping: bool = false

signal card_flipped(is_up: bool)

func _ready() -> void:
	# Initialize state
	is_face_up = start_face_up
	_update_texture()

func flip() -> void:
	# Prevent spamming the flip while it's already animating
	if is_flipping: return
	
	is_flipping = true
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE) 
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(target_root, "scale:x", 0.0, animation_duration / 2)
	tween.tween_callback(_toggle_face_state)
	tween.tween_property(target_root, "scale:x", 1.0, animation_duration / 2)
	
	await tween.finished
	
	is_flipping = false
	card_flipped.emit(is_face_up)

func _toggle_face_state() -> void:
	is_face_up = !is_face_up
	_update_texture()

func _update_texture() -> void:
	front_group.visible = is_face_up
	front_group.set_process(is_face_up)
	
	back_group.visible = not is_face_up
	back_group.set_process(not is_face_up)

# -- INPUT TESTING (Remove later) --
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		flip()
