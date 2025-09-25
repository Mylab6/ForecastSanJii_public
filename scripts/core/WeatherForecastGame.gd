extends Control

# San Jii Metro Emergency Weather Forecaster - Main Game Controller
class_name WeatherForecastGame

# UI Scenes
@onready var start_menu: Control = $StartMenu
@onready var game_ui: Control = $GameUI
@onready var radar_display: Control = $GameUI/RadarDisplay
@onready var question_panel: Control = $GameUI/QuestionPanel
@onready var score_panel: Control = $GameUI/ScorePanel
@onready var timer_label: Label = $GameUI/TimerPanel/TimerLabel
@onready var news_segment: Control = $GameUI/NewsSegment

# Game State
var current_round: int = 0
var player_rating: int = 50  # Start at 50/100
var consecutive_correct: int = 0
var total_rounds: int = 0
var correct_rounds: int = 0
var game_active: bool = false
var round_timer: float = 90.0
var max_round_time: float = 90.0

# Current Round Data (exposed to other scripts)
var current_storm_data: Dictionary = {}
var correct_answers: Dictionary = {}
var player_answers: Dictionary = {}
var round_complete: bool = false

# Weather Scenarios
var weather_scenarios = [
	{
		"name": "Hurricane Elena Approach",
		"description": "Category 4 hurricane with 140mph winds approaching CIUDADLONG from the southeast",
		"affected_areas": ["CIUDADLONG", "PUERTOSHAN", "Bahía Azul"],
		"correct_action": "EVACUATE",
		"correct_priority": "HIGH",
		"severity": 0.9,
		"type": "hurricane"
	},
	{
		"name": "MONTAÑAWEI Supercell Complex",
		"description": "Rotating supercells with tornado potential moving through the tech district",
		"affected_areas": ["MONTAÑAWEI"],
		"correct_action": "SHELTER IN PLACE",
		"correct_priority": "HIGH",
		"severity": 0.7,
		"type": "tornado"
	},
	{
		"name": "PLAYAHAI Flash Flood Emergency",
		"description": "Heavy rainfall causing rapid flooding in resort areas and beach communities",
		"affected_areas": ["PLAYAHAI"],
		"correct_action": "SHELTER IN PLACE",
		"correct_priority": "MEDIUM",
		"severity": 0.6,
		"type": "flood"
	},
	{
		"name": "VALLEGU Valley Fog",
		"description": "Dense fog reducing visibility to near zero in agricultural valleys",
		"affected_areas": ["VALLEGU"],
		"correct_action": "WEATHER ADVISORY",
		"correct_priority": "LOW",
		"severity": 0.3,
		"type": "fog"
	},
	{
		"name": "PUERTOSHAN Waterspout Activity",
		"description": "Multiple waterspouts forming over Bahía Azul threatening maritime operations",
		"affected_areas": ["PUERTOSHAN", "Bahía Azul"],
		"correct_action": "WEATHER ADVISORY",
		"correct_priority": "MEDIUM",
		"severity": 0.5,
		"type": "waterspout"
	}
]

# Rating System
var rating_titles = {
	0: "TERMINATED",
	10: "Trainee Meteorologist",
	25: "Junior Meteorologist", 
	40: "Staff Meteorologist",
	60: "Senior Meteorologist",
	80: "Chief Meteorologist",
	95: "Master Forecaster"
}

func _ready():
	_setup_ui()
	_show_start_menu()
	# Auto-start the game for testing the radar
	print("Auto-starting game for testing...")
	call_deferred("_start_game")

func _setup_ui():
	# Hide all UI panels initially
	start_menu.show()
	game_ui.hide()
	
	# Connect start button
	var start_button = start_menu.get_node("StartButton")
	if start_button:
		start_button.pressed.connect(_start_game)

func _show_start_menu():
	start_menu.show()
	game_ui.hide()
	game_active = false

func _start_game():
	print("Starting San Jii Metro Weather Forecaster!")
	start_menu.hide()
	game_ui.show()
	game_active = true
	current_round = 0
	player_rating = 50
	consecutive_correct = 0
	total_rounds = 0
	correct_rounds = 0
	_start_new_round()

func _start_new_round():
	current_round += 1
	total_rounds += 1
	round_timer = max_round_time
	round_complete = false
	
	# Select random weather scenario
	current_storm_data = weather_scenarios[randi() % weather_scenarios.size()].duplicate()
	
	# Set correct answers for this round
	correct_answers = {
		"areas": current_storm_data["affected_areas"],
		"action": current_storm_data["correct_action"],
		"priority": current_storm_data["correct_priority"]
	}
	
	# Reset player answers
	player_answers = {
		"areas": [],
		"action": "NONE",
		"priority": "LOW"
	}
	
	# Update UI
	_update_news_segment()
	_update_score_display()
	_setup_question_panel()
	
	print("Round ", current_round, ": ", current_storm_data["name"])

func _update_news_segment():
	var news_text = news_segment.get_node("NewsText")
	if news_text:
		var breaking_news = "🚨 BREAKING: " + current_storm_data["name"] + "\n\n"
		breaking_news += current_storm_data["description"] + "\n\n"
		breaking_news += "Chief Meteorologist, your immediate assessment is required!"
		news_text.text = breaking_news

func _setup_question_panel():
	# Clear previous selections
	_reset_question_panel()
	
	# Enable question interface
	var q1_panel = question_panel.get_node("Question1")
	var q2_panel = question_panel.get_node("Question2") 
	var q3_panel = question_panel.get_node("Question3")
	
	if q1_panel:
		q1_panel.show()
	if q2_panel:
		q2_panel.show()
	if q3_panel:
		q3_panel.show()

