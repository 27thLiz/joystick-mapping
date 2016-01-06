
extends Node

# member variables here, example:
# var a=2
# var b="textvar"

const buttons = [
	"a", "b", "x", "y", "leftshoulder", "rightshoulder", "lefttrigger", "righttrigger", "leftstick",
	"rightstick", "back", "start"
]

const axes = ["leftx", "lefty", "rightx", "righty", "", "", "lefttrigger", "righttrigger"]

onready var joy_num = get_node("vbox/hbox device/joy_num")

func _ready():
	# Initialization here
	set_fixed_process(true)
	pass


func _fixed_process(delta):
	var device_id = joy_num.get_value()
	