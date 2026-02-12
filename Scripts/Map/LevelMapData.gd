class_name LevelMapData extends Resource

@export_group("Grid Structure")
@export var grid_height: int = 15
@export_range(1, 5) var grid_width: int = 5
## Chance that a node will connect to 2 nodes in the next row instead of 1
@export_range(0.0, 100.0) var _branch_chance: float = 30
## Chance that a path simply merges into a neighbor lane instead of moving up
@export_range(0.0, 100.0) var _deadend_merge_chance: float = 1

# TEMP: Later this will be modular for each data
@export_group("Room Weights")
@export var weight_mob: int = 50
@export var weight_camp: int = 15
@export var weight_chest: int = 10
@export var weight_event: int = 25

@export_group("Enemy Specifics")
## If a room is a MOB, chance it becomes an ELITE
@export_range(0.0, 100.0) var _elite_chance: float = 15
@export var _possible_enemies : Array[EnemyData] = []

# Helper to get a random room type based on weights
func pick_weighted_room_type() -> String:
	var total_weight = weight_mob + weight_camp + weight_chest + weight_event
	var roll = randi() % total_weight
	
	if roll < weight_mob: return "MOB"
	roll -= weight_mob
	
	if roll < weight_camp: return "CAMP"
	roll -= weight_camp
	
	if roll < weight_chest: return "CHEST"
	
	return "EVENT"

func is_deadend() -> bool:
	return randf() < (_deadend_merge_chance / 100.0)

func is_elite() -> bool:
	return randf() < (_elite_chance / 100.0)

func get_random_enemy() -> EnemyData:
	return _possible_enemies.pick_random()
