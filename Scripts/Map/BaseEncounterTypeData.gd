class_name BaseEncounterTypeData extends Resource

@export var id: String = "ROOM"

## Should the encounter card start flipped upside?
## e.g for START and BOSS encounters
@export var start_showing: bool

## The chance of this encounter appearing relative to others.
## e.g., Common = 10.0, Rare = 1.0.
@export var weight: float = 10.0

func start() -> void:
	print("Base encounter started. Please override this method.")
