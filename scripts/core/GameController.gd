class_name GameController extends Control

# Game state management for Enhanced Weather Emergency System
# Handles round timing, state transitions, and career progression

# Game state enumeration
enum GameState {
	MENU,
	ROUND_ACTIVE,
	DECISION_PHASE,
	FEEDBACK,
	GAME_OVER,
	CAREER_TERMINATED
}

# Core game state
@export var current_state: GameState = GameState.MENU
@export var current_round: int = 0
@export var round_timer: float = 90.0  # 90 seconds per round
@export var max_round_time: float = 90.0
@export var feedback_duration: float = 15.0

# Game components
var player_stats: PlayerStats
var current_scenario: WeatherScenario
var map_radar: MapRadar
var decision_interface: Control  # Will be connected later
var feedback_system: Control     # Will be connected later

# Timer and timing
var timer_node: Timer
var round_start_time: float
var decision_start_time: float
var feedback_timer: Timer

# Game progression
@export var scenarios_per_career: int = 50
@export var difficulty_progression: bool = true
@export var auto_advance_rounds: bool = true

# Debug and testing
@export var debug_mode: bool = false
@export var skip_timers: bool = false

# Signals for UI updates
signal state_changed(new_state: GameState)
signal round_started(round_number: int, scenario: WeatherScenario)
signal timer_updated(time_remaining: float)
signal round_completed(success: bool, stats: Dictionary)
signal career_terminated(reason: String)
signal game_over(final_stats: Dictionary)

func _ready():
	print("GameController initializing...")
	
	# Initialize player stats
	player_stats = PlayerStats.new()
	
	# Setup timers
	_setup_timers()
	
	# Initialize game state
	_change_state(GameState.MENU)
	
	print("GameController ready - Current state: ", GameState.keys()[current_state])

func _setup_timers():
	"""Initialize timer nodes for game timing"""
	# Main round timer
	timer_node = Timer.new()
	timer_node.wait_time = max_round_time
	timer_node.one_shot = true
	timer_node.timeout.connect(_on_round_timer_timeout)
	add_child(timer_node)
	
	# Feedback timer
	feedback_timer = Timer.new()
	feedback_timer.wait_time = feedback_duration
	feedback_timer.one_shot = true
	feedback_timer.timeout.connect(_on_feedback_timer_timeout)
	add_child(feedback_timer)

func start_new_game():
	"""Initialize a new game session"""
	print("Starting new game...")
	
	# Reset player stats
	player_stats.reset_stats()
	current_round = 0
	
	# Start first round
	start_round()

func start_round():
	"""Begin a new round with scenario generation"""
	if player_stats.is_career_terminated():
		_handle_career_termination("Career terminated due to critical errors")
		return
	
	current_round += 1
	print("Starting round ", current_round)
	
	# Generate or select scenario
	current_scenario = _generate_round_scenario()
	
	if not current_scenario:
		print("ERROR: Failed to generate scenario for round ", current_round)
		return
	
	# Update radar display with scenario
	if map_radar:
		map_radar.update_storm_scenario(current_scenario)
	
	# Initialize round timing
	round_timer = max_round_time
	round_start_time = Time.get_time_dict_from_system()["unix"]
	
	# Start round timer
	if not skip_timers:
		timer_node.start()
	
	# Change to active round state
	_change_state(GameState.ROUND_ACTIVE)
	
	# Emit round started signal
	round_started.emit(current_round, current_scenario)
	
	print("Round ", current_round, " started: ", current_scenario.scenario_name)

func _generate_round_scenario() -> WeatherScenario:
	"""Generate appropriate scenario for current round"""
	var scenario = WeatherScenario.new()
	
	# Select scenario based on difficulty progression
	var available_templates = scenario.get_available_templates()
	var template_name: String
	
	if difficulty_progression:
		# Progressive difficulty based on round number
		if current_round <= 5:
			# Easy scenarios for first 5 rounds
			var easy_scenarios = ["PUERTOSHAN Sea Breeze", "Montaña Ridge Orographic"]
			template_name = easy_scenarios[randi() % easy_scenarios.size()]
		elif current_round <= 15:
			# Medium scenarios
			var medium_scenarios = ["CIUDADLONG Supercells", "Multi-Cell Complex"]
			template_name = medium_scenarios[randi() % medium_scenarios.size()]
		else:
			# Hard scenarios including hurricanes
			template_name = available_templates[randi() % available_templates.size()]
	else:
		# Random scenario selection
		template_name = available_templates[randi() % available_templates.size()]
	
	# Load the selected template
	if scenario.load_template(template_name):
		return scenario
	else:
		print("ERROR: Failed to load scenario template: ", template_name)
		return null

