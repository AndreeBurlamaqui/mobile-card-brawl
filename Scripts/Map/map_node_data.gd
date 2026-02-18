class_name MapNodeData extends RefCounted

var grid_pos: Vector2i
var encounter_type: BaseEncounterTypeData
var outgoing: Array[Vector2i] = []
var _visual_instance: MapNodeVisual = null
var controller: MapGenerator

enum ProgressState { BLOCKED, REACHED, READY, COMPLETED}
var state: ProgressState = ProgressState.BLOCKED
var unlocked_by := Vector2i.MIN

signal encounter_updated

func _init(_map_generator: MapGenerator, _position: Vector2i):
	controller = _map_generator
	grid_pos = _position

func assign_visual(new_visual: MapNodeVisual) -> void:
	_visual_instance = new_visual
	_visual_instance.setup(self)
	_visual_instance.button.long_pressed.connect(GameManager.instance.start_encounter.bind(self))
	_visual_instance.droppable_area.add_validator(_can_drop_torch)
	_visual_instance.droppable_area.on_drop_received.connect(_on_torch_drop_received)

func set_room_progress(new_state: ProgressState) -> void:
	if not controller:
		return
	
	state = new_state
	
	if state == ProgressState.COMPLETED:
		controller._on_room_completed(self)
	
	#  Update visuals
	controller._line_layer.queue_redraw()
	encounter_updated.emit()

func get_center_position() -> Vector2:
	if not _visual_instance:
		return Vector2.ZERO
	
	return _visual_instance.position + (_visual_instance.size / 2.0)

func _can_drop_torch(_draggable: DraggableComponent) -> bool:
	return state == ProgressState.REACHED
	
func _on_torch_drop_received(draggable: DraggableComponent) -> void:
	if _can_drop_torch(draggable): # Safe check
		set_room_progress(ProgressState.READY)
