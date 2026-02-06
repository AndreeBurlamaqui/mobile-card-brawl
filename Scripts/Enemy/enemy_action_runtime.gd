class_name EnemyActionRuntime extends RefCounted

var data: EnemyActionData
var current_amount: int

# Signal so the Visual knows when to update immediately
signal challenge_update(old_amount: int, new_amount: int)
signal challenge_cleared
signal challenge_penalty

func _init(action: EnemyActionData):
	data = action
	current_amount = data.required_amount

func take_hit(amount: int) -> void:
	var new_amount = current_amount - amount
	
	challenge_update.emit(current_amount, new_amount)
	
	current_amount = new_amount
	if current_amount == 0:
		challenge_cleared.emit()

func is_cleared() -> bool:
	return current_amount <= 0

func apply_penalty(battle: BattleController) -> void:
	# Will be the base of actions. For now will jsut damage on fail
	battle.hit_player(data.damage_on_fail)
	challenge_penalty.emit()