func process_decisions(selected_areas: Array[String], selected_response: String, selected_priority: String):
	"""Process player decisions and evaluate performance"""
	if current_state != GameState.ROUND_ACTIVE:
		print("WARNING: Decisions submitted outside of active round")
		return
	
	if not current_scenario:
		print("ERROR: No current scenario for decision processing")
		return
	
	print("Processing decisions: Areas=", selected_areas, " Response=", selected_response, " Priority=", selected_priority)
	
	# Calculate response time
	var current_time = Time.get_time_dict_from_system()["unix"]
	var response_time = current_time - round_start_time
	
	# Evaluate decisions against scenario
	var evaluation = current_scenario.evaluate_player_decision(selected_areas, selected_response, selected_priority)
	
	# Check for career-ending errors
	if evaluation["false_evacuation"]:
		_handle_career_termination("False evacuation order issued")
		return
	
	if evaluation["missed_threat"]:
		_handle_career_termination("Failed to issue evacuation for major threat")
		return
	
	# Update player statistics
	var lives_impact = _calculate_lives_impact(evaluation, current_scenario)
	var economic_impact = _calculate_economic_impact(evaluation, current_scenario)
	
	player_stats.update_round_stats(evaluation["correct"], response_time, lives_impact, economic_impact)
	
	# Stop round timer
	timer_node.stop()
	
	# Prepare feedback data
	var feedback_data = {
		"evaluation": evaluation,
		"response_time": response_time,
		"lives_impact": lives_impact,
		"economic_impact": economic_impact,
		"scenario": current_scenario,
		"player_stats": player_stats.get_performance_summary()
	}
	
	# Move to feedback phase
	_show_feedback(feedback_data)

func _calculate_lives_impact(evaluation: Dictionary, scenario: WeatherScenario) -> int:
	"""Calculate lives saved or lost based on decision accuracy"""
	var base_population = 10000  # Base population at risk
	
	if evaluation["correct"]:
		# Correct decision saves lives
		match scenario.threat_level:
			5: return 500   # Major hurricane
			4: return 200   # Severe storms
			3: return 100   # Moderate threat
			2: return 50    # Minor threat
			1: return 25    # Minimal threat
	else:
		# Incorrect decisions have consequences
		if evaluation["false_evacuation"]:
			return -100  # Economic disruption, some injuries
		elif evaluation["missed_threat"]:
			return -1000  # Major casualties from missed evacuation
		else:
			return -50   # Minor consequences from wrong response level
	
	return 0

func _calculate_economic_impact(evaluation: Dictionary, scenario: WeatherScenario) -> int:
	"""Calculate economic impact of decisions"""
	var base_cost = 100000  # Base economic impact
	
	if evaluation["correct"]:
		# Correct decisions minimize economic damage
		return base_cost * scenario.threat_level
	else:
		# Incorrect decisions increase costs
		if evaluation["false_evacuation"]:
			return -500000  # Major economic disruption
		elif evaluation["missed_threat"]:
			return -2000000  # Massive damage from unprotected population
		else:
			return -base_cost  # Moderate additional costs
	
	return 0

func _show_feedback(feedback_data: Dictionary):
	"""Display round feedback to player"""
	_change_state(GameState.FEEDBACK)
	
	# Emit feedback signal for UI
	round_completed.emit(feedback_data["evaluation"]["correct"], feedback_data)
	
	# Start feedback timer
	if not skip_timers:
		feedback_timer.start()
	
	print("Round ", current_round, " completed - Success: ", feedback_data["evaluation"]["correct"])
	print("Response time: ", "%.1f" % feedback_data["response_time"], "s")
	print("Lives impact: ", feedback_data["lives_impact"])
	print("Economic impact: $", feedback_data["economic_impact"])

func end_round():
	"""Complete current round and advance game"""
	if current_state != GameState.FEEDBACK:
		print("WARNING: end_round called outside feedback phase")
		return
	
	# Check for game over conditions
	if current_round >= scenarios_per_career:
		_handle_game_completion()
		return
	
	if player_stats.is_career_terminated():
		_handle_career_termination("Career performance below standards")
		return
	
	# Advance to next round if auto-advance is enabled
	if auto_advance_rounds:
		start_round()
	else:
		_change_state(GameState.MENU)