func _reset_question_panel():
	# Reset all checkboxes and radio buttons to default state
	player_answers = {
		"areas": [],
		"action": "NONE",
		"priority": "LOW"
	}
	
	# Call UI handler to reset visual state
	if game_ui.has_method("reset_ui_selections"):
		game_ui.reset_ui_selections()

func _process(delta):
	if game_active and not round_complete:
		round_timer -= delta
		_update_timer_display()
		
		if round_timer <= 0:
			_complete_round()

func _update_timer_display():
	if timer_label:
		var minutes = int(round_timer) / 60.0
		var seconds = int(round_timer) % 60
		timer_label.text = "TIME: %02d:%02d" % [int(minutes), seconds]
		
		# Change color based on remaining time
		if round_timer <= 10:
			timer_label.modulate = Color.RED
		elif round_timer <= 30:
			timer_label.modulate = Color.YELLOW
		else:
			timer_label.modulate = Color.WHITE

func _complete_round():
	round_complete = true
	var results = _evaluate_answers()
	_update_rating(results)
	_show_round_results(results)
	
	# Check for game over conditions
	if _check_game_over():
		_end_game()
	else:
		# Start next round after delay
		await get_tree().create_timer(3.0).timeout
		_start_new_round()

func _evaluate_answers() -> Dictionary:
	var results = {
		"areas_correct": false,
		"action_correct": false,
		"priority_correct": false,
		"overall_correct": false,
		"critical_error": false
	}
	
	# Check area selection
	var correct_areas = correct_answers["areas"]
	var selected_areas = player_answers["areas"]
	results["areas_correct"] = _arrays_match(correct_areas, selected_areas)
	
	# Check action selection
	results["action_correct"] = (player_answers["action"] == correct_answers["action"])
	
	# Check priority selection
	results["priority_correct"] = (player_answers["priority"] == correct_answers["priority"])
	
	# Critical error: False evacuation
	if player_answers["action"] == "EVACUATE" and correct_answers["action"] != "EVACUATE":
		results["critical_error"] = true
	
	# Overall correctness
	results["overall_correct"] = (results["areas_correct"] and 
								results["action_correct"] and 
								results["priority_correct"])
	
	return results

func _arrays_match(arr1: Array, arr2: Array) -> bool:
	if arr1.size() != arr2.size():
		return false
	
	for item in arr1:
		if not arr2.has(item):
			return false
	return true

func _update_rating(results: Dictionary):
	if results["critical_error"]:
		player_rating = 0  # Instant termination
		return
	
	if results["overall_correct"]:
		correct_rounds += 1
		consecutive_correct += 1
		# Bonus for consecutive correct answers
		var rating_gain = 5 + min(consecutive_correct, 5)
		player_rating = min(100, player_rating + rating_gain)
	else:
		consecutive_correct = 0
		# Penalty for wrong answers
		var penalty = 8
		if not results["action_correct"]:
			penalty += 5  # Action is most critical
		player_rating = max(0, player_rating - penalty)

func _show_round_results(results: Dictionary):
	var result_text = ""
	
	if results["critical_error"]:
		result_text = "🚨 CRITICAL ERROR: False evacuation order! You've been TERMINATED!"
	elif results["overall_correct"]:
		result_text = "✅ Excellent work, Chief! All decisions correct."
	else:
		result_text = "❌ Review needed:\n"
		if not results["areas_correct"]:
			result_text += "• Incorrect threat area assessment\n"
		if not results["action_correct"]:
			result_text += "• Inappropriate response level\n"
		if not results["priority_correct"]:
			result_text += "• Wrong priority assignment\n"
	
	print(result_text)

func _check_game_over() -> bool:
	return player_rating <= 0

func _end_game():
	game_active = false
	print("Game Over! Final Rating: ", player_rating)
	print("Correct Rounds: ", correct_rounds, "/", total_rounds)
	# Return to start menu after delay
	await get_tree().create_timer(5.0).timeout
	_show_start_menu()

func _update_score_display():
	var rating_text = _get_rating_title()
	var score_label = score_panel.get_node("RatingLabel")
	var stats_label = score_panel.get_node("StatsLabel")
	
	if score_label:
		score_label.text = "RATING: %d/100 - %s" % [player_rating, rating_text]
	
	if stats_label:
		var accuracy = 0.0
		if total_rounds > 0:
			accuracy = float(correct_rounds) / float(total_rounds) * 100.0
		stats_label.text = "Round %d | Accuracy: %.1f%% | Streak: %d" % [current_round, accuracy, consecutive_correct]

func _get_rating_title() -> String:
	for threshold in rating_titles.keys():
		if player_rating >= threshold:
			continue
		else:
			# Find the previous threshold
			var keys = rating_titles.keys()
			keys.sort()
			for i in range(keys.size() - 1, -1, -1):
				if player_rating >= keys[i]:
					return rating_titles[keys[i]]
	
	return rating_titles[95]  # Master Forecaster

# Public functions for UI to call
func select_area(area_name: String, selected: bool):
	if selected and not player_answers["areas"].has(area_name):
		player_answers["areas"].append(area_name)
	elif not selected and player_answers["areas"].has(area_name):
		player_answers["areas"].erase(area_name)

func select_action(action: String):
	player_answers["action"] = action

func select_priority(priority: String):
	player_answers["priority"] = priority

# Getters for other scripts to access current game state
func get_current_storm_data() -> Dictionary:
	return current_storm_data

func get_correct_answers() -> Dictionary:
	return correct_answers

func get_player_answers() -> Dictionary:
	return player_answers

func get_player_rating() -> int:
	return player_rating

func is_game_active() -> bool:
	return game_active and not round_complete
