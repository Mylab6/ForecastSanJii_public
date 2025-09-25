extends GutTest

# Unit tests for GameController
# Tests state management, round timing, and game progression

var game_controller: GameController
var test_scenario: WeatherScenario

func before_each():
	game_controller = GameController.new()
	test_scenario = WeatherScenario.new()
	test_scenario.load_template("Hurricane Elena")
	
	# Add to scene tree for proper timer functionality
	add_child(game_controller)
	
	# Enable debug mode to skip timers for testing
	game_controller.set_debug_mode(true)

func after_each():
	if game_controller:
		game_controller.queue_free()

func test_game_controller_initialization():
	assert_not_null(game_controller, "GameController should be created")
	assert_eq(game_controller.current_state, GameController.GameState.MENU, "Should start in MENU state")
	assert_eq(game_controller.current_round, 0, "Should start at round 0")
	assert_not_null(game_controller.player_stats, "Player stats should be initialized")

func test_game_state_transitions():
	# Test state change
	game_controller._change_state(GameController.GameState.ROUND_ACTIVE)
	assert_eq(game_controller.current_state, GameController.GameState.ROUND_ACTIVE, "State should change to ROUND_ACTIVE")
	
	# Test state change to feedback
	game_controller._change_state(GameController.GameState.FEEDBACK)
	assert_eq(game_controller.current_state, GameController.GameState.FEEDBACK, "State should change to FEEDBACK")

func test_new_game_start():
	game_controller.start_new_game()
	
	assert_eq(game_controller.current_round, 1, "Should start at round 1")
	assert_eq(game_controller.current_state, GameController.GameState.ROUND_ACTIVE, "Should be in ROUND_ACTIVE state")
	assert_not_null(game_controller.current_scenario, "Should have a current scenario")

func test_round_scenario_generation():
	var scenario = game_controller._generate_round_scenario()
	
	assert_not_null(scenario, "Should generate a scenario")
	assert_true(scenario.scenario_name.length() > 0, "Scenario should have a name")
	assert_true(scenario.storm_type.length() > 0, "Scenario should have a storm type")
	assert_true(scenario.correct_response.length() > 0, "Scenario should have correct response")

func test_difficulty_progression():
	game_controller.difficulty_progression = true
	game_controller.current_round = 3  # Early round
	
	var early_scenario = game_controller._generate_round_scenario()
	assert_not_null(early_scenario, "Should generate early scenario")
	
	game_controller.current_round = 20  # Late round
	var late_scenario = game_controller._generate_round_scenario()
	assert_not_null(late_scenario, "Should generate late scenario")

func test_decision_processing_correct():
	# Setup active round
	game_controller.current_scenario = test_scenario
	game_controller._change_state(GameController.GameState.ROUND_ACTIVE)
	game_controller.round_start_time = Time.get_time_dict_from_system()["unix"]
	
	# Process correct decision
	game_controller.process_decisions(["Puerto Shan", "Bahía Azul"], "EVACUATE NOW", "HIGH")
	
	assert_eq(game_controller.current_state, GameController.GameState.FEEDBACK, "Should move to FEEDBACK state")
	assert_eq(game_controller.player_stats.successful_rounds, 1, "Should record successful round")
	assert_true(game_controller.player_stats.accuracy_rate > 0.0, "Should have positive accuracy rate")

func test_decision_processing_incorrect():
	# Setup active round
	game_controller.current_scenario = test_scenario
	game_controller._change_state(GameController.GameState.ROUND_ACTIVE)
	game_controller.round_start_time = Time.get_time_dict_from_system()["unix"]
	
	# Process incorrect decision
	game_controller.process_decisions(["San Jii"], "WEATHER ADVISORY", "LOW")
	
	assert_eq(game_controller.current_state, GameController.GameState.FEEDBACK, "Should move to FEEDBACK state")
	assert_eq(game_controller.player_stats.successful_rounds, 0, "Should not record as successful")
	assert_eq(game_controller.player_stats.total_rounds, 1, "Should record total round")

func test_false_evacuation_termination():
	# Setup scenario that doesn't require evacuation
	var mild_scenario = WeatherScenario.new()
	mild_scenario.load_template("PUERTOSHAN Sea Breeze")
	
	game_controller.current_scenario = mild_scenario
	game_controller._change_state(GameController.GameState.ROUND_ACTIVE)
	game_controller.round_start_time = Time.get_time_dict_from_system()["unix"]
	
	# Issue false evacuation
	game_controller.process_decisions(["Puerto Shan"], "EVACUATE NOW", "HIGH")
	
	assert_eq(game_controller.current_state, GameController.GameState.CAREER_TERMINATED, "Should terminate career")
	assert_true(game_controller.player_stats.is_career_terminated(), "Player stats should show termination")

func test_missed_threat_termination():
	# Setup major threat scenario
	game_controller.current_scenario = test_scenario  # Hurricane Elena
	game_controller._change_state(GameController.GameState.ROUND_ACTIVE)
	game_controller.round_start_time = Time.get_time_dict_from_system()["unix"]
	
	# Miss the evacuation call
	game_controller.process_decisions(["Puerto Shan"], "WEATHER ADVISORY", "LOW")
	
	assert_eq(game_controller.current_state, GameController.GameState.CAREER_TERMINATED, "Should terminate career")

