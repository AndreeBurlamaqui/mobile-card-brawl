class_name BattleDebug extends CanvasItem

static var instance: BattleDebug
@export var battle_controller: BattleController

#region CARD VARIABLES
@export var hand_reference: Hand
@export var card_types: Array[SymbolData]
#endregion

#region ENEMY VARIABLES
@export var enemy_list: Array[EnemyData]
@export var battle_button_containers: VBoxContainer
#endregion

func _init() -> void:
	instance = self

func _ready() -> void:
	_setup_enemies()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			$FoldableContainer.fold()

#region CARD ACTIONS
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

func get_random_deck(size: int) -> Array[CardData]:
	var deck : Array[CardData] = []
	for i in size:
		var random_type = card_types.pick_random()
		var random_damage = randi_range(1, 5)
		var new_card = CardData.new(random_type, random_damage)
		deck.append(new_card)
	
	return deck
#endregion

#region ENEMY ACTIONS
func _setup_enemies():
	# Clear placeholders
	for child in battle_button_containers.get_children():
		child.queue_free()
	
	for enemy in enemy_list:
		var enemy_battle_button = Button.new()
		enemy_battle_button.text = enemy.alias
		enemy_battle_button.pressed.connect(_start_battle.bind(enemy))
		enemy_battle_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		enemy_battle_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		battle_button_containers.add_child(enemy_battle_button)

func _start_battle(enemy: EnemyData):
	battle_controller.start_battle(enemy)
#endregion


#region BATTLE STATES

func _on_end_win_pressed() -> void:
	battle_controller.end_battle(true)

func _on_end_lose_pressed() -> void:
	battle_controller.end_battle(false)

#endregion
