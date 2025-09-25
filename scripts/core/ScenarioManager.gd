class_name ScenarioManager extends Node

# Weather scenario generation and management system
# Handles diverse weather patterns, geographic positioning, and difficulty progression

# Scenario configuration
@export var enable_difficulty_progression: bool = true
@export var seasonal_variation: bool = true
@export var geographic_realism: bool = true
@export var storm_evolution: bool = true

# Difficulty settings
@export var easy_round_threshold: int = 5
@export var medium_round_threshold: int = 15
@export var hard_round_threshold: int = 25

# Geographic data for San Jii Metro
var geographic_regions = {
	"coastal": {
		"areas": ["Puerto Shan", "Bahía Azul", "Playa Hai"],
		"storm_types": ["Hurricane", "Sea Breeze", "Tropical Storm"],
		"typical_intensity": 45.0,
		"movement_patterns": [Vector2(10, -15), Vector2(-5, -20), Vector2(15, -10)]
	},
	"mountainous": {
		"areas": ["Montaña-Long Ridge", "Valle Gu"],
		"storm_types": ["Orographic", "Supercell", "Multi-Cell"],
		"typical_intensity": 50.0,
		"movement_patterns": [Vector2(5, -25), Vector2(-10, -15), Vector2(20, -8)]
	},
	"urban": {
		"areas": ["San Jii", "Ciudad Long"],
		"storm_types": ["Urban Heat Island", "Supercell", "Multi-Cell"],
		"typical_intensity": 48.0,
		"movement_patterns": [Vector2(15, -12), Vector2(8, -18), Vector2(25, -5)]
	},
	"rural": {
		"areas": ["Valle Gu", "Rural Areas"],
		"storm_types": ["Scattered Thunderstorms", "Squall Line"],
		"typical_intensity": 35.0,
		"movement_patterns": [Vector2(12, -10), Vector2(18, -15), Vector2(6, -20)]
	}
}

# Seasonal weather patterns
var seasonal_patterns = {
	"hurricane_season": {
		"months": [6, 7, 8, 9, 10, 11],  # June through November
		"storm_types": ["Hurricane", "Tropical Storm", "Tropical Depression"],
		"intensity_modifier": 1.3,
		"frequency_modifier": 2.0
	},
	"dry_season": {
		"months": [12, 1, 2, 3],  # December through March
		"storm_types": ["Sea Breeze", "Orographic"],
		"intensity_modifier": 0.7,
		"frequency_modifier": 0.5
	},
	"wet_season": {
		"months": [4, 5],  # April and May
		"storm_types": ["Multi-Cell", "Supercell", "Scattered Thunderstorms"],
		"intensity_modifier": 1.1,
		"frequency_modifier": 1.2
	}
}

