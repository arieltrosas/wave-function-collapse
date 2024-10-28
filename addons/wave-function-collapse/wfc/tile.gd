class_name TileWFC extends Resource
################################################################################
## Constants and Data
const ERROR_ID_KEY : int = 1
const ERROR_BORDERS_KEY : int = 2
const ERROR_BORDER_KEY : int = 3

static func err2str(error : int) -> String:
	match error:
		OK:
			return "success"
		ERROR_ID_KEY:
			return "no id key or bad format"
		ERROR_BORDERS_KEY:
			return "no borders key or bad format"
		ERROR_BORDER_KEY:
			return "no boder key or bad format"
		_:
			return "unknown error"

const KEY_ID : String = "id"
const KEY_BORDERS : String = "borders"

################################################################################
## Members

@export var scene : PackedScene
@export_file var json_path : String = ""

var _m_data : Dictionary = {}

################################################################################
## Public Methods

func get_id() -> String:
	var error : int = _is_data_id_ok(_m_data)
	if error != OK:
		push_warning("invalid tile id: %s" % err2str(error))
		return ""
	return _m_data[KEY_ID]

func set_id(p_id : String) -> void:
	_m_data[KEY_ID] = p_id

func get_border(p_border_key : String) -> Dictionary:
	var error : int = _is_data_border_ok(_m_data,p_border_key)
	if error != OK:
		push_warning("invalid tile border [%s]: %s" % [p_border_key,err2str(error)])
		return {}
	return _m_data[KEY_BORDERS][p_border_key]

func set_border(p_border_key : String, p_border_value : Dictionary) -> void:
	var error : int = _is_data_borders_ok(_m_data)
	if error != OK:
		push_warning("invalid tile borders: %s" % err2str(error))
		return

	error = _is_data_border_ok(_m_data,p_border_key)
	if error != OK:
		push_warning("invalid tile border [%s]: %s" % [p_border_key,err2str(error)])
		return

	if p_border_value.keys().any(func(key): return typeof(key) != TYPE_STRING):
		push_warning("could not set border [%s]: invalid border format" % p_border_key)
		return

	if p_border_value.values().any(func(value): return typeof(value) != TYPE_FLOAT):
		push_warning("could not set border [%s]: invalid border format" % p_border_key)
		return

	_m_data[KEY_BORDERS][p_border_key] = p_border_value

func get_border_tile_value(p_border_key : String, p_tile_id : String) -> float:
	var error : int = _is_data_border_ok(_m_data,p_border_key)
	if error != OK:
		push_warning("invalid tile border [%s]: %s" % [p_border_key,err2str(error)])
		return -1.0

	if not p_tile_id in _m_data[KEY_BORDERS][p_border_key]:
		return 0.0

	return _m_data[KEY_BORDERS][p_border_key][p_tile_id]

func set_border_tile_value(p_border_key : String, p_tile_id : String, p_value : float) -> void:
	var error : int = _is_data_border_ok(_m_data,p_border_key)
	if error != OK:
		push_warning("invalid tile border [%s]: %s" % [p_border_key,err2str(error)])
		return

	_m_data[KEY_BORDERS][p_border_key][p_tile_id] = p_value

func is_format_ok() -> bool:
	return _is_data_format_ok(_m_data) == OK

func load_from_file() -> void:
	var file : FileAccess = FileAccess.open(json_path,FileAccess.READ)
	if not file:
		push_warning("could not open file \"%s\"" % json_path)
		return

	var json_string : String = file.get_as_text(true)
	if not json_string:
		push_warning("could not read file \"%s\" contents" % json_path)
		return

	var json_parser : JSON = JSON.new()
	var error : int = json_parser.parse(json_string)
	if error != OK:
		push_warning("JSON parse error at [%s:%d]: %s" % [json_path,json_parser.get_error_line(),json_parser.get_error_message()])
		return

	error = _is_data_format_ok(json_parser.data)
	if error != OK:
		push_warning("error loading JSON file \"%s\": %s" % [json_path,err2str(error)])
		return

	_m_data = json_parser.data
	WFCPlugin.Log("loaded tile TileWFC[id=%s] from \"%s\"" % [get_id(),json_path])

func save_to_file() -> void:
	var file : FileAccess = FileAccess.open(json_path,FileAccess.WRITE)
	if not file:
		push_warning("could not open file \"%s\"" % json_path)
		return

	var error : int = _is_data_format_ok(_m_data)
	if error != OK:
		push_warning("error saving JSON file \"%s\": %s" % [json_path,err2str(error)])
		return

	var json_string : String = JSON.stringify(_m_data,"\t",false)
	file.store_string(json_string)

func _to_string() -> String:
	return JSON.stringify(_m_data,"\t",false)

################################################################################
## Private Methods

static func _is_data_format_ok(p_data : Dictionary) -> int:
	var error : int = OK

	error = _is_data_id_ok(p_data)
	if error != OK: return error

	error = _is_data_borders_ok(p_data)
	if error != OK: return error

	var borders : Dictionary = p_data[KEY_BORDERS]
	for border_key in borders.keys():
		error = _is_data_border_ok(p_data,border_key)
		if error != OK: return error

	return OK

static func _is_data_id_ok(p_data : Dictionary) -> int:
	var id = p_data.get(KEY_ID)
	if not id or typeof(id) != TYPE_STRING:
		return ERROR_ID_KEY
	return OK

static func _is_data_borders_ok(p_data : Dictionary) -> int:
	var borders = p_data.get(KEY_BORDERS)
	if not borders or typeof(borders) != TYPE_DICTIONARY:
		return ERROR_BORDERS_KEY

	if borders.keys().any(func(key): return typeof(key) != TYPE_STRING):
		return ERROR_BORDERS_KEY

	return OK

static func _is_data_border_ok(p_data : Dictionary, p_border_key : String) -> int:
	var error : int = _is_data_borders_ok(p_data)
	if error != OK: return error

	var borders : Dictionary = p_data[KEY_BORDERS]
	var border = borders.get(p_border_key)

	if not border: return OK

	if typeof(border) != TYPE_DICTIONARY:
		return ERROR_BORDER_KEY

	if border.keys().any(func(key): return typeof(key) != TYPE_STRING):
		return ERROR_BORDER_KEY

	if border.values().any(func(value): return typeof(value) != TYPE_FLOAT):
		return ERROR_BORDER_KEY

	return OK

################################################################################
## Setters/Getters
