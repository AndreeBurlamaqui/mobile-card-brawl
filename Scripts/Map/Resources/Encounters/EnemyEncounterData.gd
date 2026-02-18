class_name EnemyEncounterData extends BaseEncounterTypeData

@export var enemy: EnemyData

func start() -> void:
	# Example: controller has a function to switch to battle view
	# controller.start_battle(enemy_name, enemy_difficulty)
	print("Starting Battle against: ", enemy.alias)
	GameManager.instance.battle_scene.start_battle(enemy)
