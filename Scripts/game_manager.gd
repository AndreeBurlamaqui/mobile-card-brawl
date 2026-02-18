class_name GameManager extends Node2D
static var instance : GameManager

enum Scene { MAP, BATTLE}
@export var map_scene : CanvasLayer
@export var battle_scene : BattleController
var current_scene : Scene

var cur_map_node: MapNodeData

func _ready() -> void:
	instance = self
	_change_scene(Scene.MAP)

func _change_scene(new_scene: Scene) -> void:
	current_scene = new_scene
	
	var is_on_map = new_scene == Scene.MAP
	map_scene.visible = is_on_map
	map_scene.set_process(is_on_map)
	
	var is_on_battle = new_scene == Scene.BATTLE
	battle_scene.visible = is_on_battle
	battle_scene.set_process(is_on_battle)

func end_battle(enemy: EnemyData, endState: bool) -> void:
	# Give reward by enemies
	
	# Update map node
	if endState:
		# WIN
		cur_map_node.set_room_progress(MapNodeData.ProgressState.COMPLETED)
	else:
		# LOSE
		cur_map_node.set_room_progress(MapNodeData.ProgressState.REACHED)
	
	# Go back to map
	_change_scene(Scene.MAP)

func restart() -> void:
	get_tree().call_deferred("reload_current_scene")

func start_encounter(data: MapNodeData) -> void:
	print("Starting encounter of node [%.v] %s" %[data.grid_pos, data.encounter_type.id])
	_change_scene(Scene.BATTLE)
	cur_map_node = data
	data.encounter_type.start()
