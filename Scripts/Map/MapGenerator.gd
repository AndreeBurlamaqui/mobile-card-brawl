extends Control

@export_category("Map Settings")
@export var grid_height: int = 15 # TODO: Change to level data
@export var grid_width: int = 5 # TODO: Change to level data
## To make room positioning uneven, without respecting the grid too much
@export var position_jitter: float = 25.0

@export_category("References")
@export var scroller: ScrollContainer
@export var line_layer: Control
@export var rooms_layer: Control
@export var grid_slots: GridContainer
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
	# Create the level map
	_generate_data()
	
	# Create all the slots to be the base position of the room visual
	_create_slots()
	
	# Wait 2 frames to ensure the ScrollContainer has calculated sizes
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Spawn room/encounter visuals
	_spawn_visuals()
	
	# Draw connecting Lines
	line_layer.draw.connect(_on_line_layer_draw)
	line_layer.queue_redraw()
	
	# Scroll to (Start)
	# call_deferred to ensure the scrollbar max_value is updated
	call_deferred("_scroll_to_bottom")

func _scroll_to_bottom() -> void:
	scroller.scroll_vertical = scroller.get_v_scroll_bar().max_value

# ==============================================================================
# DATA GENERATION
# ==============================================================================
func _generate_data() -> void:
	_grid_data.clear()
	seed(Time.get_unix_time_from_system()) # TODO: Add option for custom seed
	
	# Init Empty Grid
	for r in range(grid_height):
		var row = []
		for c in range(grid_width): row.append(null)
		_grid_data.append(row)

	# Pick a random column for the single start node
	var start_col = randi() % grid_width
	var start_node = MapNodeData.new(Vector2i(0, start_col))
	start_node.type = "START"
	_grid_data[0][start_col] = start_node

	# Create branches
	for r in range(grid_height - 2):
		_connect_row_upwards(r)

	# Final Boss
	var boss_row = grid_height - 1
	var boss_col = floor(grid_width / 2.0)
	var boss = MapNodeData.new(Vector2i(boss_row, boss_col))
	boss.type = "BOSS"
	_grid_data[boss_row][boss_col] = boss
	
	# Connect Pre-Boss row to Boss
	for c in range(grid_width):
		var node = _grid_data[boss_row - 1][c]
		if node: node.outgoing.append(boss.grid_pos)

func _connect_row_upwards(row_idx: int) -> void:
	var next_row = row_idx + 1
	for c in range(grid_width):
		var node = _grid_data[row_idx][c]
		if not node: continue
		
		# Define valid moves (Left, Center, Right)
		var targets = []
		if c > 0: targets.append(c - 1)
		targets.append(c)
		if c < grid_width - 1: targets.append(c + 1)
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
				_grid_data[next_row][t_col] = MapNodeData.new(t_pos)

func _create_slots() -> void:
	# Fill GridContainer with spacers to define the "perfect grid" positions
	# Get node size
	
	# Setup grid
	for child in grid_slots.get_children(): child.queue_free() # Remove placeholders
	grid_slots.columns = grid_width # Ensure it'll be like data
	
	# Instantiate and insta delete encounter node so we get the slot size
	var temp_instance = _encounter_node.instantiate() as Control
	var spacer_size = temp_instance.custom_minimum_size
	temp_instance.free()
	
	# GridContainer fills Top-Left to Bottom-Right
	# [0]=Bottom. We iterate REVERSE row index.
	for r in range(grid_height - 1, -1, -1):
		for c in range(grid_width):
			var spacer = Panel.new()
			
			# Setup spacer
			spacer.custom_minimum_size = spacer_size
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
			
			# Debug purposes
			spacer.name = "Anchor_%d_%d" % [r, c]
			spacer.modulate.a = 0.15
			
			grid_slots.add_child(spacer)

func _spawn_visuals() -> void:
	for r in range(grid_height):
		for c in range(grid_width):
			var data = _grid_data[r][c]
			if not data: continue
			
			# Get the slot
			var anchor_idx = (grid_height - 1 - r) * grid_width + c
			var anchor = grid_slots.get_child(anchor_idx)
			
			# Add jitter offset to look less like a grid
			var offset = Vector2.ZERO
			if data.type != "START" and data.type != "BOSS":
				# Start with full range
				var min_x = -position_jitter
				var max_x = position_jitter
				
				# Ensure it'll not go outside viewport
				if c == 0:
					# First column: Never go left of center (0)
					min_x = 0.0
				if c == grid_width - 1:
					# Last column: Never go right of center (0)
					max_x = 0.0
				
				# Ensure it'll not overlap with other rooms
				if c > 0 and _grid_data[r][c-1] != null:
					# If neighbor to the left, try to stay to the right (+5)
					min_x = max(min_x, 5.0)
				if c < grid_width - 1 and _grid_data[r][c+1] != null:
					# If neighbor to the right, try to stay to the left (-5)
					max_x = min(max_x, -5.0)
				
				var jitter_x = 0.0
				
				if min_x < max_x:
					# If we are squeezed (e.g., Wall says >0 but Neighbor says <-5),
					# we default to 0 (Center) to be safe.
					jitter_x = randf_range(min_x, max_x)
				else:
					# The constraints conflict or are tight (e.g., between wall and neighbor)
					# Just pick the average or 0
					jitter_x = lerp(min_x, max_x, 0.5)
				
				var jitter_y = randf_range(-position_jitter, position_jitter)
				offset = Vector2(jitter_x, jitter_y)
			
			# Finish setup
			var center_pos = anchor.position + (anchor.size / 2.0)
			var vis = _encounter_node.instantiate()
			rooms_layer.add_child(vis)
			
			vis.position = center_pos + offset - (vis.size / 2.0)
			
			data.visual_instance = vis
			_setup_visual_appearance(vis, data)

func _setup_visual_appearance(vis, data):
	# TEMP: We'll move it to the encounter visual later
	var lbl = vis.get_node("Panel/Label")
	lbl.text = data.type
	if data.type == "BOSS": vis.modulate = Color.RED
	elif data.type == "START": vis.modulate = Color.GREEN

func _on_line_layer_draw() -> void:
	for r in range(grid_height):
		for c in range(grid_width):
			var start_node = _grid_data[r][c]
			if not start_node or not start_node.visual_instance: continue
			
			var start_pos = start_node.visual_instance.position + (start_node.visual_instance.size / 2.0)
			
			for target_grid in start_node.outgoing:
				var end_node = _grid_data[target_grid.x][target_grid.y]
				if end_node and end_node.visual_instance:
					var end_pos = end_node.visual_instance.position + (end_node.visual_instance.size / 2.0)
					
					# TEMP: Straight line. Change to texture later
					line_layer.draw_line(start_pos, end_pos, Color.WHITE, 4.0, true)