# Predefined scenario templates with enhanced variety
var enhanced_scenarios = {
	"Hurricane Elena - Category 4": {
		"storm_type": "Hurricane",
		"threat_level": 5,
		"storm_intensity": 65.0,
		"movement_pattern": Vector2(15, -10),
		"affected_areas": ["Puerto Shan", "Bahía Azul", "San Jii"],
		"correct_response": "EVACUATE NOW",
		"correct_priority": "HIGH",
		"geographic_region": "coastal",
		"duration_hours": 8,
		"radar_signature": {
			"eyewall": true,
			"spiral_bands": true,
			"eye_diameter": 25,
			"storm_surge_risk": true
		}
	},
	"Hurricane Elena - Category 2": {
		"storm_type": "Hurricane",
		"threat_level": 4,
		"storm_intensity": 55.0,
		"movement_pattern": Vector2(12, -8),
		"affected_areas": ["Puerto Shan", "Bahía Azul"],
		"correct_response": "SHELTER IN PLACE",
		"correct_priority": "HIGH",
		"geographic_region": "coastal",
		"duration_hours": 6,
		"radar_signature": {
			"eyewall": true,
			"spiral_bands": true,
			"eye_diameter": 35
		}
	},
	"CIUDADLONG Supercell Complex": {
		"storm_type": "Supercell",
		"threat_level": 4,
		"storm_intensity": 58.0,
		"movement_pattern": Vector2(25, -15),
		"affected_areas": ["Ciudad Long", "San Jii"],
		"correct_response": "SHELTER IN PLACE",
		"correct_priority": "HIGH",
		"geographic_region": "urban",
		"duration_hours": 3,
		"radar_signature": {
			"hook_echo": true,
			"mesocyclone": true,
			"bounded_weak_echo": true,
			"tornado_risk": true
		}
	},
	"Montaña Ridge Orographic Enhancement": {
		"storm_type": "Orographic",
		"threat_level": 3,
		"storm_intensity": 48.0,
		"movement_pattern": Vector2(5, -20),
		"affected_areas": ["Montaña-Long Ridge", "Valle Gu"],
		"correct_response": "SHELTER IN PLACE",
		"correct_priority": "MEDIUM",
		"geographic_region": "mountainous",
		"duration_hours": 4,
		"radar_signature": {
			"orographic_enhancement": true,
			"terrain_blocking": true,
			"upslope_intensification": true
		}
	},
	"PUERTOSHAN Sea Breeze Convergence": {
		"storm_type": "Sea Breeze",
		"threat_level": 2,
		"storm_intensity": 35.0,
		"movement_pattern": Vector2(8, 5),
		"affected_areas": ["Puerto Shan", "Playa Hai"],
		"correct_response": "WEATHER ADVISORY",
		"correct_priority": "LOW",
		"geographic_region": "coastal",
		"duration_hours": 2,
		"radar_signature": {
			"convective_cells": true,
			"sea_breeze_convergence": true,
			"afternoon_development": true
		}
	},
	"Multi-Cell Squall Line": {
		"storm_type": "Multi-Cell",
		"threat_level": 4,
		"storm_intensity": 52.0,
		"movement_pattern": Vector2(20, -12),
		"affected_areas": ["San Jii", "Ciudad Long", "Puerto Shan"],
		"correct_response": "SHELTER IN PLACE",
		"correct_priority": "HIGH",
		"geographic_region": "urban",
		"duration_hours": 4,
		"radar_signature": {
			"multiple_cells": true,
			"bow_echo": true,
			"rear_inflow_jet": true,
			"wind_damage_risk": true
		}
	},
	"Valle Gu Flash Flood Risk": {
		"storm_type": "Scattered Thunderstorms",
		"threat_level": 3,
		"storm_intensity": 42.0,
		"movement_pattern": Vector2(6, -18),
		"affected_areas": ["Valle Gu"],
		"correct_response": "WEATHER ADVISORY",
		"correct_priority": "MEDIUM",
		"geographic_region": "rural",
		"duration_hours": 3,
		"radar_signature": {
			"training_storms": true,
			"slow_movement": true,
			"flash_flood_risk": true
		}
	},
	"Tropical Storm Beta": {
		"storm_type": "Tropical Storm",
		"threat_level": 3,
		"storm_intensity": 45.0,
		"movement_pattern": Vector2(18, -8),
		"affected_areas": ["Puerto Shan", "Bahía Azul", "Playa Hai"],
		"correct_response": "SHELTER IN PLACE",
		"correct_priority": "MEDIUM",
		"geographic_region": "coastal",
		"duration_hours": 6,
		"radar_signature": {
			"tropical_bands": true,
			"asymmetric_structure": true,
			"storm_surge_minor": true
		}
	}
}

# Current scenario state
var current_scenario: WeatherScenario
var scenario_history: Array[String] = []
var current_season: String = "hurricane_season"
var evolution_timer: float = 0.0

func _ready():
	print("ScenarioManager initialized")
	_update_current_season()

