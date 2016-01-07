extends Node

const buttons = ["a", "b", "x", "y", "leftshoulder", "rightshoulder", "lefttrigger", "righttrigger", "leftstick",
				"rightstick", "back", "start", "dpup", "dpdown", "dpleft", "dpright"]

const axes = ["leftx", "lefty", "rightx", "righty", "", "", "lefttrigger", "righttrigger"]

const hat = { 12:"h0.1", 13:"h0.4", 14:"h0.8", 15:"h0.2" }

onready var joy_num = get_node("vbox/hbox device/joy_num")
onready var joy_name = get_node("vbox/hbox name/joy_name")
onready var joy_guid = get_node("vbox/hbox_guid/joy_guid")
onready var mapping_label_a = get_node("mapping_a")
onready var mapping_label_b = get_node("mapping_b")

var device_id = 0
var device_uid = ""
var device_name = ""
var mapping_a = ""
var mapping_b = ""
var current_button
var current_axis
var ignore_axes = []

func _ready():
	_on_joy_num_value_changed(0)
	set_fixed_process(true)
	add_user_signal("input_recieved", [{"name":"is_button", "type":TYPE_BOOL}])

func _input(event):
	if (event.device != device_id):
		return
	if (event.type == InputEvent.JOYSTICK_MOTION and abs(event.value) > 0.7):
		if (event.axis in ignore_axes):
			return
		ignore_axes.append(event.axis)
		current_axis = event.axis
		emit_signal("input_recieved", false)
	elif (event.type == InputEvent.JOYSTICK_BUTTON and !event.pressed):
		current_button = event.button_index
		emit_signal("input_recieved", true)
	
func _fixed_process(delta):
	for btn in range(16):
		var pressed = Input.is_joy_button_pressed(device_id, btn)
		var indicator = get_node("diagram/buttons/" + str(btn))
		if (pressed):
			indicator.show()
		else:
			indicator.hide()
	for axis in range(4):
		var value = Input.get_joy_axis(device_id, axis)
		var positive = get_node("diagram/axes/" + str(axis) + "+")
		var negative = get_node("diagram/axes/" + str(axis) + "-")
		if (abs(value) < 0.2):
			positive.hide()
			negative.hide()
			continue
		if (value > 0):
			positive.show()
		else:
			negative.show()

func start_mapping():
	for i in range(16):
		var indicator = get_node("diagram/buttons/" + str(i))
		indicator.show()
		if yield(self, "input_recieved"):
			var button_mapping = buttons[i] + ":b" + str(current_button) + ","
			mapping_a += button_mapping
			if current_button in hat:
				mapping_b += buttons[i] + ":" + hat[current_button] + ","
			else:
				mapping_b += button_mapping
		else:
			mapping_a += buttons[i] + ":a" + str(current_axis) + ","
			mapping_b += buttons[i] + ":a" + str(current_axis) + ","
		indicator.hide()
		print(mapping_b)
	
	for i in range(4):
		var indicator_pos = get_node("diagram/axes/" + str(i) + "+")
		var indicator_neg = get_node("diagram/axes/" + str(i) + "-")
		indicator_pos.show()
		indicator_neg.show()
		
		if yield(self, "input_recieved"):
			var btn_mapping = axes[i] + ":b" + str(current_button) + ","
			mapping_a += btn_mapping
			mapping_b += btn_mapping
		else:
			var axis_mapping = axes[i] + ":a" + str(current_axis) + ","
			mapping_a += axis_mapping
			mapping_b += axis_mapping
		indicator_pos.hide()
		indicator_neg.hide()
	mapping_label_a.set_text(mapping_a)
	mapping_label_b.set_text(mapping_b)
	Input.add_joy_mapping(Input.get_joy_guid(device_id) + "," + Input.get_joy_name(device_id) + "," + mapping_b, true)
	
	set_process_input(false)
	set_fixed_process(true)

func hide_all_indicators():
	for indicator in get_node("diagram/axes").get_children():
		indicator.hide()
	for indicator in get_node("diagram/buttons").get_children():
		indicator.hide()

func _on_joy_num_value_changed( value ):
	device_id = value
	device_name = Input.get_joy_name(device_id)
	device_uid = Input.get_joy_guid(device_id)
	joy_name.set_text(device_name)
	joy_guid.set_text(device_uid)


func _on_start_button_released():
	set_fixed_process(false)
	set_process_input(true)
	hide_all_indicators()
	start_mapping()
	
	


func _on_apply_a_released():
	var text = mapping_label_a.get_text()
	if text != "":
		Input.add_joy_mapping(mapping_a, true)


func _on_apply_b_released():
	var text = mapping_label_b.get_text()
	if text != "":
		Input.add_joy_mapping(mapping_b, true)
