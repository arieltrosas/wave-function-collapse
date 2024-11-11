class_name NodeWFC extends Node3D
################################################################################
## Constants and Data

const BORDER_KEYS : Array[String] = ["left","right","front","back","top","bottom"]
const ANIMATE_WAIT_TIME : float = 1.0 / 30

################################################################################
## Members

## Exported Members

@export var tileset : TilesetWFC
@export var seed : int = 0

@export_group("Grid")
@export var dimensions : Vector3i = Vector3i(5,1,5): set = _set_dimensions
@export_range(0.1,5.0,0.05) var cell_size : float = 1.0

@export_group("Visualization")
@export var animate : bool = true
@export_range(0.1,3.0,0.1) var animate_speed : float = 1.0

## Public Members
var rng : RandomNumberGenerator
var use_thread : bool = true

## Private Members
var solver : SolverWFC
var solver_trace : Array
var _m_tileMap : Array[Node3D]
var _m_tile_ids : Array[String]
var _m_collapse_thread : Thread
var _m_animation_thread : Thread
var _m_animation_running : bool = false

################################################################################
## Public Methods

func get_tile_at(p_pos : Vector3i) -> Node3D:
	if not _in_range(p_pos): return null
	return _m_tileMap[_position2index(p_pos)]


func is_collapsing() -> bool:
	return _m_collapse_thread.is_alive() or _m_animation_running


func collapse() -> void:
	if is_collapsing(): return

	_set_solver_parameters()

	var size : int = dimensions.x * dimensions.y * dimensions.z
	var tiles : Array[String] = tileset.get_tile_ids()
	var constraints : Dictionary = tileset.get_constraints(BORDER_KEYS)
	var fixed_cells : Array[Dictionary]
	for index in _m_tileMap.size():
		var tile : Node3D = _m_tileMap[index]
		if not tile: continue
		fixed_cells.push_back({"index" : index, "tile" : _m_tile_ids[index]})

	var P : SolverWFC.Problem = SolverWFC.Problem.make_problem(size,tiles,BORDER_KEYS,constraints,_get_neighbour,fixed_cells)
	var S : SolverWFC.Solution = SolverWFC.Solution.new()

	if use_thread:
		if animate: _m_collapse_thread.start(_collapse_animate_on.bind(P,S))
		else: _m_collapse_thread.start(_collapse_animate_off.bind(P,S))
	else:
		solver.solve(P,S)


func place_tile(p_id : String, p_position : Vector3i) -> void:
	if p_id == "":
		remove_tile(p_position)
		return

	if not _in_range(p_position): return
	var tile_position : Vector3 = p_position * cell_size

	var tile : TileWFC = tileset.get_tile_by_id(p_id)
	if not tile: return

	var tile_scene_node : Node3D = tile.scene.instantiate()
	if not tile_scene_node: return

	remove_tile(p_position)

	tile_scene_node.position = tile_position
	add_child(tile_scene_node)
	_m_tileMap[_position2index(p_position)] = tile_scene_node
	_m_tile_ids[_position2index(p_position)] = p_id


func remove_tile(p_position : Vector3i) -> void:
	if not _in_range(p_position): return
	var index : int = _position2index(p_position)

	var tile_scene_node : Node3D = _m_tileMap[index]
	_m_tileMap[index] = null
	_m_tile_ids[index] = ""
	if not tile_scene_node: return

	remove_child(tile_scene_node)
	tile_scene_node.queue_free()


func clear() -> void:
	for i in _m_tileMap.size(): remove_tile(_index2position(i))


################################################################################
## Engine Methods

func _init() -> void:
	solver = SolverWFC.new()
	_m_collapse_thread = Thread.new()
	_m_animation_thread = Thread.new()


func _ready() -> void:
	for tile in tileset.tiles:
		tile.load_from_file()
	_m_tileMap.resize(dimensions.x * dimensions.y * dimensions.z)
	_m_tile_ids.resize(dimensions.x * dimensions.y * dimensions.z)


