extends Control

@export_category("Map Settings")
@export var data: LevelMapData
## To make room positioning uneven, without respecting the grid too much
@export var _position_jitter: float = 25.0

@export_category("References")
@export var _scroller: ScrollContainer
@export var _line_layer: Control
@export var _rooms_layer: Control
@export var _grid_slots: GridContainer
@export var _encounter_node: PackedScene

# Data Class
class MapNodeData:
	var grid_pos: Vector2i
	var type: String = "ROOM" # TEMP
	var outgoing: Array[Vector2i] = []
	var visual_instance: Control = null
	
	func _init(p): grid_pos = p

var _grid_data: Array = [] # 2D array [row][col]

func _ready() -> void:
	if not data:
		push_error("MapGenerator: No Level Data assigned!")
		return
	
	# Create the level map
	_generate_grid_data()
	_assign_room_types()
	
	# Create all the slots to be the base position of the room visual
	_create_slots()
	
	# Wait 2 frames to ensure the ScrollContainer has calculated sizes
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Spawn room/encounter visuals
	_spawn_visuals()
	
	# Draw connecting Lines
	_line_layer.draw.connect(_on_line_layer_draw)
	_line_layer.queue_redraw()
	
	# Scroll to (Start)
	# call_deferred to ensure the scrollbar max_value is updated
	call_deferred("_scroll_to_bottom")

func _scroll_to_bottom() -> void:
	_scroller.scroll_vertical = _scroller.get_v_scroll_bar().max_value

func _generate_grid_data() -> void:
	_grid_data.clear()
	seed(Time.get_unix_time_from_system()) # TODO: Add option for custom seed
	
	var height = data.grid_height
	var width = data.grid_width
	
	# Init Empty Grid
	for r in range(height):
		var row = []
		for c in range(width): row.append(null)
		_grid_data.append(row)

	# Pick a random column for the single start node
	var start_col = randi() % width
	var start_node = MapNodeData.new(Vector2i(0, start_col))
	start_node.type = "START"
	_grid_data[0][start_col] = start_node

	# Create branches
	for r in range(height - 2):
		_connect_rooms(r)

	# Final Boss
	var boss_row = height - 1
	var boss_col = floor(width / 2.0)
	var boss = MapNodeData.new(Vector2i(boss_row, boss_col))
	boss.type = "BOSS"
	_grid_data[boss_row][boss_col] = boss
	
	# Connect Pre-Boss row to Boss
	for c in range(width):
		var node = _grid_data[boss_row - 1][c]
		if node: node.outgoing.append(boss.grid_pos)

func _connect_rooms(row_idx: int) -> void:
	# It'll either connect to the next (upwards) or the neighbours (sides)
	var next_row = row_idx + 1
	var width = data.grid_width
	
	# In case it's deadend: ensure that it's not going to break the path
	var active_nodes_indices: Array[int] = []
	for column in range(width):
		if _grid_data[row_idx][column] != null:
			active_nodes_indices.append(column)
	# Pick one that will guarantee to never be a deadend
	var guaranteed_survivor_col = active_nodes_indices.pick_random()
	
	for column in range(width):
		var node = _grid_data[row_idx][column]
		if not node: continue
		
		# Check deadends first
		var isnt_survivor = column != guaranteed_survivor_col # never should be deadend
		var isnt_start = row_idx > 0 # if it's not the START
		if isnt_survivor and isnt_start and data.is_deadend():
			var side_targets = []
			if column > 0 and _grid_data[row_idx][column-1] != null:
				# Left Neighbour
				side_targets.append(column - 1)
			if column < width - 1 and _grid_data[row_idx][column+1] != null: 
				# Right Neighbour
				side_targets.append(column + 1)
			
			if side_targets.size() > 0:
				var target_c = side_targets.pick_random()
				# Connect to neighbor in SAME row
				node.outgoing.append(Vector2i(row_idx, target_c))
				continue # Valid deadend, no upward path
		
		# Define valid moves (Left, Center, Right)
		var targets = []
		if column > 0:
			# Check if can go left, to not cross connection lines 
			var crossing: bool = false
			
			var left_neighbor = _grid_data[row_idx][column - 1]
			if left_neighbor:
				for connection in left_neighbor.outgoing:
					if connection.x == next_row and connection.y == column:
						crossing = true
						break
			
			if not crossing:
				targets.append(column - 1)
		
		# No need to check crossing when going center
		targets.append(column)
		
		# No need to check right. The neighbor will be checking if so
		if column < width - 1: 
			targets.append(column + 1)
		
		targets.shuffle()
		
		# TODO: Make this be a data from the level
		# So we can set that the level 1 has only 1 start path
		# Row 0 (Start) must branch into at least 2 paths if possible
		var path_count = 1
		if row_idx == 0: path_count = 2
		elif randf() > 0.7: path_count = 2 # 30% chance to branch
		
		for i in range(min(path_count, targets.size())):
			var t_col = targets[i]
			var t_pos = Vector2i(next_row, t_col)
			
			if not node.outgoing.has(t_pos):
				node.outgoing.append(t_pos)
			
			if _grid_data[next_row][t_col] == null:
				# Create node if it doesn't exist yet
				_grid_data[next_row][t_col] = MapNodeData.new(t_pos)

