extends Node3D
################################################################################
## Constants

################################################################################
## Members

@onready var camera : Camera3D = $Camera
@onready var generator : NodeWFC = $Generator
@onready var ui : Control = $UI
@onready var edit_layer_plane : MeshInstance3D = $EditLayerPlane

var edit_mode : int = -1: set = _set_edit_mode

var _edit_mode_front_rear_clip : int = 0:
	set(value):
		if edit_mode == camera.OrthoViewFront:
			_edit_mode_front_rear_clip = clamp(value,0,generator.dimensions.z)
		if edit_mode == camera.OrthoViewRear:
			_edit_mode_front_rear_clip = clamp(value,-1,generator.dimensions.z-1)
		_set_edit_layer_position()
		_edit_mode_clip_tiles()

var _edit_mode_right_left_clip : int = 0:
	set(value):
		if edit_mode == camera.OrthoViewRight:
			_edit_mode_right_left_clip = clamp(value,0,generator.dimensions.x)
		if edit_mode == camera.OrthoViewLeft:
			_edit_mode_right_left_clip = clamp(value,-1,generator.dimensions.x-1)
		_set_edit_layer_position()
		_edit_mode_clip_tiles()

var _edit_mode_top_bottom_clip : int = 0:
	set(value):
		if edit_mode == camera.OrthoViewTop:
			_edit_mode_top_bottom_clip = clamp(value,0,generator.dimensions.y)
		if edit_mode == camera.OrthoViewBottom:
			_edit_mode_top_bottom_clip = clamp(value,-1,generator.dimensions.y-1)
		_set_edit_layer_position()
		_edit_mode_clip_tiles()

################################################################################
## Private Methods

func _set_edit_layer_position() -> void:
	var cell_size : float = generator.cell_size
	if edit_mode == camera.OrthoViewFront or edit_mode == camera.OrthoViewRear:
		edit_layer_plane.rotation = Vector3(PI*0.5,0,0)
		edit_layer_plane.position = generator.position + Vector3(0,0,_edit_mode_front_rear_clip + 0.5) * cell_size

	if edit_mode == camera.OrthoViewRight or edit_mode == camera.OrthoViewLeft:
		edit_layer_plane.rotation = Vector3(0,0,PI*0.5)
		edit_layer_plane.position = generator.position + Vector3(_edit_mode_right_left_clip+0.5,0,0) * cell_size

	if edit_mode == camera.OrthoViewTop or edit_mode == camera.OrthoViewBottom:
		edit_layer_plane.rotation = Vector3(0,0,0)
		edit_layer_plane.position = generator.position + Vector3(0,_edit_mode_top_bottom_clip,0) * cell_size


func _edit_mode_clip_tiles() -> void:
	var dimensions : Vector3i = generator.dimensions

	if edit_mode == camera.OrthoViewFront:
		for x in dimensions.x:
			for y in dimensions.y:
				for z in dimensions.z:
					var tile : Node3D = generator.get_tile_at(Vector3i(x,y,z))
					if not tile: continue
					if _edit_mode_front_rear_clip == -1:
						tile.visible = z == 0
					elif _edit_mode_front_rear_clip == dimensions.z:
						tile.visible = true
					else:
						tile.visible = z <= _edit_mode_front_rear_clip

	if edit_mode == camera.OrthoViewRear:
		for x in dimensions.x:
			for y in dimensions.y:
				for z in dimensions.z:
					var tile : Node3D = generator.get_tile_at(Vector3i(x,y,z))
					if not tile: continue
					if _edit_mode_front_rear_clip == -1:
						tile.visible = true
					elif _edit_mode_front_rear_clip == dimensions.z:
						tile.visible = z == dimensions.z - 1
					else:
						tile.visible = z >= _edit_mode_front_rear_clip

	if edit_mode == camera.OrthoViewRight:
		for y in dimensions.y:
			for z in dimensions.z:
				for x in dimensions.x:
					var tile : Node3D = generator.get_tile_at(Vector3i(x,y,z))
					if not tile: continue
					if _edit_mode_right_left_clip == -1:
						tile.visible = x == 0
					elif _edit_mode_right_left_clip == dimensions.x:
						tile.visible = true
					else:
						tile.visible = x <= _edit_mode_right_left_clip

	if edit_mode == camera.OrthoViewLeft:
		for y in dimensions.y:
			for z in dimensions.z:
				for x in dimensions.x:
					var tile : Node3D = generator.get_tile_at(Vector3i(x,y,z))
					if not tile: continue
					if _edit_mode_right_left_clip == -1:
						tile.visible = true
					elif _edit_mode_right_left_clip == dimensions.x:
						tile.visible = x == dimensions.x - 1
					else:
						tile.visible = x >= _edit_mode_right_left_clip

	if edit_mode == camera.OrthoViewTop:
		for x in dimensions.x:
			for z in dimensions.z:
				for y in dimensions.y:
					var tile : Node3D = generator.get_tile_at(Vector3i(x,y,z))
					if not tile: continue
					if _edit_mode_top_bottom_clip == -1:
						tile.visible = y == 0
					elif _edit_mode_top_bottom_clip == dimensions.y:
						tile.visible = true
					else:
						tile.visible = y <= _edit_mode_top_bottom_clip

	if edit_mode == camera.OrthoViewBottom:
		for x in dimensions.x:
			for z in dimensions.z:
				for y in dimensions.y:
					var tile : Node3D = generator.get_tile_at(Vector3i(x,y,z))
					if not tile: continue
					if _edit_mode_top_bottom_clip == -1:
						tile.visible = true
					elif _edit_mode_top_bottom_clip == dimensions.y:
						tile.visible = y == dimensions.y - 1
					else:
						tile.visible = y >= _edit_mode_top_bottom_clip


