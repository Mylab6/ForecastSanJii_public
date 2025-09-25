extends Control

var score_label: Label
var continue_button: Button

func _ready():
	_setup_ui()
	
	# Start with faded elements for animation
	score_label.modulate.a = 0
	continue_button.modulate.a = 0
	
	# Load scores saved by the previous scene
	var total_score = get_tree().get_meta("last_score", 0)
	var round_score = get_tree().get_meta("round_score", 0)
	var ideal_score = get_tree().get_meta("ideal_score", 0)
	var high_score = get_tree().get_meta("high_score", 0)
	var is_new_high = get_tree().get_meta("is_new_high", false)

	# Ensure scores are valid
	if total_score < 0:
		total_score = 0
	if round_score < 0:
		round_score = 0
	if ideal_score < 0:
		ideal_score = 0
	if high_score < 0:
		high_score = 0

	# Update score display with colors and feedback
	_update_score_display(total_score, round_score, ideal_score, high_score, is_new_high)
	
	# Animate in the UI elements
	_animate_ui_in()

func _setup_ui():
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.2, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Title
	var title = Label.new()
	title.text = "Scoreboard"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.position.y = 100
	add_child(title)
	
	# Score label
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color.YELLOW)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	score_label.position.y = -50
	add_child(score_label)
	
	# Continue button with better styling
	continue_button = Button.new()
	continue_button.text = "Continue to Next Round"
	continue_button.add_theme_font_size_override("font_size", 20)
	continue_button.custom_minimum_size = Vector2(300, 60)
	continue_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	continue_button.position.y = 150
	continue_button.position.x = -150
	continue_button.add_theme_color_override("font_color", Color.WHITE)
	continue_button.add_theme_color_override("font_color_hover", Color.YELLOW)
	continue_button.pressed.connect(Callable(self, "_on_continue_pressed"))
	add_child(continue_button)

func _update_score_display(total_score: int, round_score: int, ideal_score: int, high_score: int, is_new_high: bool):
	"""Update the score display with colors and performance feedback"""
	var performance_message = ""
	var score_color = Color.YELLOW
	
	# Determine performance based on score vs ideal
	var score_ratio = float(round_score) / float(ideal_score) if ideal_score > 0 else 0.0
	
	if score_ratio >= 0.9:
		performance_message = "Outstanding! Perfect weather prediction!"
		score_color = Color.GREEN
	elif score_ratio >= 0.7:
		performance_message = "Great job! Good emergency management."
		score_color = Color(0.5, 1.0, 0.5)  # Light green
	elif score_ratio >= 0.5:
		performance_message = "Decent performance. Room for improvement."
		score_color = Color.YELLOW
	else:
		performance_message = "Needs work. Study the weather patterns more carefully."
		score_color = Color.ORANGE
	
	# Add high score message
	var high_score_message = ""
	if is_new_high:
		high_score_message = "
🎉 NEW HIGH SCORE! 🎉"
		score_color = Color.CYAN
	elif total_score == high_score:
		high_score_message = "
Tied your high score!"
	
	score_label.text = "Round Complete!
Round Score: %d
Total Score: %d
Ideal Score: %d
High Score: %d%s

%s" % [
		round_score, total_score, ideal_score, high_score, high_score_message, performance_message
	]
	score_label.add_theme_color_override("font_color", score_color)

func _animate_ui_in():
	"""Animate the UI elements fading in"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in score label
	tween.tween_property(score_label, "modulate:a", 1.0, 0.8).set_delay(0.2)
	
	# Fade in continue button
	tween.tween_property(continue_button, "modulate:a", 1.0, 0.8).set_delay(0.5)
	# Return to radar demo (next round)
	get_tree().change_scene_to_file("res://radar_demo.tscn")
