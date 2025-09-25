extends Node3D  # Make sure it’s a 3D node script

@onready var head = $HeadPivot
@export var max_nod := 10.0  # Use Godot 4 proper format
func _process(delta):
	if head:
		
		head.rotation_degrees.x = sin(Time.get_ticks_msec() *  0.005) * max_nod
