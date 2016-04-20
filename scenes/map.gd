
extends Node2D

const BodyView = preload("res://scenes/bodyview.gd")

const block = [
	Vector2(1,0),
	Vector2(0,1),
	Vector2(1,1)
]

var bodies
var actor_bodies
onready var walls = get_node("walls")

func _init():
	bodies = []
	actor_bodies = {}
	print("map created")

func _ready():
	print("map ready")
	pass
	
func is_empty_space(pos):
	return walls.get_cell(pos.x, pos.y) == -1

func add_body(body):
	var bodyview = BodyView.create(body)
	bodies.append(body)
	get_node("walls").add_child(bodyview)

func add_actor(body, actor):
	get_node("actors").add_child(actor)
	actor_bodies[actor] = body
	var module = preload("res://model/ai/wander.gd").new()
	actor.add_child(module)

func move_actor(actor, new_pos):
	move_body(actor_bodies[actor], new_pos)

func move_body(body, new_pos):
	body.pos = new_pos

func get_actor_body(actor):
	return actor_bodies[actor]

func get_body_at(pos):
	for body in bodies:
		if body.pos == pos:
			return body
	return null

func _fixed_process(delta):
	var player_body = get_actor_body(get_parent().player)
	for i in range(5):
		for j in range(5):
			var pos = player_body.pos + Vector2(i,j)
			var cell = walls.get_cell(pos.x, pos.y)
			if cell > 0 && cell % 2 == 0:
				walls.set_cell(pos.x, pos.y, cell - 1)
	for diff in block:
		var pos = player_body.pos + diff
		var cell = walls.get_cell(pos.x, pos.y)
		if cell % 2 == 1:
			walls.set_cell(pos.x, pos.y, cell + 1)

