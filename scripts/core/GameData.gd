extends Node

# Global game data persistence

# Score tracking
var current_score: int = 0
var high_score: int = 0

func _ready():
	# Load saved data
	_load_game_data()

func set_score(score: int):
	"""Set the current score"""
	current_score = score
	if score > high_score:
		high_score = score
	_save_game_data()

func get_score() -> int:
	"""Get the current score"""
	return current_score

func get_high_score() -> int:
	"""Get the high score"""
	return high_score

func reset_score():
	"""Reset current score to 0"""
	current_score = 0

func _save_game_data():
	"""Save game data to file"""
	var save_file = FileAccess.open("user://gamedata.save", FileAccess.WRITE)
	if save_file:
		var save_data = {
			"current_score": current_score,
			"high_score": high_score
		}
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()

func _load_game_data():
	"""Load game data from file"""
	var save_file = FileAccess.open("user://gamedata.save", FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var save_data = json.data
			current_score = save_data.get("current_score", 0)
			high_score = save_data.get("high_score", 0)
