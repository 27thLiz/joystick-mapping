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
onready var timer = get_node("input_timer")
onready var diag = get_node("extra_event_diag")
onready var popup = diag.get_node("MenuButton").get_popup()
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
var possible_events = []
var got_button
var skip = false
var cancel = false
var do_mapping = false
var got_extra_input = false
var event_chosen = false

func _ready():
	_on_joy_num_value_changed(0)
	set_fixed_process(true)
	set_process_input(true)
	add_user_signal("input_recieved")
	diag.get_node("MenuButton").get_popup().connect("item_pressed", self, "_event_selected")

func _input(event):
	if !do_mapping:
		if (event.is_action_released("start_mapping")):
			_on_start_button_released()
	else:
		if (event.type == InputEvent.KEY):
			print(event.scancode)
		if (event.is_action_released("mapping_back")):
			_on_back_released()
		if (event.is_action_released("mapping_skip")):
			_on_skip_released()
		if (event.is_action_released("mapping_cancel")):
			_on_cancel_released()
		if (event.device != device_id):
			return
		if (event.type == InputEvent.JOYSTICK_MOTION and abs(event.value) > 0.7):
			if (event.axis in ignore_axes):
				return
			if !(to_button > 11 and to_button < 16):
				ignore_axes.append(event.axis)
			from_axis = event.axis
			got_button = false
			start_timer(event)
		elif (event.type == InputEvent.JOYSTICK_BUTTON and !event.pressed):
			from_button = event.button_index
			got_button = true
			start_timer(event)

func _fixed_process(delta):
	
	if do_mapping:
		return
	if (device_name != Input.get_joy_name(device_id)):
		_on_joy_num_value_changed(device_id)
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
	do_mapping = true
	mapping_a = device_uid + "," + device_name + ","
	mapping_b = device_uid + "," + device_name + ","
	to_button = 0
	to_axis = 0
	ignore_axes = []
	var finished = false
	var map_a = {}
	var map_b = {}
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
			if !got_button:
				var axis_mapping = "a" + str(from_axis)
				map_a[buttons[to_button]] = axis_mapping
				map_b[buttons[to_button]] = axis_mapping
			else:
				var button_mapping = "b" + str(from_button)
				map_b[buttons[to_button]] = button_mapping
				if from_button in hat:
					map_a[buttons[to_button]] = hat[from_button]
				else:
					map_a[buttons[to_button]] = button_mapping
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
				var button_mapping = "b" + str(from_button)
				map_a[axes[to_axis]] = button_mapping
				map_b[axes[to_axis]] = button_mapping
			else:
				var axis_mapping = "a" + str(from_axis) 
				map_a[axes[to_axis]] = axis_mapping
				map_b[axes[to_axis]] = axis_mapping
			to_axis += 1
			indicator_pos.hide()
			indicator_neg.hide()
			continue
		finished = true
		break
	
	for key in map_a.keys():
		mapping_a += key + ":" + map_a[key] + ","
	
	for key in map_b.keys():
		mapping_b += key + ":" + map_b[key] + ","
		
	get_node("back").set_disabled(true)
	get_node("cancel").set_disabled(true)
	get_node("skip").set_disabled(true)
	if finished:
		get_node("apply_a").set_disabled(false)
		get_node("apply_b").set_disabled(false)
		get_node("copy_a").set_disabled(false)
		get_node("copy_b").set_disabled(false)
		mapping_label_a.set_text(mapping_a)
		mapping_label_b.set_text(mapping_b)
		print("MAPPING A: ", mapping_a)
		print("MAPPING B: ", mapping_b)
		Input.add_joy_mapping(mapping_a, true)
	do_mapping = false

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
	if device_uid == "__XINPUT_DEVICE__":
		get_node("xinput_notice").show()
		return
	hide_all_indicators()
	get_node("back").set_disabled(false)
	get_node("cancel").set_disabled(false)
	get_node("skip").set_disabled(false)
	on_device_mapped_changed(device_id)
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

func _on_copy_a_released():
	OS.set_clipboard(mapping_a)

func _on_copy_b_released():
	OS.set_clipboard(mapping_b)

func start_timer(event):
	possible_events.append(event)
	if !got_extra_input:
		timer.start()
		got_extra_input = true
	else:
		timer.stop()
		popup.clear()
		for ev in possible_events:
			var item
			if ev.type == InputEvent.JOYSTICK_BUTTON:
				item = "Joy Button " + str(ev.button_index)
			else:
				item = "Joy Axis " + str(ev.axis)
			popup.add_item(item)
		diag.show()
		var action = diag.get_node("action_label")
		if to_button < JOY_BUTTON_MAX:
			action.set_text(buttons[to_button])
		else:
			action.set_text(axes[to_axis])
		diag.get_node("MenuButton").set_text("Choose event")
		event_chosen = false

func _input_timeout():
	got_extra_input = false
	emit_signal("input_recieved")
	possible_events = []

func _event_selected(index):
	var ev = possible_events[index]
	if ev.type == InputEvent.JOYSTICK_BUTTON:
		got_button = true
		from_button = ev.button_index
	else:
		got_button = false
		from_axis = ev.axis
	event_chosen = true
	diag.get_node("MenuButton").set_text(popup.get_item_text(index))

func _extra_event_diag_confirmed():
	if !event_chosen:
		diag.show()
	else:
		_input_timeout()
