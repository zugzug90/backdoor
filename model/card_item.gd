
extends "res://model/card_ref.gd"

class SlotItem:
	const WEAPON = 0
	const SUIT = 1
	const ACCESSORY  = 2

export(int, "WEAPON", "SUIT", "ACCESSORY") var slot = 0

func get_slot():
	return slot

func evoke(actor, options):
	actor.equip_item(self)