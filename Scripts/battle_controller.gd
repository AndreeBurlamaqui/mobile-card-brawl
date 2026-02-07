class_name BattleController extends Control

enum State { PLAYER_TURN, ENEMY_TURN, VICTORY, DEFEAT }

@export var enemy_controller: EnemyActionController
@export var player_controller: Hand

var current_state: State = State.PLAYER_TURN
signal state_change(old_state: State, new_state: State)

# ENEMY
var enemy: EnemyData

# PLAYER
var player_hp: int

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

func change_state(new_state: State) -> void:
	state_change.emit(current_state, new_state)
	current_state = new_state
	
	match current_state:
		State.PLAYER_TURN:
			# Enable player actions
			# Give more cards
			player_controller.add_next_deck_card()
		State.ENEMY_TURN:
			enemy_controller.apply_every_penalties(self)

func hit_player(value: int) -> void:
	player_hp -= value
