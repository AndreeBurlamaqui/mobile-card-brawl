extends Panel

@export var action_container: FlowContainer
@export var action_template: PackedScene

var _current_enemy: EnemyData
var _current_actions: Array[EnemyActionRuntime] = []

func setup(enemy: EnemyData):
	# Remove design placeholders
	for child in action_container.get_children():
		child.queue_free()
	
	_current_enemy = enemy
	for action in _current_enemy.actions:
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
	new_action.size_flags_stretch_ratio = data.amount
	
	new_action.droppable_area.on_drop_received.connect( _on_action_targeted.bind(runtime_data))
	
	action_container.add_child(new_action)

func _on_action_targeted(draggable: DraggableComponent, action: EnemyActionRuntime ) -> void:
	if draggable.target is not CardVisual:
		return
	
	var used_card: CardVisual = draggable.target
	if used_card.curData.type != action.data.type:
		return
	
	var player_damage = used_card.apply()
	action.take_hit(player_damage)