func test_lives_impact_calculation():
	var correct_eval = {"correct": true}
	var hurricane_scenario = test_scenario  # Threat level 5
	
	var lives_saved = game_controller._calculate_lives_impact(correct_eval, hurricane_scenario)
	assert_eq(lives_saved, 500, "Should save 500 lives for correct hurricane response")
	
	var incorrect_eval = {"correct": false, "false_evacuation": true, "missed_threat": false}
	var lives_lost = game_controller._calculate_lives_impact(incorrect_eval, hurricane_scenario)
	assert_eq(lives_lost, -100, "Should lose 100 lives for false evacuation")

func test_economic_impact_calculation():
	var correct_eval = {"correct": true}
	var hurricane_scenario = test_scenario  # Threat level 5
	
	var economic_benefit = game_controller._calculate_economic_impact(correct_eval, hurricane_scenario)
	assert_eq(economic_benefit, 500000, "Should have positive economic impact for correct response")
	
	var false_evac_eval = {"correct": false, "false_evacuation": true, "missed_threat": false}
	var economic_cost = game_controller._calculate_economic_impact(false_evac_eval, hurricane_scenario)
	assert_eq(economic_cost, -500000, "Should have major economic cost for false evacuation")

func test_performance_evaluation():
	# Setup some game progress
	game_controller.current_round = 5
	game_controller.player_stats.successful_rounds = 3
	game_controller.player_stats.total_rounds = 5
	game_controller.player_stats.career_level = "Junior Forecaster"
	
	var performance = game_controller.evaluate_performance()
	
	assert_eq(performance["current_round"], 5, "Should report current round")
	assert_eq(performance["career_level"], "Junior Forecaster", "Should report career level")
	assert_eq(performance["accuracy_rate"], 0.6, "Should calculate accuracy rate")
	assert_false(performance["career_terminated"], "Should not be terminated")

func test_round_timer_functionality():
	game_controller.set_debug_mode(false)  # Enable timers
	game_controller.max_round_time = 2.0   # Short timer for testing
	
	game_controller.start_round()
	
	assert_true(game_controller.is_round_active(), "Round should be active")
	assert_true(game_controller.get_time_remaining() > 0, "Should have time remaining")
	
	# Wait for timer to expire
	await wait_seconds(3.0)
	
	assert_eq(game_controller.current_state, GameController.GameState.FEEDBACK, "Should move to feedback after timeout")

func test_game_completion():
	# Setup near end of career
	game_controller.current_round = game_controller.scenarios_per_career - 1
	game_controller.player_stats.successful_rounds = 40
	
	game_controller.end_round()
	
	assert_eq(game_controller.current_state, GameController.GameState.GAME_OVER, "Should complete game")

func test_component_connections():
	var mock_radar = MapRadar.new()
	var mock_interface = Control.new()
	var mock_feedback = Control.new()
	
	game_controller.set_map_radar(mock_radar)
	game_controller.set_decision_interface(mock_interface)
	game_controller.set_feedback_system(mock_feedback)
	
	assert_eq(game_controller.map_radar, mock_radar, "Should connect map radar")
	assert_eq(game_controller.decision_interface, mock_interface, "Should connect decision interface")
	assert_eq(game_controller.feedback_system, mock_feedback, "Should connect feedback system")
	
	mock_radar.queue_free()
	mock_interface.queue_free()
	mock_feedback.queue_free()

func test_pause_resume_functionality():
	game_controller.start_round()
	
	game_controller.pause_game()
	assert_true(game_controller.timer_node.paused, "Timer should be paused")
	
	game_controller.resume_game()
	assert_false(game_controller.timer_node.paused, "Timer should be resumed")

func test_restart_functionality():
	# Setup some game progress
	game_controller.current_round = 5
	game_controller.start_round()
	
	game_controller.restart_game()
	
	assert_eq(game_controller.current_round, 1, "Should restart at round 1")
	assert_eq(game_controller.current_state, GameController.GameState.ROUND_ACTIVE, "Should be in active state")

func test_debug_mode():
	game_controller.set_debug_mode(true)
	
	assert_true(game_controller.debug_mode, "Debug mode should be enabled")
	assert_true(game_controller.skip_timers, "Should skip timers in debug mode")
	
	var debug_info = game_controller.get_debug_info()
	assert_has(debug_info, "current_state", "Debug info should include current state")
	assert_has(debug_info, "current_round", "Debug info should include current round")

func test_signal_emissions():
	var state_changed_received = false
	var round_started_received = false
	
	game_controller.state_changed.connect(func(state): state_changed_received = true)
	game_controller.round_started.connect(func(round, scenario): round_started_received = true)
	
	game_controller.start_round()
	
	assert_true(state_changed_received, "Should emit state_changed signal")
	assert_true(round_started_received, "Should emit round_started signal")