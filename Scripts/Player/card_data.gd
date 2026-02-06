class_name CardData extends Resource

@export var type: SymbolData

@export var value: int = 1 # TEMP: Later cards will have its own action

func _init(symbol: SymbolData, damage: int) -> void:
	type = symbol
	value = damage