func _handle_career_termination(reason: String):
	"""Handle career termination scenarios"""
	print("CAREER TERMINATED: ", reason)
	
	_change_state(GameState.CAREER_TERMINATED)
	career_terminated.emit(reason)
	
	# Stop all timers
	timer_node.stop()
	feedback_timer.stop()

func _handle_game_completion():
	"""Handle successful completion of career"""
	print("CAREER COMPLETED! Final stats:")
	var final_stats = player_stats.get_performance_summary()
	
	for key in final_stats:
		print("  ", key, ": ", final_stats[key])
	
	_change_state(GameState.GAME_OVER)
	game_over.emit(final_stats)

func evaluate_performance() -> Dictionary:
	"""Get current performance evaluation"""
	return {
		"current_round": current_round,
		"career_level": player_stats.career_level,
		"accuracy_rate": player_stats.accuracy_rate,
		"response_time_avg": player_stats.response_time_avg,
		"lives_saved": player_stats.lives_saved,
		"career_terminated": player_stats.is_career_terminated(),
		"rounds_remaining": scenarios_per_career - current_round
	}

func _change_state(new_state: GameState):
	"""Handle game state transitions"""
	var old_state = current_state
	current_state = new_state
	
	print("State change: ", GameState.keys()[old_state], " -> ", GameState.keys()[new_state])
	state_changed.emit(new_state)

func _process(delta):
	"""Update game timing and state"""
	if current_state == GameState.ROUND_ACTIVE and not skip_timers:
		# Update round timer
		round_timer = timer_node.time_left
		timer_updated.emit(round_timer)
		
		# Check for urgency indicators
		if round_timer < 30.0:
			# Emit urgency signal for UI
			pass
		
		if round_timer < 10.0:
			# Critical time warning
			pass

func _on_round_timer_timeout():
	"""Handle round timer expiration"""
	print("Round timer expired - auto-submitting decisions")
	
	# Auto-submit empty decisions (will likely result in failure)
	process_decisions([], "NONE", "LOW")

func _on_feedback_timer_timeout():
	"""Handle feedback timer expiration"""
	print("Feedback timer expired - advancing to next round")
	end_round()

# Public interface methods

func set_map_radar(radar: MapRadar):
	"""Connect map radar component"""
	map_radar = radar
	print("Map radar connected to GameController")

func set_decision_interface(interface: Control):
	"""Connect decision interface component"""
	decision_interface = interface
	print("Decision interface connected to GameController")

func set_feedback_system(system: Control):
	"""Connect feedback system component"""
	feedback_system = system
	print("Feedback system connected to GameController")

func get_current_scenario() -> WeatherScenario:
	"""Get current weather scenario"""
	return current_scenario

func get_player_stats() -> PlayerStats:
	"""Get current player statistics"""
	return player_stats

func get_time_remaining() -> float:
	"""Get remaining time in current round"""
	return round_timer

func is_round_active() -> bool:
	"""Check if a round is currently active"""
	return current_state == GameState.ROUND_ACTIVE

func pause_game():
	"""Pause the current game"""
	if timer_node:
		timer_node.paused = true
	if feedback_timer:
		feedback_timer.paused = true

func resume_game():
	"""Resume the paused game"""
	if timer_node:
		timer_node.paused = false
	if feedback_timer:
		feedback_timer.paused = false

func restart_game():
	"""Restart the entire game"""
	# Stop all timers
	timer_node.stop()
	feedback_timer.stop()
	
	# Reset state
	current_round = 0
	current_scenario = null
	
	# Start new game
	start_new_game()

func set_debug_mode(enabled: bool):
	"""Enable/disable debug mode"""
	debug_mode = enabled
	skip_timers = enabled  # Skip timers in debug mode
	
	if map_radar:
		map_radar.set_debug_mode(enabled)

func get_debug_info() -> Dictionary:
	"""Get debug information"""
	return {
		"current_state": GameState.keys()[current_state],
		"current_round": current_round,
		"time_remaining": round_timer,
		"scenario_name": current_scenario.scenario_name if current_scenario else "None",
		"player_stats": player_stats.get_performance_summary() if player_stats else {},
		"debug_mode": debug_mode
	}