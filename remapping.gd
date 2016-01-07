extends Node

const buttons = ["a", "b", "x", "y", "leftshoulder", "rightshoulder", "lefttrigger", "righttrigger", "leftstick",
				"rightstick", "back", "start", "dpup", "dpdown", "dpleft", "dpright"]

const axes = ["leftx", "lefty", "rightx", "righty", "", "", "lefttrigger", "righttrigger"]

const hat = { 12:"h0.1", 13:"h0.4", 14:"h0.8", 15:"h0.2" }

onready var joy_num = get_node("joy_num")
onready var joy_name = get_node("joy_name")
onready var joy_guid = get_node("joy_guid")
onready var joy_mapped = get_node("joy_mapped")
onready var mapping_label_a = get_node("mapping_a")
onready var mapping_label_b = get_node("mapping_b")

var device_id = 0
var device_uid = ""
var device_name = ""
var device_mapped = false setget on_device_mapped_changed
var mapping_a = ""
var mapping_b = ""
var to_button
var to_axis
var from_button
var from_axis
var ignore_axes = []
var got_button
var skip = false
var cancel = false

func _ready():
	_on_joy_num_value_changed(0)
	set_fixed_process(true)
	add_user_signal("input_recieved")

func _input(event):
	if (event.device != device_id):
		return
	if (event.type == InputEvent.JOYSTICK_MOTION and abs(event.value) > 0.7):
		if (event.axis in ignore_axes):
			return
		ignore_axes.append(event.axis)
		from_axis = event.axis
		got_button = false
		emit_signal("input_recieved")
	elif (event.type == InputEvent.JOYSTICK_BUTTON and !event.pressed):
		from_button = event.button_index
		got_button = true
		emit_signal("input_recieved")

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
	mapping_a = device_uid + "," + device_name + ","
	mapping_b = device_uid + "," + device_name + ","
	to_button = 0
	to_axis = 0
	ignore_axes = []
	var finished = false
	while(true):
		
		if to_button < 16:
			var indicator = get_node("diagram/buttons/" + str(to_button))
			indicator.show()
			yield(self, "input_recieved")
			if cancel:
				break
			if skip:
				skip = false
				indicator.hide()
				continue
			if got_button:
				var button_mapping = buttons[to_button] + ":b" + str(from_button) + ","
				mapping_b += button_mapping
				if from_button in hat:
					mapping_a += buttons[to_button] + ":" + hat[from_button] + ","
				else:
					mapping_a += button_mapping
			else:
				mapping_a += buttons[to_button] + ":a" + str(from_axis) + ","
				mapping_b += buttons[to_button] + ":a" + str(from_axis) + ","
			indicator.hide()
			to_button += 1
			continue
			
		if to_axis < 4:
			var indicator_pos = get_node("diagram/axes/" + str(to_axis) + "+")
			var indicator_neg = get_node("diagram/axes/" + str(to_axis) + "-")
			indicator_pos.show()
			indicator_neg.show()
			
			yield(self, "input_recieved")
			if cancel:
				break
			if skip:
				skip = false
				indicator_pos.hide()
				indicator_neg.hide()
				continue
			if got_button:
				var btn_mapping = axes[to_axis] + ":b" + str(from_button) + ","
				mapping_a += btn_mapping
				mapping_b += btn_mapping
			else:
				var axis_mapping = axes[to_axis] + ":a" + str(from_axis) + ","
				mapping_a += axis_mapping
				mapping_b += axis_mapping
			to_axis += 1
			indicator_pos.hide()
			indicator_neg.hide()
			continue
		finished = true
		break
	
	get_node("back").set_disabled(true)
	get_node("cancel").set_disabled(true)
	if finished:
		get_node("apply_a").set_disabled(false)
		get_node("apply_b").set_disabled(false)
		mapping_label_a.set_text(mapping_a)
		mapping_label_b.set_text(mapping_b)
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
	self.device_mapped = Input.is_joy_known(device_id)
	joy_name.set_text(device_name)
	joy_guid.set_text(device_uid)

func on_device_mapped_changed(mapped):
	if mapped:
		joy_mapped.set_text("Yes")
	else:
		joy_mapped.set_text("No")

func _on_start_button_released():
	set_fixed_process(false)
	set_process_input(true)
	hide_all_indicators()
	get_node("back").set_disabled(false)
	get_node("cancel").set_disabled(false)
	get_node("skip").set_disabled(false)
	if Input.is_joy_known(device_id):
		Input.remove_joy_mapping(device_uid)
	start_mapping()

func _on_apply_a_released():
	var text = mapping_label_a.get_text()
	if text != "":
		Input.add_joy_mapping(mapping_a, true)
		self.device_mapped = true

func _on_apply_b_released():
	var text = mapping_label_b.get_text()
	if text != "":
		Input.add_joy_mapping(mapping_b, true)
		self.device_mapped = true

func _on_back_released():
	if to_button == 0:
		return

	if to_button < 16:
		to_button -= 1
	elif to_axis == 0:
		to_button = 15
	else:
		to_axis -= 1
	skip = true
	emit_signal("input_recieved")

func _on_cancel_released():
	cancel = true;
	emit_signal("input_recieved")

func _on_skip_released():
	if to_button == 15:
		to_button = 16
	elif to_button < 15:
		to_button += 1
	elif to_axis < 4:
		to_axis += 1
	skip = true
	emit_signal("input_recieved")
