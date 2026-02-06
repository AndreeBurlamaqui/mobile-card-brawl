class_name CardVisual extends Control

## Index label that will show the ratio of the card. Debugging Only
@export var indexLabel : Label
## Visual node. Useful to rotate or scale without affecting other stuff unwanted
@export var visual : Control
@export var icon : TextureRect
@export var amount_label : Label

# TEMP
var curHand: Hand
var curData: CardData
#

func setup(data: CardData, hand: Hand) -> void:
	curData = data
	curHand = hand
	
	icon.texture = data.type.icon
	amount_label.text = str(data.value)

func apply() -> int:
	curHand.remove_card(self)
	return curData.value # TEMP: Return the amount of damage made by this card
