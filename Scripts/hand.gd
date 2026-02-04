class_name Hand extends Control

@export_group("References")
@export var card_placement: HBoxContainer

@export_group("Hand Layout")
## The visual curve height. Higher numbers make a steeper arch.
@export var arch_height: float = 40.0
## How much the cards tilt at the edges of the hand (in degrees).
@export var rotation_curve: float = 10.0

@export_group("Animation")
## Speed of the card moving to its new position.
@export var anim_speed: float = 0.2

# -- Runtime --
var _cards: Array[Card] = []
var _ghosts: Array[Control] = []

func _ready() -> void:
	# Clean up any placeholder cards used for editor design
	for child in get_children():
		if child is Card: child.queue_free()
	for child in card_placement.get_children():
		child.queue_free()
	
	# This was crashing. TODO: check it later if it's needed
	## Connect to resize so we re-calculate if the screen size changes
	#resized.connect(func(): reorder_hand())

# Call this whenever you add/remove a card to the hand
func add_card(card: Control) -> void:
	_cards.append(card)
	add_child(card)
	
	# Create Ghost
	var newGhost = Panel.new()
	_ghosts.append(newGhost)
	card_placement.add_child(newGhost)
	
	# Wait one frame for the HBox to sort the ghost, then refresh
	get_tree().process_frame.connect(reorder_hand, CONNECT_ONE_SHOT)

func remove_card(card: Control) -> void:
	var index = _cards.find(card)
	if index != -1:
		_cards.remove_at(index)
		card.queue_free()
		
		var ghost = _ghosts[index]
		_ghosts.remove_at(index)
		ghost.queue_free()
		
		# Wait one frame for HBox to collapse, then refresh
		get_tree().process_frame.connect(reorder_hand, CONNECT_ONE_SHOT)

## The "Refresh" method. Call this manually to validate design or update layout.
## It calculates the ideal position for every card and Tweens them there.
func reorder_hand() -> void:
	if _cards.is_empty(): return
	
	# Force HBox to update its layout immediately so we get correct Ghost positions
	card_placement.queue_sort() 
	await get_tree().process_frame
	
	# With new ghost placements. We can now check if they should update width
	_update_ghost_widths()
	await get_tree().process_frame
	
	# 3. Calculate and Apply Positions
	for i in range(_cards.size()):
		if i >= _ghosts.size(): break # Safe check. Shouldn't happen
		
		var card = _cards[i]
		var ghost = _ghosts[i]
		
		# Ghost position conversion to local
		var ghost_screen_pos = ghost.global_position
		var target_pos = get_global_transform().affine_inverse() * ghost_screen_pos
		
		# Center Alignment correction
		target_pos.x += ghost.size.x / 2.0 # Ghost is Top-Left, we want Center-Bottom
		target_pos.y += ghost.size.y / 2.0       # Baseline
		
		# Arch Logic
		var ratio: float = 0.0
		if _cards.size() > 1:
			ratio = float(i) / float(_cards.size() - 1)
			ratio = (ratio - 0.5) * 2.0
		
		var arch_y = abs(ratio) * arch_height
		target_pos.y += arch_y
		
		# Pivot correction
		var pivot_pixels = card.size * card.pivot_offset_ratio
		target_pos -= pivot_pixels
		
		var target_rot = ratio * rotation_curve
		
		# 4. Apply (Tween or Snap)
		if Engine.is_editor_hint():
			card.global_position = target_pos
			card.visual.rotation_degrees = target_rot
		else:
			_animate_card_to(card, target_pos, target_rot)

func _animate_card_to(card: Card, target_pos: Vector2, target_rot: float) -> void:
	# Kill existing tweens on this card so we don't fight
	if card.has_meta("moving_card_tween"):
		var t = card.get_meta("moving_card_tween") as Tween
		if t and t.is_valid(): t.kill()
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "position", target_pos, anim_speed)
	tween.parallel().tween_property(card.visual, "rotation_degrees", target_rot, anim_speed)
	
	# Store reference to kill it later if needed
	card.set_meta("moving_card_tween", tween)

## Check ghost width. If it's out of bounds
func _update_ghost_widths() -> void:
	if _ghosts.is_empty(): return
	
	var total_cards = _cards.size()
	var available_width = card_placement.size.x
	var card_real_width = _cards[0].custom_minimum_size.x
	var fixed_separation = card_placement.get_theme_constant("separation")
	
	# Check if current amount of cards is overflowing
	var total_needed = (total_cards * card_real_width) + ((total_cards - 1) * fixed_separation)
	var is_overflowing = total_needed > available_width
	
	for ghost in _ghosts:
		if is_overflowing:
			# Squeeze. Godot will automatically set the size
			ghost.custom_minimum_size.x = 0
			ghost.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			# Center and set width based on card. We keep all cards together this way
			ghost.custom_minimum_size.x = card_real_width
			ghost.size_flags_horizontal = Control.SIZE_FILL
