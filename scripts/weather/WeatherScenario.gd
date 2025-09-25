class_name WeatherScenario extends Resource

# Scenario identification
@export var scenario_name: String = ""
@export var storm_type: String = ""
@export var threat_level: int = 1  # 1-5 scale

# Geographic and temporal data
@export var affected_areas: Array[String] = []
@export var storm_intensity: float = 0.0  # dBZ reflectivity
@export var movement_pattern: Vector2 = Vector2.ZERO  # Direction and speed
@export var duration_minutes: int = 90  # Scenario duration

# Correct decision parameters
@export var correct_response: String = ""  # NONE, WEATHER ADVISORY, SHELTER IN PLACE, EVACUATE NOW
@export var correct_priority: String = ""  # LOW, MEDIUM, HIGH
@export var correct_areas: Array[String] = []  # Areas that should be selected

# Radar signature data
@export var radar_signature: Dictionary = {}

# Scenario templates
const SCENARIO_TEMPLATES = {
	"Hurricane Elena": {
		"storm_type": "Hurricane",
		"threat_level": 5,
		"storm_intensity": 65.0,
		"movement_pattern": Vector2(15, -10),
		"affected_areas": ["Puerto Shan", "Bahía Azul"],
		"correct_response": "EVACUATE NOW",
		"correct_priority": "HIGH",
		"radar_signature": {
			"eyewall": true,
			"spiral_bands": true,
			"eye_diameter": 25
		}
	},
	"CIUDADLONG Supercells": {
		"storm_type": "Supercell",
		"threat_level": 4,
		"storm_intensity": 55.0,
		"movement_pattern": Vector2(25, -15),
		"affected_areas": ["Ciudad Long"],
		"correct_response": "SHELTER IN PLACE",
		"correct_priority": "HIGH",
		"radar_signature": {
			"hook_echo": true,
			"mesocyclone": true,
			"bounded_weak_echo": true
		}
	},
	"PUERTOSHAN Sea Breeze": {
		"storm_type": "Thunderstorm",
		"threat_level": 2,
		"storm_intensity": 35.0,
		"movement_pattern": Vector2(10, 5),
		"affected_areas": ["Puerto Shan"],
		"correct_response": "WEATHER ADVISORY",
		"correct_priority": "LOW",
		"radar_signature": {
			"convective_cells": true,
			"sea_breeze_convergence": true
		}
	},
	"Montaña Ridge Orographic": {
		"storm_type": "Orographic",
		"threat_level": 3,
		"storm_intensity": 45.0,
		"movement_pattern": Vector2(5, -20),
		"affected_areas": ["Montaña-Long Ridge"],
		"correct_response": "SHELTER IN PLACE",
		"correct_priority": "MEDIUM",
		"radar_signature": {
			"orographic_enhancement": true,
			"terrain_blocking": true
		}
	},
	"Multi-Cell Complex": {
		"storm_type": "Multi-Cell",
		"threat_level": 4,
		"storm_intensity": 50.0,
		"movement_pattern": Vector2(20, -12),
		"affected_areas": ["San Jii", "Ciudad Long", "Puerto Shan"],
		"correct_response": "SHELTER IN PLACE",
		"correct_priority": "HIGH",
		"radar_signature": {
			"multiple_cells": true,
			"bow_echo": true,
			"rear_inflow_jet": true
		}
	}
}

func _init():
	# Initialize with default values
	scenario_name = ""
	storm_type = ""
	threat_level = 1
	affected_areas = []
	storm_intensity = 0.0
	movement_pattern = Vector2.ZERO
	duration_minutes = 90
	correct_response = ""
	correct_priority = ""
	correct_areas = []
	radar_signature = {}

func load_template(template_name: String) -> bool:
	"""Load a predefined scenario template"""
	if not SCENARIO_TEMPLATES.has(template_name):
		return false
	
	var template = SCENARIO_TEMPLATES[template_name]
	scenario_name = template_name
	storm_type = template["storm_type"]
	threat_level = template["threat_level"]
	storm_intensity = template["storm_intensity"]
	movement_pattern = template["movement_pattern"]
	affected_areas = template["affected_areas"].duplicate()
	correct_response = template["correct_response"]
	correct_priority = template["correct_priority"]
	correct_areas = template["affected_areas"].duplicate()
	radar_signature = template["radar_signature"].duplicate()
	
	return true

func create_custom_scenario(name: String, type: String, areas: Array[String], 
							intensity: float, movement: Vector2, 
							response: String, priority: String) -> void:
	"""Create a custom weather scenario"""
	scenario_name = name
	storm_type = type
	affected_areas = areas.duplicate()
	correct_areas = areas.duplicate()
	storm_intensity = intensity
	movement_pattern = movement
	correct_response = response
	correct_priority = priority
	
	# Set threat level based on response
	match correct_response:
		"EVACUATE NOW":
			threat_level = 5
		"SHELTER IN PLACE":
			threat_level = 4 if correct_priority == "HIGH" else 3
		"WEATHER ADVISORY":
			threat_level = 2 if correct_priority == "MEDIUM" else 1
		_:
			threat_level = 1

func get_random_template() -> String:
	"""Get a random scenario template name"""
	var templates = SCENARIO_TEMPLATES.keys()
	return templates[randi() % templates.size()]

func evaluate_player_decision(selected_areas: Array[String], 
							 selected_response: String, 
							 selected_priority: String) -> Dictionary:
	"""Evaluate player decisions against correct answers"""
	var result = {
		"correct": false,
		"areas_correct": false,
		"response_correct": false,
		"priority_correct": false,
		"false_evacuation": false,
		"missed_threat": false,
		"score": 0
	}
	
	# Check area selection
	result["areas_correct"] = arrays_equal(selected_areas, correct_areas)
	
	# Check response level
	result["response_correct"] = selected_response == correct_response
	
	# Check priority level
	result["priority_correct"] = selected_priority == correct_priority
	
	# Check for critical errors
	if selected_response == "EVACUATE NOW" and correct_response != "EVACUATE NOW":
		result["false_evacuation"] = true
	
	if correct_response == "EVACUATE NOW" and selected_response != "EVACUATE NOW":
		result["missed_threat"] = true
	
	# Calculate overall correctness
	result["correct"] = result["areas_correct"] and result["response_correct"] and result["priority_correct"]
	
	# Calculate score (0-100)
	var score = 0
	if result["areas_correct"]: score += 40
	if result["response_correct"]: score += 40
	if result["priority_correct"]: score += 20
	result["score"] = score
	
	return result

func get_scenario_description() -> String:
	"""Get a human-readable description of the scenario"""
	var description = "Scenario: %s\n" % scenario_name
	description += "Storm Type: %s\n" % storm_type
	description += "Threat Level: %d/5\n" % threat_level
	description += "Affected Areas: %s\n" % ", ".join(affected_areas)
	description += "Storm Intensity: %.1f dBZ\n" % storm_intensity
	description += "Movement: %.1f km/h at %.0f°" % [movement_pattern.length(), rad_to_deg(movement_pattern.angle())]
	
	return description

func arrays_equal(a: Array, b: Array) -> bool:
	"""Helper function to compare two arrays for equality"""
	if a.size() != b.size():
		return false
	
	var a_sorted = a.duplicate()
	var b_sorted = b.duplicate()
	a_sorted.sort()
	b_sorted.sort()
	
	for i in range(a_sorted.size()):
		if a_sorted[i] != b_sorted[i]:
			return false
	
	return true

func get_available_templates() -> Array[String]:
	"""Get list of all available scenario templates"""
	return SCENARIO_TEMPLATES.keys()