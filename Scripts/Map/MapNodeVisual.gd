class_name MapNodeVisual extends Control

@export var type_label: Label
@export var flip_controller: Flipper
@export var droppable_area: DroppableComponent
@export var button: HoldButton

func setup(data: MapNodeData) -> void:
	if not data:
		return
	
	_on_encounter_update(data)
	data.encounter_updated.connect(_on_encounter_update.bind(data))

func _on_encounter_update(data: MapNodeData) -> void:
	print("Updating encounter: [%.v] {%s}" %[data.grid_pos, data.encounter_type.id])
	
	type_label.text = data.encounter_type.id
	
	var is_showing = data.state == MapNodeData.ProgressState.READY  or data.encounter_type.start_showing
	var starting_face = Flipper.FlipState.FACE_UP if is_showing else Flipper.FlipState.FACE_DOWN
	flip_controller.flip_to(starting_face)
	
	button.set_interactable(data.state == MapNodeData.ProgressState.READY)

func _on_droppable_hover_enter(draggable: DraggableComponent) -> void:
	modulate.a = 0.5

func _on_droppable_hover_exit() -> void:
	modulate.a = 1

func _on_droppable_drop_received(draggable: DraggableComponent) -> void:
	modulate.a = 1
