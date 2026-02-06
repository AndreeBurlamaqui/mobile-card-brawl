class_name BattleController extends Control

@export var enemy_actions_controller: EnemyActionController

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
	enemy_actions_controller.setup(enemy)

func hit_player(value: int) -> void:
	player_hp -= value
