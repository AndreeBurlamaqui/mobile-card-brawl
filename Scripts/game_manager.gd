class_name GameManager extends Node2D
static var instance : GameManager

enum Scene { MAP, BATTLE}
@export var map_scene : CanvasLayer
@export var battle_scene : CanvasLayer

var cur_map_node: MapGenerator.MapNodeData

func _ready() -> void:
	instance = self
	_change_scene(Scene.MAP)

func _change_scene(new_scene: Scene) -> void:
	var is_on_map = new_scene == Scene.MAP
	map_scene.visible = is_on_map
	map_scene.set_process(is_on_map)
	
	var is_on_battle = new_scene == Scene.BATTLE
	battle_scene.visible = is_on_battle
	battle_scene.set_process(is_on_battle)

func start_battle(data: MapGenerator.MapNodeData) -> void:
	_change_scene(Scene.BATTLE)
	cur_map_node = data

func end_battle(enemy: EnemyData, endState: bool) -> void:
	# Give reward by enemies
	
	# Update map node
	if endState:
		# WIN
		cur_map_node.set_room_progress(MapGenerator.MapNodeData.ProgressState.COMPLETED)
	else:
		# LOSE
		cur_map_node.set_room_progress(MapGenerator.MapNodeData.ProgressState.REACHED)
	
	# Go back to map
	_change_scene(Scene.MAP)
