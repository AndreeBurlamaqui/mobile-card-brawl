class_name MapNodeVisual extends Control

@export var type_label: Label

func setup(data: MapGenerator.MapNodeData) -> void:
	_on_encounter_update(data)
	data.encounter_updated.connect(_on_encounter_update.bind(data))

func _on_encounter_update(data: MapGenerator.MapNodeData) -> void:
	type_label.text = data.type
	print("Updating encounter ", data.type)
