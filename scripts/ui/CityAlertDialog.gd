class_name CityAlertDialog extends AcceptDialog

# Dialog for setting city alert levels

@onready var city_name_label: Label = $VBox/CityNameLabel
@onready var population_label: Label = $VBox/PopulationLabel
@onready var current_alert_label: Label = $VBox/CurrentAlertLabel
@onready var alert_buttons_container: VBoxContainer = $VBox/AlertButtonsContainer

var current_city: Dictionary = {}

signal alert_changed(city_name: String, alert_level: CityManager.AlertLevel)

func _ready():
	title = "City Alert System"
	ok_button_text = "Close"
	setup_alert_buttons()

func setup_alert_buttons():
	# Clear existing buttons
	for child in alert_buttons_container.get_children():
		child.queue_free()
	
	# Create alert level buttons
	create_alert_button("Normal", CityManager.AlertLevel.NONE, Color.WHITE)
	create_alert_button("⚠ CAUTION", CityManager.AlertLevel.CAUTION, Color.YELLOW)
	create_alert_button("🏠 SHELTER", CityManager.AlertLevel.SHELTER, Color.ORANGE)
	create_alert_button("🚨 EVACUATE", CityManager.AlertLevel.EVACUATE, Color.RED)

func create_alert_button(text: String, alert_level: CityManager.AlertLevel, color: Color):
	var button = Button.new()
	button.text = text
	button.modulate = color
	button.pressed.connect(_on_alert_button_pressed.bind(alert_level))
	alert_buttons_container.add_child(button)

func show_city_dialog(city: Dictionary):
	current_city = city
	
	city_name_label.text = "City: " + city.name
	population_label.text = "Population: " + str(city.population)
	
	var current_alert = CityManager.get_city_alert(city.name)
	current_alert_label.text = "Current Alert: " + CityManager.get_alert_level_text(current_alert)
	current_alert_label.modulate = CityManager.get_alert_level_color(current_alert)
	
	popup_centered()

func _on_alert_button_pressed(alert_level: CityManager.AlertLevel):
	if current_city.has("name"):
		CityManager.set_city_alert(current_city.name, alert_level)
		alert_changed.emit(current_city.name, alert_level)
		
		# Update current alert display
		current_alert_label.text = "Current Alert: " + CityManager.get_alert_level_text(alert_level)
		current_alert_label.modulate = CityManager.get_alert_level_color(alert_level)
		
		# Refresh the map to show the new color
		var map_radar = get_tree().get_nodes_in_group("map_radar")
		if map_radar.size() > 0:
			map_radar[0].refresh_map()
		
		print("Set alert for ", current_city.name, " to ", CityManager.get_alert_level_text(alert_level))
