class_name MapNodeVisual extends Control

@export var type_label: Label
@export var flip_controller: Flipper

func setup(data: MapGenerator.MapNodeData) -> void:
	_on_encounter_update(data)
	var is_showing = data.state == MapGenerator.MapNodeData.ProgressState.COMPLETED  or data.type.start_showing
	var starting_face = Flipper.FlipState.FACE_UP if is_showing else Flipper.FlipState.FACE_DOWN
	flip_controller.flip_to(starting_face)
	data.encounter_updated.connect(_on_encounter_update.bind(data))

func _on_encounter_update(data: MapGenerator.MapNodeData) -> void:
	type_label.text = data.type.id
	print("Updating encounter: [%.v] {%s}" %[data.grid_pos, data.type])