func _assign_room_types() -> void:
	var height = data.grid_height
	var width = data.grid_width
	
	# Skip Start (Row 0) and Boss (Row height-1)
	for row in range(1, height - 1):
		for column in range(width):
			var node = _grid_data[row][column]
			if not node: continue
			
			# Set room type
			var base_type = data.pick_weighted_room_type()
			
			# In case it's an enemy, check tier
			if base_type == "MOB":
				if data.is_elite():
					node.type = "ELITE"
				else:
					node.type = "MOB"
			else:
				node.type = base_type

func _create_slots() -> void:
	# Fill GridContainer with spacers to define the "perfect grid" positions
	# Setup grid
	for child in _grid_slots.get_children(): child.queue_free() # Remove placeholders
	_grid_slots.columns = data.grid_width # Ensure it'll be like data
	
	# Instantiate and insta delete encounter node so we get the slot size
	var temp_instance = _encounter_node.instantiate() as Control
	var spacer_size = temp_instance.custom_minimum_size
	temp_instance.free()
	
	# GridContainer fills Top-Left to Bottom-Right
	# [0]=Bottom. We iterate REVERSE row index.
	var height = data.grid_height
	var width = data.grid_width
	for row in range(height - 1, -1, -1):
		for column in range(width):
			var spacer = Panel.new() # TEMP to see what's happening BTS
			
			# Setup spacer
			spacer.custom_minimum_size = spacer_size
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
			
			# Debug purposes
			spacer.name = "Anchor_%d_%d" % [row, column]
			spacer.modulate.a = 0.15
			
			_grid_slots.add_child(spacer)

func _spawn_visuals() -> void:
	var height = data.grid_height
	var width = data.grid_width
	
	for row in range(height):
		for column in range(width):
			var data = _grid_data[row][column]
			if not data: continue
			
			# Get the slot
			var anchor_idx = (height - 1 - row) * width + column
			var anchor = _grid_slots.get_child(anchor_idx)
			
			# Add jitter offset to look less like a grid
			var offset = _get_position_jitter(row, column, width)
			
			# Finish setup
			var center_pos = anchor.position + (anchor.size / 2.0)
			var vis = _encounter_node.instantiate()
			_rooms_layer.add_child(vis)
			
			vis.position = center_pos + offset - (vis.size / 2.0)
			
			data.visual_instance = vis
			_setup_visual_appearance(vis, data)

func _get_position_jitter(row: int, column: int, width: int) -> Vector2:
	# Don't jitter special nodes
	var type = _grid_data[row][column].type
	if type == "START" or type == "BOSS": return Vector2.ZERO
	
	var max_x = _position_jitter
	var min_x = _position_jitter * -1
	
	# Wall Constraints
	if column == 0: min_x = 0.0
	if column == width - 1: max_x = 0.0
	
	# Neighbor Constraints
	if column > 0 and _grid_data[row][column - 1] != null:
		min_x = max(min_x, 5.0)
	if column < width - 1 and _grid_data[row][column + 1] != null:
		max_x = min(max_x, -5.0)
	
	var j_x = 0.0
	if min_x < max_x: j_x = randf_range(min_x, max_x)
	else: j_x = lerp(min_x, max_x, 0.5)
	
	return Vector2(j_x, randf_range(_position_jitter * -1, _position_jitter))

func _setup_visual_appearance(vis, data):
	# TEMP: We'll move it to the encounter visual later
	var lbl = vis.get_node("Panel/Label")
	lbl.text = data.type
	match data.type:
		"START": vis.modulate = Color.GREEN
		"BOSS": vis.modulate = Color.RED
		"ELITE": vis.modulate = Color.DARK_MAGENTA
		"CAMP": vis.modulate = Color.FOREST_GREEN
		"CHEST": vis.modulate = Color.GOLD
		"EVENT": vis.modulate = Color.VIOLET
		"MOB": vis.modulate = Color.WHITE

func _on_line_layer_draw() -> void:
	var height = data.grid_height
	var width = data.grid_width
	
	for row in range(height):
		for column in range(width):
			var start_node = _grid_data[row][column]
			if not start_node or not start_node.visual_instance: continue
			
			var start_pos = start_node.visual_instance.position + (start_node.visual_instance.size / 2.0)
			
			for target_grid in start_node.outgoing:
				var end_node = _grid_data[target_grid.x][target_grid.y]
				if end_node and end_node.visual_instance:
					var end_pos = end_node.visual_instance.position + (end_node.visual_instance.size / 2.0)
					
					# TEMP: Straight line. Change to texture later
					_line_layer.draw_line(start_pos, end_pos, Color.WHITE, 4.0, true)