func generate_scenario_for_round(round_number: int) -> WeatherScenario:
	"""Generate appropriate scenario based on round number and difficulty progression"""
	print("Generating scenario for round ", round_number)
	
	var scenario = WeatherScenario.new()
	var template_name = _select_scenario_template(round_number)
	
	if not template_name:
		print("ERROR: Failed to select scenario template")
		return null
	
	# Load base template
	if not _load_enhanced_template(scenario, template_name):
		print("ERROR: Failed to load template: ", template_name)
		return null
	
	# Apply geographic positioning
	if geographic_realism:
		_apply_geographic_positioning(scenario)
	
	# Apply seasonal variations
	if seasonal_variation:
		_apply_seasonal_variations(scenario)
	
	# Apply difficulty scaling
	if enable_difficulty_progression:
		_apply_difficulty_scaling(scenario, round_number)
	
	# Add to history
	scenario_history.append(template_name)
	current_scenario = scenario
	
	print("Generated scenario: ", scenario.scenario_name)
	return scenario

func _select_scenario_template(round_number: int) -> String:
	"""Select appropriate scenario template based on difficulty progression"""
	var available_templates: Array[String] = []
	
	if enable_difficulty_progression:
		if round_number <= easy_round_threshold:
			# Easy scenarios
			available_templates = [
				"PUERTOSHAN Sea Breeze Convergence",
				"Valle Gu Flash Flood Risk",
				"Montaña Ridge Orographic Enhancement"
			]
		elif round_number <= medium_round_threshold:
			# Medium scenarios
			available_templates = [
				"Tropical Storm Beta",
				"Hurricane Elena - Category 2",
				"Multi-Cell Squall Line"
			]
		elif round_number <= hard_round_threshold:
			# Hard scenarios
			available_templates = [
				"CIUDADLONG Supercell Complex",
				"Hurricane Elena - Category 4",
				"Multi-Cell Squall Line"
			]
		else:
			# Expert scenarios - all available
			available_templates = enhanced_scenarios.keys()
	else:
		# Random selection from all scenarios
		available_templates = enhanced_scenarios.keys()
	
	# Apply seasonal filtering
	if seasonal_variation:
		available_templates = _filter_by_season(available_templates)
	
	# Avoid recent repeats
	available_templates = _filter_recent_scenarios(available_templates)
	
	if available_templates.is_empty():
		# Fallback to any scenario if filtering is too restrictive
		available_templates = enhanced_scenarios.keys()
	
	# Select random template from available options
	return available_templates[randi() % available_templates.size()]

func _load_enhanced_template(scenario: WeatherScenario, template_name: String) -> bool:
	"""Load enhanced scenario template with additional data"""
	if not enhanced_scenarios.has(template_name):
		return false
	
	var template = enhanced_scenarios[template_name]
	
	# Load basic scenario data
	scenario.scenario_name = template_name
	scenario.storm_type = template["storm_type"]
	scenario.threat_level = template["threat_level"]
	scenario.storm_intensity = template["storm_intensity"]
	scenario.movement_pattern = template["movement_pattern"]
	scenario.affected_areas = template["affected_areas"].duplicate()
	scenario.correct_response = template["correct_response"]
	scenario.correct_priority = template["correct_priority"]
	scenario.correct_areas = template["affected_areas"].duplicate()
	scenario.radar_signature = template["radar_signature"].duplicate()
	
	# Add enhanced data
	if template.has("duration_hours"):
		scenario.duration_minutes = template["duration_hours"] * 60
	
	return true

func _apply_geographic_positioning(scenario: WeatherScenario):
	"""Apply realistic geographic positioning based on storm type and affected areas"""
	var primary_region = _determine_primary_region(scenario.affected_areas)
	
	if not primary_region:
		return
	
	var region_data = geographic_regions[primary_region]
	
	# Adjust storm characteristics based on geography
	match primary_region:
		"coastal":
			# Coastal storms tend to be more intense due to ocean energy
			scenario.storm_intensity *= 1.1
			# Add storm surge risk for hurricanes
			if scenario.storm_type == "Hurricane":
				scenario.radar_signature["storm_surge_risk"] = true
		
		"mountainous":
			# Mountain storms can be enhanced by orographic lifting
			if scenario.storm_type in ["Supercell", "Multi-Cell"]:
				scenario.storm_intensity *= 1.05
				scenario.radar_signature["orographic_enhancement"] = true
		
		"urban":
			# Urban heat island can intensify storms
			scenario.storm_intensity *= 1.03
			scenario.radar_signature["urban_heat_island"] = true
		
		"rural":
			# Rural areas may have less intense but more widespread storms
			scenario.storm_intensity *= 0.95

