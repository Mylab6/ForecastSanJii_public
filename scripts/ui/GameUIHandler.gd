extends Control

# UI Interaction Handler for Weather Forecast Game
class_name GameUIHandler

@onready var game_controller = get_parent()

# Question 1 - Area Selection Checkboxes
var q1_ciudadlong
var q1_puertoshan
var q1_montanawei
var q1_playahai
var q1_vallegu

# Question 2 - Action Radio Buttons
var q2_none
var q2_advisory
var q2_shelter
var q2_evacuate

# Question 3 - Priority Radio Buttons
var q3_low
var q3_medium
var q3_high

func _ready():
	call_deferred("_setup_ui_references")

func _setup_ui_references():
	# Get node references safely
	q1_ciudadlong = get_node_or_null("QuestionPanel/Question1/Q1_CIUDADLONG")
	q1_puertoshan = get_node_or_null("QuestionPanel/Question1/Q1_PUERTOSHAN")
	q1_montanawei = get_node_or_null("QuestionPanel/Question1/Q1_MONTAÑAWEI")
	q1_playahai = get_node_or_null("QuestionPanel/Question1/Q1_PLAYAHAI")
	q1_vallegu = get_node_or_null("QuestionPanel/Question1/Q1_VALLEGU")
	
	q2_none = get_node_or_null("QuestionPanel/Question2/Q2_NONE")
	q2_advisory = get_node_or_null("QuestionPanel/Question2/Q2_ADVISORY")
	q2_shelter = get_node_or_null("QuestionPanel/Question2/Q2_SHELTER")
	q2_evacuate = get_node_or_null("QuestionPanel/Question2/Q2_EVACUATE")
	
	q3_low = get_node_or_null("QuestionPanel/Question3/Q3_LOW")
	q3_medium = get_node_or_null("QuestionPanel/Question3/Q3_MEDIUM")
	q3_high = get_node_or_null("QuestionPanel/Question3/Q3_HIGH")
	
	_connect_ui_signals()

func _connect_ui_signals():
	# Connect area selection checkboxes with null checks
	if q1_ciudadlong and q1_ciudadlong.has_signal("toggled"):
		q1_ciudadlong.toggled.connect(_on_area_selected.bind("CIUDADLONG"))
	if q1_puertoshan and q1_puertoshan.has_signal("toggled"):
		q1_puertoshan.toggled.connect(_on_area_selected.bind("PUERTOSHAN"))
	if q1_montanawei and q1_montanawei.has_signal("toggled"):
		q1_montanawei.toggled.connect(_on_area_selected.bind("MONTAÑAWEI"))
	if q1_playahai and q1_playahai.has_signal("toggled"):
		q1_playahai.toggled.connect(_on_area_selected.bind("PLAYAHAI"))
	if q1_vallegu and q1_vallegu.has_signal("toggled"):
		q1_vallegu.toggled.connect(_on_area_selected.bind("VALLEGU"))
	
	# Connect action radio buttons with null checks
	if q2_none and q2_none.has_signal("toggled"):
		q2_none.toggled.connect(_on_action_selected.bind("NONE"))
	if q2_advisory and q2_advisory.has_signal("toggled"):
		q2_advisory.toggled.connect(_on_action_selected.bind("WEATHER ADVISORY"))
	if q2_shelter and q2_shelter.has_signal("toggled"):
		q2_shelter.toggled.connect(_on_action_selected.bind("SHELTER IN PLACE"))
	if q2_evacuate and q2_evacuate.has_signal("toggled"):
		q2_evacuate.toggled.connect(_on_action_selected.bind("EVACUATE"))
	
	# Connect priority radio buttons with null checks
	if q3_low and q3_low.has_signal("toggled"):
		q3_low.toggled.connect(_on_priority_selected.bind("LOW"))
	if q3_medium and q3_medium.has_signal("toggled"):
		q3_medium.toggled.connect(_on_priority_selected.bind("MEDIUM"))
	if q3_high and q3_high.has_signal("toggled"):
		q3_high.toggled.connect(_on_priority_selected.bind("HIGH"))
	
	print("UI signals connected successfully!")

func _on_area_selected(area_name: String, selected: bool):
	if game_controller and game_controller.has_method("select_area"):
		game_controller.select_area(area_name, selected)
		print("Area ", area_name, " selected: ", selected)

func _on_action_selected(action: String, selected: bool):
	if selected and game_controller and game_controller.has_method("select_action"):
		game_controller.select_action(action)
		print("Action selected: ", action)
		
		# Special visual feedback for evacuation
		if action == "EVACUATE":
			_flash_evacuation_warning()

func _on_priority_selected(priority: String, selected: bool):
	if selected and game_controller and game_controller.has_method("select_priority"):
		game_controller.select_priority(priority)
		print("Priority selected: ", priority)

func _flash_evacuation_warning():
	# Visual warning for evacuation selection
	if q2_evacuate:
		var original_color = q2_evacuate.modulate
		q2_evacuate.modulate = Color.RED
		
		# Flash effect
		var tween = create_tween()
		tween.tween_property(q2_evacuate, "modulate", original_color, 0.5)
		tween.tween_property(q2_evacuate, "modulate", Color.RED, 0.5)
		tween.tween_property(q2_evacuate, "modulate", original_color, 0.5)

func reset_ui_selections():
	# Reset all checkboxes with null checks
	if q1_ciudadlong and q1_ciudadlong.has_method("set_pressed_no_signal"):
		q1_ciudadlong.set_pressed_no_signal(false)
	if q1_puertoshan and q1_puertoshan.has_method("set_pressed_no_signal"):
		q1_puertoshan.set_pressed_no_signal(false)
	if q1_montanawei and q1_montanawei.has_method("set_pressed_no_signal"):
		q1_montanawei.set_pressed_no_signal(false)
	if q1_playahai and q1_playahai.has_method("set_pressed_no_signal"):
		q1_playahai.set_pressed_no_signal(false)
	if q1_vallegu and q1_vallegu.has_method("set_pressed_no_signal"):
		q1_vallegu.set_pressed_no_signal(false)
	
	# Reset action selection to NONE
	if q2_none and q2_none.has_method("set_pressed_no_signal"):
		q2_none.set_pressed_no_signal(true)
	
	# Reset priority to LOW
	if q3_low and q3_low.has_method("set_pressed_no_signal"):
		q3_low.set_pressed_no_signal(true)
	
	print("UI selections reset")