func _process(delta: float) -> void:
	if _m_collapse_thread.is_started() and not _m_collapse_thread.is_alive():
		_m_collapse_thread.wait_to_finish()


func _exit_tree() -> void:
	if _m_collapse_thread.is_alive():
		_m_collapse_thread.wait_to_finish()

################################################################################
## Private Methods

func _in_range(p_pos : Vector3i) -> bool:
	var in_range_x : bool = 0 <= p_pos.x and p_pos.x < dimensions.x
	var in_range_y : bool = 0 <= p_pos.y and p_pos.y < dimensions.y
	var in_range_z : bool = 0 <= p_pos.z and p_pos.z < dimensions.z
	return in_range_x and in_range_y and in_range_z


func _position2index(p_pos : Vector3i) -> int:
	if not _in_range(p_pos): return -1
	var size_xz : int = dimensions.x * dimensions.z
	var index_xz : int = p_pos.z * dimensions.x + p_pos.x
	return p_pos.y * size_xz + index_xz


func _index2position(p_index : int) -> Vector3i:
	if p_index < 0: return Vector3i(-1,-1,-1)
	var size_xz : int = dimensions.x * dimensions.z
	var index_xz : int = (p_index % size_xz)
	var y : int = p_index / size_xz
	var x : int = index_xz % dimensions.x
	var z : int = index_xz / dimensions.x
	return Vector3i(x,y,z)


func _get_neighbour(p_index : int, p_border_key : String) -> int:
	var index_position : Vector3i = _index2position(p_index)
	if not _in_range(index_position): return -1
	var neighbour_position : Vector3i = Vector3i(0,0,0)
	match p_border_key:
		"left": neighbour_position = index_position + Vector3i.LEFT
		"right": neighbour_position = index_position + Vector3i.RIGHT
		"front": neighbour_position = index_position + Vector3i.BACK
		"back": neighbour_position = index_position + Vector3i.FORWARD
		"top": neighbour_position = index_position + Vector3i.UP
		"bottom": neighbour_position = index_position + Vector3i.DOWN

	return _position2index(neighbour_position)


func _set_solver_parameters() -> void:
	if not rng: rng = RandomNumberGenerator.new()

	if seed != 0:
		rng.seed = seed
	else:
		rng.randomize()
	solver.rng = rng


func _collapse_animate_on(P : SolverWFC.Problem, S : SolverWFC.Solution) -> void:
	_m_animation_running = true

	S.updated.connect(
		func(p_index : int) -> void:
			solver_trace.push_back({"index" : p_index, "tile" : S.get_tile(p_index)})
	)

	_m_animation_thread.start(
		func () -> void:
			while not solver_trace.is_empty() or _m_collapse_thread.is_alive():
				if not solver_trace.is_empty():
					var trace : Dictionary = solver_trace.pop_front()
					var tile_index : int = trace["index"]
					var tile_id : String = trace["tile"]
					place_tile(tile_id,_index2position(tile_index))
				await get_tree().create_timer(ANIMATE_WAIT_TIME / animate_speed).timeout

			_m_animation_running = false
	)

	solver.solve(P,S)
	_m_animation_thread.wait_to_finish()


func _collapse_animate_off(P : SolverWFC.Problem, S : SolverWFC.Solution) -> void:
	solver.solve(P,S)
	for index in P.size:
		var tile_id : String = S.get_tile(index)
		var tile_position : Vector3i = _index2position(index)
		place_tile.call_deferred(tile_id,tile_position)


################################################################################
## Set/Get

func _set_dimensions(p_dimensions : Vector3i) -> void:
	clear()
	p_dimensions.x = max(1,p_dimensions.x)
	p_dimensions.y = max(1,p_dimensions.y)
	p_dimensions.z = max(1,p_dimensions.z)
	dimensions = p_dimensions
	_m_tileMap.resize(dimensions.x * dimensions.y * dimensions.z)
	_m_tile_ids.resize(dimensions.x * dimensions.y * dimensions.z)
