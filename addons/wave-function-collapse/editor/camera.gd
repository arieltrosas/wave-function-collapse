extends Camera3D
################################################################################
## Constants and Data

enum CameraMode { Ortho, Orbit }
enum OrthoView { Front, Rear, Right, Left, Top, Bottom }

const BaseCameraSpeed : float = 10.0
const BaseCameraSensitivity : float = 0.25
const BaseViewDistance : float = 5.0

################################################################################
## Properties

@export var mode : CameraMode = CameraMode.Orbit

var _look_at_point : Vector3 = Vector3(0,0,0)
var _view_distance : float = BaseViewDistance: set = _set_view_distance

var _is_shift_pressed : bool = false
var _is_mouse_middle_button_pressed : bool = false
var _mouse_wheel_dir : float = 0.0
var _mouse_velocity : Vector2 = Vector2(0,0)

var _orbit_rotation : Vector3 = Vector3(0,0,0)

################################################################################
## Public Methods

func get_forward_vector() -> Vector3:
	return -global_basis.z


func get_right_vector() -> Vector3:
	return global_basis.x


func get_up_vector() -> Vector3:
	return global_basis.y


################################################################################
## Private Methods

func _process_drag(delta : float) -> void:
	var orbit_velocity : Vector3 = Vector3(0,0,0)
	orbit_velocity.x = -_mouse_velocity.y * deg_to_rad(BaseCameraSensitivity)
	orbit_velocity.y = -_mouse_velocity.x * deg_to_rad(BaseCameraSensitivity)

	_orbit_rotation += orbit_velocity
	_orbit_rotation.x = clamp(_orbit_rotation.x,-PI * 0.4999,PI * 0.4999)


func _process_pan(delta : float) -> void:
	var displacement : Vector3 = Vector3(0,0,0)
	displacement += get_up_vector() * _mouse_velocity.y * _view_distance * 0.01 * BaseCameraSensitivity
	displacement += -get_right_vector() * _mouse_velocity.x * _view_distance * 0.01 * BaseCameraSensitivity
	_look_at_point += displacement


func _set_camera_mode_ortho(p_ortho_view : OrthoView) -> void:
	mode = CameraMode.Ortho
	projection = ProjectionType.PROJECTION_ORTHOGONAL

	match p_ortho_view:
		OrthoView.Front: _orbit_rotation = Vector3(0,0,0)
		OrthoView.Rear: _orbit_rotation = Vector3(0,PI,0)
		OrthoView.Right: _orbit_rotation = Vector3(0,PI * 0.5,0)
		OrthoView.Left: _orbit_rotation = Vector3(0,PI * 1.5,0)
		OrthoView.Top: _orbit_rotation = Vector3(PI * 0.4999,0,0)
		OrthoView.Bottom: _orbit_rotation = Vector3(-PI * 0.4999,0,0)

func _set_camera_mode_orbit() -> void:
	mode = CameraMode.Ortho
	projection = ProjectionType.PROJECTION_PERSPECTIVE

################################################################################
## Engine Methods

func _ready() -> void:
	position = Vector3(0,0,1) * _view_distance


func _process(delta : float) -> void:
	var is_drag_mode : bool = _is_mouse_middle_button_pressed and not _is_shift_pressed
	var is_panning_mode : bool = _is_mouse_middle_button_pressed and _is_shift_pressed

	if is_drag_mode or is_panning_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if is_drag_mode and mode == CameraMode.Ortho: _set_camera_mode_orbit()

	if is_drag_mode: _process_drag(delta)
	if is_panning_mode: _process_pan(delta)

	_view_distance += _mouse_wheel_dir * 0.1 * _view_distance

	position = Vector3(0,0,1) * _view_distance
	position = position.rotated(Vector3(1,0,0),_orbit_rotation.x)
	position = position.rotated(Vector3(0,1,0),_orbit_rotation.y)
	position += _look_at_point
	transform = transform.looking_at(_look_at_point)

	_mouse_velocity = Vector2(0,0)
	_mouse_wheel_dir = 0.0


func _input(p_event : InputEvent) -> void:
	if p_event is InputEventKey:
		var key_event : InputEventKey = p_event as InputEventKey
		if key_event.keycode == KEY_SHIFT:
			_is_shift_pressed = key_event.pressed

		if key_event.keycode == KEY_1: _set_camera_mode_ortho(OrthoView.Front)
		if key_event.keycode == KEY_2: _set_camera_mode_ortho(OrthoView.Rear)
		if key_event.keycode == KEY_3: _set_camera_mode_ortho(OrthoView.Right)
		if key_event.keycode == KEY_4: _set_camera_mode_ortho(OrthoView.Left)
		if key_event.keycode == KEY_5: _set_camera_mode_ortho(OrthoView.Top)
		if key_event.keycode == KEY_6: _set_camera_mode_ortho(OrthoView.Bottom)

	if p_event is InputEventMouseButton:
		var mouse_button_event : InputEventMouseButton = p_event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_mouse_middle_button_pressed = mouse_button_event.pressed

		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_mouse_wheel_dir = 1.0

		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_mouse_wheel_dir = -1.0

	if p_event is InputEventMouseMotion:
		var mouse_motion_event : InputEventMouseMotion = p_event as InputEventMouseMotion
		_mouse_velocity = mouse_motion_event.relative

################################################################################
## Set/Get Methods

func _set_view_distance(p_distance : float) -> void:
	if p_distance <= 0.0: return
	_view_distance = p_distance
	size = tan(deg_to_rad(fov) * 0.5) * _view_distance * 2.0
