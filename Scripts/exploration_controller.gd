class_name ExplorationController extends Node

@export var torch_symbol: SymbolData
@export var player_hand: Hand


func _ready() -> void:
	if not torch_symbol:
		return
	
	# Fill array with starting torch count
	var starting_torches : Array[CardData]
	for i in range(30): # TEMP
		var torch_card := CardData.new(torch_symbol, 1)
		starting_torches.append(torch_card)
		print("Adding torch %d %s" %[i, torch_card.type.id])
	
	player_hand.setup(starting_torches)
