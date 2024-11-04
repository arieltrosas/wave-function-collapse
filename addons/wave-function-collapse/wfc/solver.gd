class_name SolverWFC extends RefCounted
################################################################################
## Constants and Data Structures

const ERROR_UNDEFINED : int = -1
const ERROR_UNSOLVABLE_PROBLEM : int = -2
const ERROR_SOLVER_PARAMETERS : int = -3

class Solution extends RefCounted:
	signal updated(p_index : int)

	var solution : Array[int]
	var tiles : Array[String]

	func get_tile(p_index : int) -> String:
		var t : int = solution[p_index]
		return tiles[t] if t != -1 else ""

class Problem extends RefCounted:

	static func make_problem(	p_size : int,
								p_tiles : Array[String],
								p_border_keys : Array[String],
								p_constraints : Dictionary,
								p_neighbourhood_function : Callable,
								p_fixed : Array[Dictionary]):
		var P : Problem = Problem.new()

		P.size = p_size
		P.tiles = p_tiles
		P.domain_size = P.tiles.size()
		P.border_keys = p_border_keys
		P.constraints = {}
		P.fixed_cells = p_fixed

		for tile in P.tiles:
			P.constraints[tile] = {}
			var tile_constraints : Dictionary = p_constraints[tile]
			for border_key in P.border_keys:
				var tile_border_constraints : Dictionary = tile_constraints[border_key]
				var border_constraints_array : Array[float]
				border_constraints_array.resize(P.domain_size)
				border_constraints_array.fill(0.0)
				for i in P.domain_size:
					var t : String = P.tiles[i]
					var t_value : float = tile_border_constraints.get(t,0.0)
					border_constraints_array[i] = p_constraints[tile][border_key][P.tiles[i]]
				P.constraints[tile][border_key] = border_constraints_array

		P.neighbourhood_function = p_neighbourhood_function

		return P

	var size : int
	var tiles : Array[String]
	var domain_size : int
	var border_keys : Array[String]
	var constraints : Dictionary
	var neighbourhood_function : Callable
	var fixed_cells : Array[Dictionary]

	func get_neighbour(p_cell_index : int, p_border_key : String) -> int:
		return neighbourhood_function.call(p_cell_index,p_border_key)

	func get_border_constraint(p_tile : int, p_border_key : String) -> Array[float]:
		var border_constraint : Array[float]
		border_constraint.assign(constraints[tiles[p_tile]][p_border_key])
		return border_constraint

class Cell extends RefCounted:
	signal tile_updated

	var index : int = -1
	var tile : int = -1: set = _set_tile
	var domain : Array[float]

	func _set_tile(p_tile : int) -> void:
		tile = p_tile
		if tile != -1:
			domain.fill(0.0)
			domain[tile] = 1.0
		else: domain.fill(1.0)
		tile_updated.emit()


	static func make_cell(p_index : int, p_domain_size : int) -> Cell:
		var cell : Cell = Cell.new()
		cell.index = p_index
		cell.tile = -1
		cell.domain.resize(p_domain_size)
		cell.domain.fill(1.0)
		return cell


	static func make_array(p_size : int, p_domain_size : int) -> Array[Cell]:
		var array : Array[Cell]
		array.resize(p_size)
		for i in p_size: array[i] = make_cell(i,p_domain_size)
		return array


	func is_collapsed() -> bool:
		return tile != -1


	func entropy() -> float:
		var e : float = 0.0
		for p in domain: if p != 0.0: e += p * log(p)
		return -e

	func is_domain_empty() -> bool:
		return domain.all(func(p : float) -> bool: return p == 0)


	func collapse(rng : RandomNumberGenerator) -> void:
		_normalize_domain()
		var p : float = rng.randf()
		var p_accumulated : float = 0.0
		var t : int = -1
		for i in domain.size():
			p_accumulated += domain[i]
			if p <= p_accumulated:
				t = i
				break
		tile = t

	func constrain_domain(p_constraint : Array[float]) -> void:
		for i in domain.size(): domain[i] = domain[i] * p_constraint[i]

	func _normalize_domain() -> void:
		var c : float = 0.0
		for p in domain: c += p
		if c == 0.0: return
		c = 1.0 / c
		for i in domain.size(): domain[i] *= c

	func duplicate() -> Cell:
		var other : Cell = Cell.new()
		other.domain = domain.duplicate()
		other.index = index
		other.tile = tile
		return other

	func assign(p_cell : Cell) -> void:
		index = p_cell.index
		tile = p_cell.tile
		domain = p_cell.domain.duplicate()

	func _to_string() -> String:
		return "Cell(%d,%d)%s" % [index,tile,str(domain)]

class PriorityQueue extends RefCounted:
	var _cell_indexes : Array[int]
	var _cell_entropy : Array[float]

	func is_empty() -> bool:
		return _cell_indexes.is_empty()

	func insert(p_index : int, p_entropy : float) -> void:
		var k : int = 0
		while k < _cell_indexes.size() and p_entropy > _cell_entropy[k]:
			k = k + 1
		_cell_indexes.insert(k,p_index)
		_cell_entropy.insert(k,p_entropy)

	func next() -> int:
		_cell_entropy.pop_front()
		return _cell_indexes.pop_front()

