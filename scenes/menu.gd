
extends Node2D

const MenuButton = preload("res://scenes/ui/button.xscn")

const Route = preload("res://scenes/route.gd")

onready var saves_node = get_node("saves")
onready var caplog = get_node("/root/captains_log")
onready var profile = caplog.get_node("profile")

func _ready():
	start()

func start():
	var journals = caplog.get_profile()["saves"]
	for route_id in journals:
		var char_name = profile.get_player_name(route_id)
		var button = MenuButton.instance()
		button.set_text(char_name)
		button.connect("pressed", self, "_on_load_game", [route_id])
		saves_node.add_child(button)
	set_process_input(true)
	show()

func stop():
	for button in saves_node.get_children():
		if button.get_name() != "new_game":
			button.queue_free()
	set_process_input(false)
	hide()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		caplog.finish()

func _on_new_game():
	caplog.create_route()
	stop()

func _on_load_game(save_id):
	stop()
	caplog.load_route(save_id)
	get_tree().set_current_scene(get_node("/root/sector"))
