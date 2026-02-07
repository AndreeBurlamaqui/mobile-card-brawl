class_name BattleController extends Control

enum State { PLAYER_TURN, ENEMY_TURN, VICTORY, DEFEAT }

static var instance: BattleController

@export var enemy_controller: EnemyActionController
@export var player_controller: Hand

var current_state: State = State.PLAYER_TURN
signal state_change(old_state: State, new_state: State)

# ENEMY
var enemy: EnemyData

# PLAYER
var player_hp: int
signal player_hp_change(old_value: int, new_value: int)

func _init() -> void:
	instance = self

func start_battle(against: EnemyData) -> void:
	## Clear current enemy (if any)
	#if enemy != null:
		#
	
	# Setup new enemy and actions
	enemy = against
	enemy_controller.setup(enemy)
	
	# Setup player
	var deck : Array[CardData] = BattleDebug.instance.get_random_deck(30) # TEMP
	player_controller.setup(deck)
	player_hp = 100
	player_hp_change.emit(player_hp, player_hp)

func change_state(new_state: State) -> void:
	state_change.emit(current_state, new_state)
	current_state = new_state
	
	match current_state:
		State.PLAYER_TURN:
			# Enable player actions
			# Give more cards
			player_controller.add_next_deck_card()
		State.ENEMY_TURN:
			await enemy_controller.apply_every_penalties()
			change_state(State.PLAYER_TURN) # Go back to player

func hit_player(value: int) -> void:
	var new_value = player_hp - value
	player_hp_change.emit(player_hp, new_value)
	player_hp = new_value