class BacktrackNode extends RefCounted:
	var domain_veto : Array[float]
	var state : Array[Cell]

	static func make_backtrack_node(p_cell : Cell, p_cells : Array[Cell], P : Problem) -> BacktrackNode:
		var bnode : BacktrackNode = BacktrackNode.new()
		bnode.domain_veto = p_cell.domain.duplicate()
		bnode.state.push_back(p_cell.duplicate())
		for border_key in P.border_keys:
			var neighbour_index : int = P.get_neighbour(p_cell.index,border_key)
			if neighbour_index == -1: continue
			var neighbour_cell : Cell = p_cells[neighbour_index]
			var neighbour_cell_duplicate = neighbour_cell.duplicate()
			bnode.state.push_back(neighbour_cell_duplicate)

		return bnode

################################################################################
## Members

var rng : RandomNumberGenerator = null

################################################################################
## Public Methods

func solve(P : Problem, S : Solution) -> int:
	if not rng: return ERROR_SOLVER_PARAMETERS

	S.solution.resize(P.size)
	S.solution.fill(-1)
	S.tiles = P.tiles

	var cells : Array[Cell] = Cell.make_array(P.size,P.domain_size)
	for cell in cells:
		cell.tile_updated.connect(
			func() -> void:
				S.solution[cell.index] = cell.tile
				S.updated.emit.call_deferred(cell.index)
		)

	var exploration_queue : PriorityQueue = PriorityQueue.new()
	var backtrack_stack : Array[BacktrackNode]

	var unsolvable : bool = false
	var starting_index_pool : Array[int]
	for i in P.size: starting_index_pool.push_back(i)

	for fixed in P.fixed_cells:
		var index : int = fixed["index"]
		var tile : String = fixed["tile"]
		for connection in cells[index].tile_updated.get_connections():
			cells[index].tile_updated.disconnect(connection["callable"])
		cells[index].tile = S.tiles.find(tile)
		S.solution[index] = cells[index].tile
		starting_index_pool[index] = -1
		if not _propagate(cells[index],cells,exploration_queue,P):
			unsolvable = true

	if unsolvable: return ERROR_UNSOLVABLE_PROBLEM

	starting_index_pool = starting_index_pool.filter(func(i): return i != -1)
	if starting_index_pool.is_empty(): return OK
	var initial_index : int = starting_index_pool[rng.randi() % starting_index_pool.size()]

	exploration_queue.insert(initial_index,0)

	# Algorithm

	while not exploration_queue.is_empty(): # main loop
		var current_index : int = exploration_queue.next()
		var current_cell : Cell = cells[current_index]

		if current_cell.is_domain_empty(): return ERROR_UNSOLVABLE_PROBLEM
		if current_cell.is_collapsed(): continue

		backtrack_stack.push_back(BacktrackNode.make_backtrack_node(current_cell,cells,P))

		var backtrack : bool = _collapse_cell(current_cell,cells,exploration_queue,P)

		while backtrack: # backtrack loop
			if backtrack_stack.is_empty():
				return ERROR_UNSOLVABLE_PROBLEM
			backtrack = _backtrack(cells,backtrack_stack,exploration_queue,P)

		# end backtrack loop

	# end main loop

	# End Algorithm

	return OK

################################################################################
## Private Methods+

func _collapse_cell(p_cell : Cell, p_cells : Array[Cell], p_queue : PriorityQueue, P : Problem) -> bool:
	p_cell.collapse(rng)
	return not _propagate(p_cell,p_cells,p_queue,P)


func _propagate(p_cell : Cell, p_cells : Array[Cell], p_queue : PriorityQueue, P : Problem) -> bool:
	var next : Array[Cell]
	for border_key in P.border_keys:
		var neighbour_index : int = P.get_neighbour(p_cell.index,border_key)
		if neighbour_index == -1: continue
		var neighbour_cell : Cell = p_cells[neighbour_index]
		var constraint : Array[float] = P.get_border_constraint(p_cell.tile,border_key)
		neighbour_cell.constrain_domain(constraint)
		if neighbour_cell.is_domain_empty():
			next.clear()
			return false
		if not neighbour_cell.is_domain_empty():
			next.push_back(neighbour_cell)

	for cell in next: p_queue.insert(cell.index,cell.entropy())

	return true


func _backtrack(p_cells : Array[Cell], p_bstack : Array[BacktrackNode], p_queue : PriorityQueue, P : Problem) -> bool:
	var bnode : BacktrackNode = p_bstack.back()
	var current_cell = p_cells[bnode.state[0].index]

	var is_domain_empty : bool = not _restore_backtrack_node(current_cell,bnode,p_cells,P)

	if is_domain_empty:
		p_bstack.pop_back()
		p_queue.insert(current_cell.index,current_cell.entropy())
		return true

	var backtrack = _collapse_cell(current_cell,p_cells,p_queue,P)

	return backtrack


func _restore_backtrack_node(p_cell : Cell, p_bnode : BacktrackNode, p_cells : Array[Cell], P : Problem) -> bool:
	p_bnode.domain_veto[p_cell.tile] = 0.0
	for cell in p_bnode.state:
		p_cells[cell.index].assign(cell)
	p_cells[p_bnode.state[0].index].constrain_domain(p_bnode.domain_veto)
	if p_cells[p_bnode.state[0].index].is_domain_empty():
		p_cells[p_bnode.state[0].index].assign(p_bnode.state[0])
		return false
	return true
