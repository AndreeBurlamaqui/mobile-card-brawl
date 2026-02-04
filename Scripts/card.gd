class_name Card extends Control

## Index label that will show the ratio of the card. Debugging Only
@export var indexLabel : Label
## Visual node. Useful to rotate or scale without affecting other stuff unwanted
@export var visual : Control

var curHand: Hand

func initiate(hand: Hand) -> void:
	curHand = hand

func apply() -> void:
	curHand.remove_card(self)
