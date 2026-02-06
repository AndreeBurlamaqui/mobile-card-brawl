class_name EnemyActionVisual extends Control

@export var icon: TextureRect
@export var label: Label
@export var droppable_area: DroppableComponent

func _ready() -> void:
	droppable_area.on_hover_enter.connect(_on_droppable_hover_enter)
	droppable_area.on_hover_exit.connect(_on_droppable_hover_exit)
	droppable_area.on_drop_received.connect(_on_droppable_drop_received)

func setup(action: EnemyActionRuntime):
	icon.texture = action.data.type.icon
	action.challenge_update.connect(_on_challenge_update)
	action.challenge_cleared.connect(_on_challenge_cleared)
	_on_challenge_update(0, action.current_amount) # Initial value

func _on_challenge_update(old_value: int, new_value: int) -> void:
	# TODO: Add animation value changing from old to new
	label.text = str(new_value)

func _on_challenge_cleared() -> void:
	pass

func _on_droppable_hover_enter(draggable: DraggableComponent) -> void:
	modulate.a = 0.5

func _on_droppable_hover_exit() -> void:
	modulate.a = 1

func _on_droppable_drop_received(draggable: DraggableComponent) -> void:
	# Reset hover
	modulate.a = 1.0