func _paint_tile(p_mouse_position : Vector2) -> void:
	var tile_position : Vector3i

	if edit_mode == camera.OrthoViewFront or edit_mode == camera.OrthoViewRear:
		tile_position = _calculate_projected_tile_position(p_mouse_position)
	if edit_mode == camera.OrthoViewRight or edit_mode == camera.OrthoViewLeft:
		tile_position = _calculate_projected_tile_position(p_mouse_position)
	if edit_mode == camera.OrthoViewTop or edit_mode == camera.OrthoViewBottom:
		tile_position = _calculate_projected_tile_position(p_mouse_position)

	var tile_id : String = ui.get_selected_tile_id()
	if tile_id != "": generator.place_tile(tile_id,tile_position)


func _erase_tile(p_mouse_position : Vector2) -> void:
	var tile_position : Vector3i

	if edit_mode == camera.OrthoViewFront or edit_mode == camera.OrthoViewRear:
		tile_position = _calculate_projected_tile_position(p_mouse_position)
	if edit_mode == camera.OrthoViewRight or edit_mode == camera.OrthoViewLeft:
		tile_position = _calculate_projected_tile_position(p_mouse_position)
	if edit_mode == camera.OrthoViewTop or edit_mode == camera.OrthoViewBottom:
		tile_position = _calculate_projected_tile_position(p_mouse_position)

	generator.remove_tile(tile_position)


func _calculate_projected_tile_position(p_mouse_position : Vector2) -> Vector3i:
	var cell_size : float = generator.cell_size
	var dimensions : Vector3 = generator.dimensions

	var zdistance : int
	var zdimension_size : int

	if edit_mode == camera.OrthoViewFront or edit_mode == camera.OrthoViewRear:
		zdistance = _edit_mode_front_rear_clip
		zdimension_size = dimensions.z
	if edit_mode == camera.OrthoViewRight or edit_mode == camera.OrthoViewLeft:
		zdistance = _edit_mode_right_left_clip
		zdimension_size = dimensions.x
	if edit_mode == camera.OrthoViewTop or edit_mode == camera.OrthoViewBottom:
		zdistance = _edit_mode_top_bottom_clip
		zdimension_size = dimensions.y

	var projected_position : Vector3 = camera.project_position(p_mouse_position,zdistance * cell_size)
	projected_position = projected_position - generator.position + Vector3i(1,1,1) * 0.5

	var tile_position : Vector3i = projected_position / cell_size

	if edit_mode == camera.OrthoViewFront or edit_mode == camera.OrthoViewRear:
		tile_position.z = zdistance
	if edit_mode == camera.OrthoViewRight or edit_mode == camera.OrthoViewLeft:
		tile_position.x = zdistance
	if edit_mode == camera.OrthoViewTop or edit_mode == camera.OrthoViewBottom:
		tile_position.y = zdistance

	return tile_position


func _set_status_bar() -> void:
	var mouse_position : Vector2 = get_viewport().get_mouse_position()
	var tpos : Vector3i = _calculate_projected_tile_position(mouse_position)
	if not generator._in_range(tpos) or edit_mode == -1: tpos = Vector3i(-1,-1,-1)
	ui.set_tile_position(tpos)

	if edit_mode == -1: ui.set_mode_label("View Perspective")
	else:
		var layer : int
		var view_string : String
		if edit_mode == camera.OrthoViewFront:
			view_string = "Front"
			layer = _edit_mode_front_rear_clip
		if edit_mode == camera.OrthoViewRear:
			view_string = "Rear"
			layer = generator.dimensions.z - _edit_mode_front_rear_clip - 1
		if edit_mode == camera.OrthoViewRight:
			view_string = "Right"
			layer = _edit_mode_right_left_clip
		if edit_mode == camera.OrthoViewLeft:
			view_string = "Left"
			layer = generator.dimensions.x - _edit_mode_right_left_clip - 1
		if edit_mode == camera.OrthoViewTop:
			view_string = "Top"
			layer = _edit_mode_top_bottom_clip
		if edit_mode == camera.OrthoViewBottom:
			view_string = "Bottom"
			layer = generator.dimensions.y - _edit_mode_top_bottom_clip - 1

		var tile_id : String = ui.get_selected_tile_id()
		if tile_id == "": tile_id = "-"
		ui.set_mode_label("Edit Orthogonal %s Layer %d Tile [%s]" % [view_string,layer,tile_id])


