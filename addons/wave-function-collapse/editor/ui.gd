extends Control
################################################################################
## UI Components

@onready var seed_spinbox : SpinBox = $MarginContainer/MarginContainer2/VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/SeedOption/HFlowContainer/SpinBox
@onready var dimension_x_spinbox : SpinBox = $MarginContainer/MarginContainer2/VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/DimensionsOption/VBoxContainer/HFlowContainer/x
@onready var dimension_y_spinbox : SpinBox = $MarginContainer/MarginContainer2/VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/DimensionsOption/VBoxContainer/HFlowContainer/y
@onready var dimension_z_spinbox : SpinBox = $MarginContainer/MarginContainer2/VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/DimensionsOption/VBoxContainer/HFlowContainer/z
@onready var cell_size_spinbox : SpinBox = $MarginContainer/MarginContainer2/VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/CellSizeOption/HFlowContainer/SpinBox
@onready var animate_flag_checkbutton : CheckButton = $MarginContainer/MarginContainer2/VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/AnimateOption/HFlowContainer/CheckButton
@onready var animate_speed_slider : HSlider = $MarginContainer/MarginContainer2/VBoxContainer/VBoxContainer/PanelContainer/VBoxContainer/AnimateSpeedOption/HFlowContainer/HSlider

################################################################################
## Members

signal generate_button_pressed
signal seed_updated(p_seed : int)
signal dimension_updated(p_dimension : Vector3i)
signal cell_size_updated(p_cell_size : float)
signal animate_flag_updated(p_flag : bool)
signal animate_speed_updated(p_animate_speed : float)

var disabled : bool = false: set = _set_disabled

var _seed_value : int = 42: set = _set_seed_value
var _dimension_value : Vector3i = Vector3i(5,1,5): set = _set_dimension_value
var _cell_size_value : float = 1.0: set = _set_cell_size_value
var _animate_flag_value : bool = true: set = _set_animate_flag_value
var _animate_speed_value : float = 1.0: set = _set_animate_speed_value

################################################################################
## Engine Methods

################################################################################
## Signals

func _on_gui_input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton: grab_focus()


func _on_seed_value_changed(p_value: float) -> void:
	_seed_value = p_value as int
	seed_updated.emit(_seed_value)


func _on_dimension_x_value_changed(p_value : float) -> void:
	var x : int = p_value as int
	var d : Vector3i = _dimension_value; d.x = x
	_dimension_value = d


func _on_dimension_y_value_changed(p_value : float) -> void:
	var y : int = p_value as int
	var d : Vector3i = _dimension_value; d.y = y
	_dimension_value = d


func _on_dimension_z_value_changed(p_value : float) -> void:
	var z : int = p_value as int
	var d : Vector3i = _dimension_value; d.z = z
	_dimension_value = d


func _on_cell_size_value_changed(p_value : float) -> void:
	_cell_size_value = p_value


func _on_animate_flag_value_changed(p_value : bool) -> void:
	_animate_flag_value = p_value


func _on_animate_speed_value_changed(p_value : float) -> void:
	_animate_speed_value = p_value

################################################################################
## Setters/Getters

func _set_disabled(p_disabled : bool) -> void:
	disabled = p_disabled
	seed_spinbox.editable = not disabled
	dimension_x_spinbox.editable = not disabled
	dimension_y_spinbox.editable = not disabled
	dimension_z_spinbox.editable = not disabled
	cell_size_spinbox.editable = not disabled
	animate_flag_checkbutton.disabled = disabled
	animate_speed_slider.editable = not disabled


func _set_seed_value(p_seed_value: int) -> void:
	_seed_value = p_seed_value
	seed_updated.emit(_seed_value)


func _set_dimension_value(p_dimension_value: Vector3i) -> void:
	_dimension_value = p_dimension_value
	dimension_updated.emit(_dimension_value)


func _set_cell_size_value(p_cell_size_value: float) -> void:
	_cell_size_value = p_cell_size_value
	cell_size_updated.emit(_cell_size_value)


func _set_animate_flag_value(p_animate_flag_value: bool) -> void:
	_animate_flag_value = p_animate_flag_value
	animate_flag_updated.emit(_animate_flag_value)


func _set_animate_speed_value(p_animate_speed_value: float) -> void:
	_animate_speed_value = p_animate_speed_value
	animate_speed_updated.emit(_animate_speed_value)


func _on_generate_button_pressed() -> void:
	generate_button_pressed.emit()