func _apply_seasonal_variations(scenario: WeatherScenario):
	"""Apply seasonal weather pattern variations"""
	var season_data = seasonal_patterns[current_season]
	
	# Apply intensity modifier
	scenario.storm_intensity *= season_data["intensity_modifier"]
	
	# Adjust storm characteristics based on season
	match current_season:
		"hurricane_season":
			# Hurricane season brings more intense tropical systems
			if scenario.storm_type in ["Hurricane", "Tropical Storm"]:
				scenario.storm_intensity *= 1.2
				scenario.movement_pattern *= 1.1  # Faster movement
		
		"dry_season":
			# Dry season has weaker, more localized storms
			scenario.storm_intensity *= 0.8
			if scenario.storm_type == "Sea Breeze":
				scenario.storm_intensity *= 1.1  # Sea breeze more prominent
		
		"wet_season":
			# Wet season has more persistent, training storms
			if scenario.storm_type in ["Multi-Cell", "Scattered Thunderstorms"]:
				scenario.movement_pattern *= 0.7  # Slower movement
				scenario.radar_signature["training_storms"] = true

func _apply_difficulty_scaling(scenario: WeatherScenario, round_number: int):
	"""Apply difficulty scaling based on round progression"""
	var difficulty_factor = 1.0 + (round_number - 1) * 0.02  # 2% increase per round
	
	# Scale storm intensity
	scenario.storm_intensity *= difficulty_factor
	
	# Add complexity for higher rounds
	if round_number > 10:
		# Add multiple affected areas for complex scenarios
		if scenario.affected_areas.size() == 1 and randf() < 0.3:
			var additional_areas = _get_adjacent_areas(scenario.affected_areas[0])
			if not additional_areas.is_empty():
				scenario.affected_areas.append(additional_areas[0])
				scenario.correct_areas.append(additional_areas[0])
	
	if round_number > 20:
		# Add storm evolution and movement changes
		scenario.radar_signature["storm_evolution"] = true
		scenario.movement_pattern *= randf_range(0.8, 1.3)  # Variable movement

func _determine_primary_region(affected_areas: Array[String]) -> String:
	"""Determine primary geographic region based on affected areas"""
	var region_scores = {}
	
	for region in geographic_regions:
		region_scores[region] = 0
		var region_areas = geographic_regions[region]["areas"]
		
		for area in affected_areas:
			if area in region_areas:
				region_scores[region] += 1
	
	# Find region with highest score
	var max_score = 0
	var primary_region = ""
	
	for region in region_scores:
		if region_scores[region] > max_score:
			max_score = region_scores[region]
			primary_region = region
	
	return primary_region

func _get_adjacent_areas(area: String) -> Array[String]:
	"""Get areas adjacent to the given area"""
	var adjacent_map = {
		"San Jii": ["Ciudad Long", "Puerto Shan"],
		"Ciudad Long": ["San Jii", "Montaña-Long Ridge"],
		"Puerto Shan": ["San Jii", "Bahía Azul", "Playa Hai"],
		"Bahía Azul": ["Puerto Shan", "Playa Hai"],
		"Playa Hai": ["Puerto Shan", "Bahía Azul"],
		"Montaña-Long Ridge": ["Ciudad Long", "Valle Gu"],
		"Valle Gu": ["Montaña-Long Ridge"]
	}
	
	if adjacent_map.has(area):
		return adjacent_map[area]
	else:
		return []

