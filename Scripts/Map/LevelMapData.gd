class_name LevelMapData extends Resource

@export_group("Grid Structure")
@export var grid_height: int = 15
@export_range(1, 5) var grid_width: int = 5
## Chance that a node will connect to 2 nodes in the next row instead of 1
@export_range(0.0, 100.0) var _branch_chance: float = 30
## Chance that a path simply merges into a neighbor lane instead of moving up
@export_range(0.0, 100.0) var _deadend_merge_chance: float = 1

@export_group("Encounters")
@export var _possible_encounters : Array[BaseEncounterTypeData] = []
@export var start_encounter: BaseEncounterTypeData
@export var boss_encounter: EnemyEncounterData

# Helper to get a random room type based on weights
func get_random_encounter() -> BaseEncounterTypeData:
	if _possible_encounters.is_empty():
		push_warning("LevelMapData: No encounters defined!")
		return null

	# 1. Calculate total weight
	var total_weight: float = 0.0
	for encounter in _possible_encounters:
		total_weight += encounter.weight

	# 2. Pick a random number within that range
	var roll: float = randf_range(0.0, total_weight)

	# 3. Find which encounter corresponds to that roll
	var current_weight: float = 0.0
	for encounter in _possible_encounters:
		current_weight += encounter.weight
		if roll <= current_weight:
			return encounter
	
	# Fallback (should theoretically not happen due to math, but safe to have)
	return _possible_encounters.front()

func is_deadend() -> bool:
	return randf() < (_deadend_merge_chance / 100.0)
