class_name PlayerStats extends Resource

# Career progression tracking
@export var accuracy_rate: float = 0.0
@export var response_time_avg: float = 0.0
@export var lives_saved: int = 0
@export var economic_impact: int = 0
@export var career_level: String = "Trainee Meteorologist"
@export var successful_rounds: int = 0
@export var total_rounds: int = 0
@export var false_evacuations: int = 0
@export var missed_threats: int = 0

# Career level thresholds
const CAREER_LEVELS = {
	"Trainee Meteorologist": 0,
	"Junior Forecaster": 5,
	"Senior Forecaster": 15,
	"Lead Meteorologist": 30,
	"Chief Meteorologist": 50,
	"Master Forecaster": 100
}

func _init():
	reset_stats()

func reset_stats():
	"""Initialize or reset all player statistics to default values"""
	accuracy_rate = 0.0
	response_time_avg = 0.0
	lives_saved = 0
	economic_impact = 0
	career_level = "Trainee Meteorologist"
	successful_rounds = 0
	total_rounds = 0
	false_evacuations = 0
	missed_threats = 0

func update_round_stats(success: bool, response_time: float, lives_impact: int, economic_cost: int):
	"""Update statistics after completing a round"""
	total_rounds += 1
	
	if success:
		successful_rounds += 1
		lives_saved += lives_impact
		economic_impact += economic_cost
	
	# Update accuracy rate
	accuracy_rate = float(successful_rounds) / float(total_rounds) if total_rounds > 0 else 0.0
	
	# Update average response time
	if total_rounds == 1:
		response_time_avg = response_time
	else:
		response_time_avg = (response_time_avg * (total_rounds - 1) + response_time) / total_rounds
	
	# Check for career advancement
	update_career_level()

func record_false_evacuation():
	"""Record a false evacuation - career ending event"""
	false_evacuations += 1

func record_missed_threat():
	"""Record a missed major threat - career ending event"""
	missed_threats += 1

func update_career_level():
	"""Update career level based on successful rounds"""
	for level in CAREER_LEVELS.keys():
		if successful_rounds >= CAREER_LEVELS[level]:
			career_level = level

func get_career_progress() -> Dictionary:
	"""Get current career progress information"""
	var current_threshold = CAREER_LEVELS[career_level]
	var next_level = get_next_career_level()
	var next_threshold = CAREER_LEVELS[next_level] if next_level != career_level else current_threshold
	
	return {
		"current_level": career_level,
		"next_level": next_level,
		"current_threshold": current_threshold,
		"next_threshold": next_threshold,
		"progress": successful_rounds,
		"progress_to_next": next_threshold - successful_rounds if next_level != career_level else 0
	}

func get_next_career_level() -> String:
	"""Get the next career level or current if at maximum"""
	var levels = CAREER_LEVELS.keys()
	var current_index = levels.find(career_level)
	
	if current_index < levels.size() - 1:
		return levels[current_index + 1]
	else:
		return career_level  # Already at maximum level

func is_career_terminated() -> bool:
	"""Check if career has been terminated due to critical errors"""
	return false_evacuations > 0 or missed_threats > 0

func get_performance_summary() -> Dictionary:
	"""Get comprehensive performance summary"""
	return {
		"accuracy_rate": accuracy_rate,
		"response_time_avg": response_time_avg,
		"lives_saved": lives_saved,
		"economic_impact": economic_impact,
		"career_level": career_level,
		"successful_rounds": successful_rounds,
		"total_rounds": total_rounds,
		"false_evacuations": false_evacuations,
		"missed_threats": missed_threats,
		"career_terminated": is_career_terminated()
	}