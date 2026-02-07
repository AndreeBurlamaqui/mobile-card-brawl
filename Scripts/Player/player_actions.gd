extends Node

@export var deck_count: Label
@export var hp_bar: ProgressBar

var hp_tween: Tween

func _ready() -> void:
	BattleController.instance.player_controller.deck_change.connect(_on_deck_change)
	BattleController.instance.player_hp_change.connect(_on_player_hp_change)

func _on_pass_pressed() -> void:
	BattleController.instance.change_state(BattleController.State.ENEMY_TURN)

func _on_deck_change(deck: Array[CardData]) -> void:
	deck_count.text = str(deck.size())

func _on_player_hp_change(old_value: int, new_value: int) -> void:
	hp_bar.value = old_value
	
	if hp_tween != null and hp_tween.is_running():
		hp_tween.kill()
	
	hp_tween = create_tween()
	hp_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	hp_tween.tween_property(hp_bar, "value", new_value, 0.15)
