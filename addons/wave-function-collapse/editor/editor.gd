extends Node3D
################################################################################
## Constants

################################################################################
## Members

@onready var camera : Camera3D = $Camera
@onready var generator : NodeWFC = $Generator
@onready var ui : Control = $UI

################################################################################
## Engine Methods

func _process(delta: float) -> void:
	if not generator.is_collapsing() and ui.disabled:
		ui.disabled = false

################################################################################
## UI Signals


func _on_ui_seed_updated(p_seed: int) -> void:
	generator.seed = p_seed
	print("seed:",generator.seed)


func _on_ui_dimension_updated(p_dimension: Vector3i) -> void:
	generator.dimensions = p_dimension
	print("dimensions:",generator.dimensions)


func _on_ui_cell_size_updated(p_cell_size: float) -> void:
	generator.cell_size = p_cell_size
	print("cell size:",generator.cell_size)


func _on_ui_animate_speed_updated(p_animate_speed: float) -> void:
	generator.animate_speed = p_animate_speed
	print("animate speed:",generator.animate_speed)


func _on_ui_animate_flag_updated(p_flag: bool) -> void:
	generator.animate = p_flag
	print("animate:",generator.animate)


func _on_ui_generate_button_pressed() -> void:
	if not generator.is_collapsing():
		ui.disabled = true
		generator.collapse()
