@tool
class_name Hand extends Control

@export_group("Editor")
@export var update_in_editor: bool = true

@export_group("Hand Layout")
## Maximum width the hand is allowed to take up (in pixels).
## For portrait mobile (720px width), 600-650 is usually good.
var max_hand_width: float = 650.0

## The visual curve height. Higher numbers make a steeper arch.
@export var arch_height: float = 40.0

## How much the cards tilt at the edges of the hand (in degrees).
@export var rotation_curve: float = 10.0

## The default spacing between cards if they don't fill the max width.
@export var default_card_spacing: float = 120.0

@export_group("Animation")
## Speed of the card moving to its new position.
@export var anim_speed: float = 0.2

# -- Runtime --
var _cards: Array[Card] = []

func _enter_tree() -> void:
	if Engine.is_editor_hint() :
		return
	
	DebugInstance.hand_reference = self

func _ready() -> void:
	if Engine.is_editor_hint() :
		return
	
	# Clean up any placeholder cards used for editor design
	for child in get_children():
		child.queue_free()
	
	# Initial layout calculation
	call_deferred("update_hand_positions")

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and update_in_editor :
		
		# Sync the internal list with editor children
		_cards.clear()
		for child in get_children():
			if child is Card :
				_cards.append(child)
		
		update_hand_positions()

# Call this whenever you add/remove a card to the hand
func add_card(card: Control) -> void:
	_cards.append(card)
	add_child(card)
	
	# Connect to the card's input signals here if needed (e.g. for selection)
	# card.gui_input.connect(...)
	
	update_hand_positions()

func remove_card(card: Control) -> void:
	if card in _cards:
		_cards.erase(card)
		remove_child(card) # Or queue_free() if destroying it
		update_hand_positions()

# The Core Logic: Calculates where every card should sit visually
func update_hand_positions() -> void:
	var card_count: int = _cards.size()
	if card_count == 0:
		return
	
	# Space cards based on hand width
	var total_width: float = (card_count - 1) * default_card_spacing
	var current_spacing: float = default_card_spacing
	
	if total_width > max_hand_width:
		current_spacing = max_hand_width / max(card_count - 1, 1)
		total_width = max_hand_width
	
	# Get center of the hand 
	var hand_center_x: float = size.x / 2.0
	var start_x: float = hand_center_x - (total_width / 2.0)
	
	for i in range(card_count):
		var card: Card = _cards[i]
		
		# Convert Ratio to Pixels based on Card Size
		var card_offset = card.size * card.pivot_offset_ratio
		var target_pivot_x: float = start_x + (i * current_spacing)
		
		# -- Position X --
		var target_x: float = start_x + (i * current_spacing)
		target_x -= card_offset.x # Ensure position no matter the pivot
		
		# -- Arch Calculation (Y and Rotation) --
		# We normalize the position from -1.0 (left) to 1.0 (right)
		# Center card is 0.0
		var ratio: float = 0
		if card_count > 1:
			ratio = float(i) / float(card_count - 1.0) # 0.0 to 1.0
			ratio = (ratio - 0.5) * 2.0 # -1.0 to 1.0
		card.indexLabel.text = str(ratio)
		
		# Apply an arch function: y = x^2 (Parabola)
		var target_pivot_y = abs(ratio) * arch_height
		
		# Update position and rotation
		var final_pos_x = target_pivot_x - card_offset.x
		var final_pos_y = target_pivot_y - card_offset.y
		var target_pos = Vector2(final_pos_x, final_pos_y)
		var target_rot: float = ratio * rotation_curve
		
		if Engine.is_editor_hint() and update_in_editor:
			# SNAP in editor (Don't use Tweens in _process)
			card.position = target_pos
			card.rotation_degrees = target_rot
		else :
			animate_card_to(card, target_pos, target_rot)

# Helper for smooth tweening
func animate_card_to(card: Card, target_pos: Vector2, target_rot: float) -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Note: We animate 'position' relative to the Hand container
	tween.parallel().tween_property(card, "position", target_pos, anim_speed)
	tween.parallel().tween_property(card, "rotation_degrees", target_rot, anim_speed)