func _filter_by_season(templates: Array[String]) -> Array[String]:
	"""Filter scenario templates based on current season"""
	var season_data = seasonal_patterns[current_season]
	var seasonal_storm_types = season_data["storm_types"]
	var filtered: Array[String] = []
	
	for template_name in templates:
		var template = enhanced_scenarios[template_name]
		if template["storm_type"] in seasonal_storm_types:
			filtered.append(template_name)
	
	# If no seasonal matches, return original list
	return filtered if not filtered.is_empty() else templates

func _filter_recent_scenarios(templates: Array[String]) -> Array[String]:
	"""Filter out recently used scenarios to avoid repetition"""
	var recent_count = min(3, scenario_history.size())
	var recent_scenarios = scenario_history.slice(-recent_count)
	var filtered: Array[String] = []
	
	for template_name in templates:
		if not template_name in recent_scenarios:
			filtered.append(template_name)
	
	# If all scenarios are recent, return original list
	return filtered if not filtered.is_empty() else templates

func _update_current_season():
	"""Update current season based on system date"""
	var date = Time.get_date_dict_from_system()
	var month = date["month"]
	
	for season in seasonal_patterns:
		var season_months = seasonal_patterns[season]["months"]
		if month in season_months:
			current_season = season
			break
	
	print("Current season: ", current_season)

func evolve_current_scenario(delta_time: float):
	"""Evolve current scenario over time if storm evolution is enabled"""
	if not current_scenario or not storm_evolution:
		return
	
	evolution_timer += delta_time
	
	# Evolve storm every 30 seconds
	if evolution_timer >= 30.0:
		evolution_timer = 0.0
		_apply_storm_evolution()

func _apply_storm_evolution():
	"""Apply realistic storm evolution patterns"""
	if not current_scenario:
		return
	
	match current_scenario.storm_type:
		"Hurricane":
			# Hurricanes can intensify or weaken
			var intensity_change = randf_range(-5.0, 3.0)
			current_scenario.storm_intensity = clamp(
				current_scenario.storm_intensity + intensity_change,
				30.0, 70.0
			)
		
		"Supercell":
			# Supercells can develop new signatures
			if randf() < 0.3:
				current_scenario.radar_signature["tornado_warning"] = true
		
		"Multi-Cell":
			# Multi-cell storms can develop bow echoes
			if randf() < 0.4:
				current_scenario.radar_signature["bow_echo_development"] = true

# Public interface methods

func get_available_scenarios() -> Array[String]:
	"""Get list of all available scenario templates"""
	return enhanced_scenarios.keys()

func get_scenario_details(template_name: String) -> Dictionary:
	"""Get detailed information about a specific scenario template"""
	if enhanced_scenarios.has(template_name):
		return enhanced_scenarios[template_name]
	else:
		return {}

func get_current_scenario() -> WeatherScenario:
	"""Get the currently active scenario"""
	return current_scenario

func get_scenario_history() -> Array[String]:
	"""Get history of generated scenarios"""
	return scenario_history.duplicate()

func set_seasonal_override(season: String):
	"""Override automatic season detection"""
	if seasonal_patterns.has(season):
		current_season = season
		print("Season override set to: ", season)

func reset_scenario_history():
	"""Clear scenario history"""
	scenario_history.clear()
	print("Scenario history reset")

func get_geographic_info() -> Dictionary:
	"""Get geographic region information"""
	return geographic_regions.duplicate()

func validate_scenario_meteorology(scenario: WeatherScenario) -> Dictionary:
	"""Validate meteorological accuracy of scenario"""
	var validation = {
		"valid": true,
		"warnings": [],
		"errors": []
	}
	
	# Check intensity vs storm type consistency
	match scenario.storm_type:
		"Hurricane":
			if scenario.storm_intensity < 40.0:
				validation["warnings"].append("Hurricane intensity seems low for classification")
		"Sea Breeze":
			if scenario.storm_intensity > 40.0:
				validation["warnings"].append("Sea breeze intensity seems high")
	
	# Check geographic consistency
	var primary_region = _determine_primary_region(scenario.affected_areas)
	if primary_region == "mountainous" and scenario.storm_type == "Hurricane":
		validation["warnings"].append("Hurricane affecting primarily mountainous region is unusual")
	
	return validation