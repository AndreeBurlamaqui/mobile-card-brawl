class_name BattleController extends CanvasLayer

enum State { PLAYER_TURN, ENEMY_TURN, VICTORY, DEFEAT }

static var instance: BattleController

@export var enemy_controller: EnemyActionController
@export var player_controller: Hand

@export_category("UI")
@export var alias_label: RichTextLabel
@export var enemy_hp: ProgressBar
var _hp_tween: Tween

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
	alias_label.text = str(enemy.alias)
	var enemy_action_count = enemy.actions.size()
	enemy_hp.min_value = 0
	enemy_hp.max_value = enemy_action_count
	_update_enemy_bar(enemy.actions.size())
	
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
	var left_challenges = enemy_controller.get_challenge_left()
	await _update_enemy_bar(left_challenges)
	
	# Check if game should finish
	if left_challenges <= 0:
		end_battle(true)

func _update_enemy_bar(left_challenges: int) -> void:
	if _hp_tween != null and _hp_tween.is_running():
		_hp_tween.kill()
	
	_hp_tween = create_tween()
	_hp_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BOUNCE)
	_hp_tween.tween_property(enemy_hp, "value", left_challenges, 0.25)
	await _hp_tween.finished
