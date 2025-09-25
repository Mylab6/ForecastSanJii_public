class_name GameSetup extends Control

# Game setup scene for configuring the weather radar game

@onready var city_count_spin: SpinBox = $VBoxContainer/CityCountContainer/CityCountSpinBox
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var title_label: Label = $VBoxContainer/TitleLabel

var selected_city_count: int = 5

signal game_ready(city_count: int)

func _ready():
	setup_ui()
	connect_signals()

func setup_ui():
	title_label.text = "Forecast San Jii - Weather Radar Setup"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Configure city count spinner
	city_count_spin.min_value = 3
	city_count_spin.max_value = 7
	city_count_spin.step = 2
	city_count_spin.value = 5
	
	start_button.text = "Start Weather Simulation"

func connect_signals():
	city_count_spin.value_changed.connect(_on_city_count_changed)
	start_button.pressed.connect(_on_start_pressed)

func _on_city_count_changed(value: float):
	selected_city_count = int(value)
	print("Selected city count: ", selected_city_count)

func _on_start_pressed():
	print("Starting game with ", selected_city_count, " cities")
	game_ready.emit(selected_city_count)
