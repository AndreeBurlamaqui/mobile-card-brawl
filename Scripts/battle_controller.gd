class_name BattleController extends CanvasLayer

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
	player_hp = 100 # Player HP per session

func start_battle(against: EnemyData) -> void:
	# Setup new enemy and actions
	enemy = against
	enemy_controller.setup(enemy)
	for action in enemy_controller.current_actions:
		action.challenge_cleared.connect(_on_enemy_challenge_cleared)
	
	# Setup player
	var deck : Array[CardData] = BattleDebug.instance.get_random_deck(30) # TEMP
	player_controller.setup(deck)
	player_hp_change.emit(player_hp, player_hp)

func change_state(new_state: State) -> void:
	state_change.emit(current_state, new_state)
	current_state = new_state
	
	if enemy_controller.is_round_cleared():
		# Enemy died, stop battle
		end_battle(true)
		return
	
	match current_state:
		State.PLAYER_TURN:
			if player_hp <= 0:
				return # Game is ending
			
			# Enable player actions
			# Give more cards
			player_controller.add_next_deck_card()
		State.ENEMY_TURN:
			await enemy_controller.apply_every_penalties()
			
			if player_hp <= 0:
				return # Game is ending
			
			change_state(State.PLAYER_TURN) # Go back to player

func hit_player(value: int) -> void:
	var new_value = player_hp - value
	player_hp_change.emit(player_hp, new_value)
	player_hp = new_value
	
	if player_hp <= 0:
		await get_tree().create_timer(1).timeout
		GameManager.instance.restart()

func end_battle(is_win: bool) -> void:
	GameManager.instance.end_battle(enemy, is_win)

func _on_enemy_challenge_cleared() -> void:
	# Check if game should finish
	if enemy_controller.is_round_cleared():
		end_battle(true)
