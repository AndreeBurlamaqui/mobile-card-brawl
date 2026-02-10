class_name HoldButton extends TextureButton

## Fired when the hold is completed successfully
signal long_pressed

@export_category("Settings")
## How long (in seconds) the user must hold the button
@export var hold_time: float = 1.5
## If true, the progress resets instantly on release. If false, it rewinds.
@export var instant_reset: bool = true

@export_category("Visuals")
## Reference to the progress bar child (assign in inspector or uses auto-find)
@export var progress_bar: TextureProgressBar
## Optional: Tween scale on success
@export var success_scale: Vector2 = Vector2(1.1, 1.1)

# Internal state
var _current_hold_time: float = 0.0
var _is_holding: bool = false
var _fired: bool = false
var _tween: Tween

func _ready() -> void:
	if not progress_bar:
		push_error("HoldButton: No TextureProgressBar found!")
		return
	
	# Setup initial state
	progress_bar.max_value = 100
	progress_bar.value = 0
	
	# Connect button signals
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_exited.connect(_on_button_up) # Focus loss

func _process(delta: float) -> void:
	if _is_holding:
		if _fired:
			progress_bar.value = 100
			return
		else:
			_current_hold_time += delta
			
			var ratio = _current_hold_time / hold_time
			progress_bar.value = ratio * 100
			
			if _current_hold_time >= hold_time:
				_complete_hold()
	elif not _is_holding and not instant_reset and progress_bar.value > 0:
		# Smooth rewind visual
		progress_bar.value = move_toward(progress_bar.value, 0, delta * 300)

func _on_button_down() -> void:
	_is_holding = true
	_fired = false
	_current_hold_time = 0.0
	
	# Cancel any rewinding tweens
	if _tween: _tween.kill()

func _on_button_up() -> void:
	_is_holding = false
	_current_hold_time = 0.0
	
	if instant_reset:
		progress_bar.value = 0

func _complete_hold() -> void:
	_fired = true
	
	# Emit the signal
	long_pressed.emit()
	
	# Pop effect
	_play_success_animation()

func _play_success_animation() -> void:
	if _tween: _tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Scale up and down
	pivot_offset = size / 2
	scale = Vector2.ONE # Reset first
	_tween.tween_property(self, "scale", success_scale, 0.1)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.2)
