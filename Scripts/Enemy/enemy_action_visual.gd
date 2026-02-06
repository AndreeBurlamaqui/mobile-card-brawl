class_name EnemyActionVisual extends Control

@export var icon: TextureRect
@export var label: Label

func set_data(data: EnemyAction):
	icon.texture = data.symbol
	label.text = str(data.amount)
