class_name EnemyActionController extends Panel

@export var action_container: FlowContainer
@export var action_template: PackedScene

var _current_actions: Array[EnemyActionRuntime] = []

func setup(enemy: EnemyData):
	# Remove design placeholders
	for child in action_container.get_children():
		child.queue_free()
	
	_current_actions.clear()
	for action in enemy.actions:
		_add_action(action)

func _add_action(data: EnemyActionData):
	# Prepare runtime data
	var runtime_data = EnemyActionRuntime.new(data)
	_current_actions.append(runtime_data)
	
	# Prepare visual side
	var new_action = action_template.instantiate() as EnemyActionVisual
	new_action.setup(runtime_data)
	
	# By setting the stretch ratio we make that actions that are "stronger" bigger
	new_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_action.size_flags_vertical = Control.SIZE_EXPAND_FILL
	new_action.size_flags_stretch_ratio = data.required_amount * 100
	
	new_action.droppable_area.on_drop_received.connect( _on_action_targeted.bind(runtime_data))
	new_action.droppable_area.add_validator(_can_action_be_targeted.bind(runtime_data))
	
	action_container.add_child(new_action)

func _can_action_be_targeted (draggable: DraggableComponent, action: EnemyActionRuntime ) -> bool:
	if draggable.target is not CardVisual:
		return false # Whats being dropped is not a card
	
	var used_card: CardVisual = draggable.target
	if used_card.curData.type != action.data.type:
		return false # Not the same symbol type
	
	return true # Nothing is blocking it. So it can

func _on_action_targeted(draggable: DraggableComponent, action: EnemyActionRuntime ) -> void:
	if not _can_action_be_targeted(draggable, action):
		return # Double check
	
	var player_damage = (draggable.target as CardVisual).apply()
	action.take_hit(player_damage)

func apply_every_penalties() -> void:
	if _current_actions.is_empty():
		return
	
	for action in _current_actions:
		if action.is_cleared():
			continue
		
		action.apply_penalty()
		await get_tree().create_timer(1).timeout

func is_round_cleared() -> bool:
	for action in _current_actions:
		if not action.is_cleared():
			return false
	return true
