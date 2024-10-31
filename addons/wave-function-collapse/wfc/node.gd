class_name NodeWFC extends Node3D
################################################################################
## Constants and Data

const BORDER_KEYS : Array[String] = ["left","right","front","back","top","bottom"]

################################################################################
## Members

## Exported Members
@export var tileset : TilesetWFC

@export_category("WFC")
@export var seed : int = 0

@export_category("Grid")
@export var dimensions : Vector3i = Vector3i(5,1,5)
@export_range(0.1,5.0,0.05) var cell_size : float = 1.0

## Public Members
var rng : RandomNumberGenerator

## Private Members
var _m_solver : SolverWFC
var _m_tileMap : Array[Node3D]

################################################################################
## Public Methods

func collapse() -> void:
	_set_solver_parameters()

	var size : int = dimensions.x * dimensions.y * dimensions.z
	var tiles : Array[String] = tileset.get_tile_ids()
	var constraints : Dictionary = tileset.get_constraints(BORDER_KEYS)

	var P : SolverWFC.Problem = SolverWFC.Problem.make_problem(size,tiles,BORDER_KEYS,constraints,_get_neighbour)
	var S : SolverWFC.Solution = _m_solver.solve(P)

	for i in S.solution.size():
		if S.solution[i] == -1: continue
		var tile_id : String = S.tile_id_map[S.solution[i]]
		var tile_position : Vector3i = _index2position(i)
		place_tile(tile_id,tile_position)

func place_tile(p_id : String, p_position : Vector3i) -> void:
	if not _in_range(p_position): return
	var tile_position : Vector3 = p_position * cell_size

	var tile : TileWFC = tileset.get_tile_by_id(p_id)
	if not tile: return

	var tile_scene_node : Node3D = tile.scene.instantiate()
	if not tile_scene_node: return

	add_child(tile_scene_node)
	tile_scene_node.position = tile_position
	_m_tileMap[_position2index(p_position)] = tile_scene_node

func remove_tile(p_position : Vector3i) -> void:
	if not _in_range(p_position): return
	var index : int = _position2index(p_position)

	var tile_scene_node : Node3D = _m_tileMap[index]
	_m_tileMap[index] = null
	if not tile_scene_node: return

	remove_child(tile_scene_node)
	tile_scene_node.queue_free()

################################################################################
## Engine Methods

func _ready() -> void:
	for tile in tileset.tiles: tile.load_from_file()
	_m_tileMap.resize(dimensions.x * dimensions.y * dimensions.z)

func _init() -> void:
	_m_solver = SolverWFC.new()

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
		"front": neighbour_position = index_position + Vector3i.FORWARD
		"back": neighbour_position = index_position + Vector3i.BACK
		"top": neighbour_position = index_position + Vector3i.UP
		"bottom": neighbour_position = index_position + Vector3i.DOWN

	return _position2index(neighbour_position)

func _set_solver_parameters() -> void:
	if not rng:
		rng = RandomNumberGenerator.new()
		if seed != 0: rng.seed = seed
		else: rng.randomize()
	_m_solver.rng = rng