################################################################################
## Engine Methods

func _ready() -> void:
	for tile in generator.tileset.tiles:
		ui.add_tile_to_list(tile.get_id())


func _process(delta: float) -> void:
	var cell_size : float = generator.cell_size
	var dimensions : Vector3i = generator.dimensions

	generator.position = 0.5 * cell_size * (Vector3(1,1,1) - Vector3(dimensions.x,0,dimensions.z))

	if not generator.is_collapsing() and ui.disabled:
		ui.disabled = false

	if camera.mode == camera.CameraMode.Orbit: edit_mode = -1

	_set_status_bar()


func _unhandled_input(p_event: InputEvent) -> void:
	if p_event is InputEventKey:
		var key : InputEventKey = p_event as InputEventKey

		if key.keycode == KEY_E and key.pressed and not key.echo:
			if edit_mode == camera.OrthoViewFront:
				_edit_mode_front_rear_clip += 1
			if edit_mode == camera.OrthoViewRear:
				_edit_mode_front_rear_clip -= 1
			if edit_mode == camera.OrthoViewRight:
				_edit_mode_right_left_clip += 1
			if edit_mode == camera.OrthoViewLeft:
				_edit_mode_right_left_clip -= 1
			if edit_mode == camera.OrthoViewTop:
				_edit_mode_top_bottom_clip += 1
			if edit_mode == camera.OrthoViewBottom:
				_edit_mode_top_bottom_clip -= 1

		if key.keycode == KEY_D and key.pressed and not key.echo:
			if edit_mode == camera.OrthoViewFront:
				_edit_mode_front_rear_clip -= 1
			if edit_mode == camera.OrthoViewRear:
				_edit_mode_front_rear_clip += 1
			if edit_mode == camera.OrthoViewRight:
				_edit_mode_right_left_clip -= 1
			if edit_mode == camera.OrthoViewLeft:
				_edit_mode_right_left_clip += 1
			if edit_mode == camera.OrthoViewTop:
				_edit_mode_top_bottom_clip -= 1
			if edit_mode == camera.OrthoViewBottom:
				_edit_mode_top_bottom_clip += 1

		if key.keycode == KEY_1 and key.pressed and not key.echo:
			edit_mode = camera.OrthoViewFront
		if key.keycode == KEY_2 and key.pressed and not key.echo:
			edit_mode = camera.OrthoViewRear
		if key.keycode == KEY_3 and key.pressed and not key.echo:
			edit_mode = camera.OrthoViewRight
		if key.keycode == KEY_4 and key.pressed and not key.echo:
			edit_mode = camera.OrthoViewLeft
		if key.keycode == KEY_5 and key.pressed and not key.echo:
			edit_mode = camera.OrthoViewTop
		if key.keycode == KEY_6 and key.pressed and not key.echo:
			edit_mode = camera.OrthoViewBottom

	if p_event is InputEventMouseButton:
		var mouse_button : InputEventMouseButton = p_event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			if edit_mode != -1: _paint_tile(mouse_button.position)
		if mouse_button.button_index == MOUSE_BUTTON_RIGHT and mouse_button.pressed:
			if edit_mode != -1: _erase_tile(mouse_button.position)


################################################################################
## UI

func _on_ui_seed_updated(p_seed: int) -> void:
	generator.seed = p_seed
	print("seed:",generator.seed)


func _on_ui_dimension_updated(p_dimension: Vector3i) -> void:
	generator.dimensions = p_dimension
	print("dimensions:",generator.dimensions)


func _on_ui_cell_size_updated(p_cell_size: float) -> void:
	generator.cell_size = p_cell_size
	generator.position = Vector3(1,1,1) * generator.cell_size * 0.5
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


func _on_ui_clear_pressed() -> void:
	if not generator.is_collapsing():
		ui.disabled = true
		generator.clear()
		ui.disabled = false

################################################################################
## Set/Get

func _set_edit_mode(p_mode : int) -> void:
	edit_mode = p_mode

	if edit_mode == -1:
		camera.set_camera_mode_orbit()
		edit_layer_plane.visible = false
		return

	edit_layer_plane.visible = true
	camera.set_camera_mode_ortho(p_mode)

	_set_edit_layer_position()
	_edit_mode_clip_tiles()
