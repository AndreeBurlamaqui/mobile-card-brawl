class_name EnemyData extends Resource

class EnemyActionConfig:
	@export var symbol: SymbolData
	@export var required_amount: int = 10
	@export var penalty_damage: int = 2

@export var alias: String = "Goblin"
## List of boxes to spawn. For now it'll just use classes
@export var actions: Array[EnemyActionData]
