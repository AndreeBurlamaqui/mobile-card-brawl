class_name Debug extends Node

# -- Dependencies --
@export var hand_reference: Hand
@export var card_types: Array[SymbolData]

# -- Configuration --

func _ready() -> void:
	# Verify dependencies to avoid crashes
	if not hand_reference:
		push_error("DebugInterface: Hand Reference is missing!")
		return
	if not card_types or card_types.is_empty():
		push_error("DebugInterface: Card Scene is missing!")
		return

# -- Debug Actions --

func _on_clear_pressed() -> void:
	var cards = hand_reference.get_children()
	for child in cards:
		if child is Control:
			hand_reference.remove_card(child)
			child.queue_free()


func _on_add_card_pressed() -> void:
	var randomType = card_types.pick_random()
	var new_card := CardData.new(randomType, randi_range(1, 4))
	hand_reference.add_card(new_card)


func _on_remove_card_pressed() -> void:
	var cards = hand_reference.get_children()
	if cards.is_empty() :
		return
	
	# Remove the last card (LIFO)
	var card_to_remove = cards.back()
	hand_reference.remove_card(card_to_remove)
	card_to_remove.queue_free()
