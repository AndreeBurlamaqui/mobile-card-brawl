extends Panel

@export var action_container: FlowContainer
@export var action_template: PackedScene

@export var actions: Array[EnemyAction]

func _ready() -> void:
	# Remove design placeholders
	for child in action_container.get_children():
		child.queue_free()
	
	for i in range(actions.size()) :
		var new_action = action_template.instantiate() as EnemyActionVisual
		var action_data = actions[i]
		new_action.set_data(action_data)
		
		# By setting the stretch ratio we make that actions that are "stronger" bigger
		new_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		new_action.size_flags_stretch_ratio = action_data.amount
		
		action_container.add_child(new_action)
