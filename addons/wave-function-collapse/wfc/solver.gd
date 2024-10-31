class_name SolverWFC extends RefCounted
################################################################################
## Constants and Data Structures

class Solution extends RefCounted:
	var solution : Array[int]
	var tile_id_map : Array[String]

class Problem extends RefCounted:

	static func make_problem(	p_size : int,
								p_tiles : Array[String],
								p_border_keys : Array[String],
								p_constraints : Dictionary,
								p_neighbourhood_function : Callable):
		var P : Problem = Problem.new()

		P.size = p_size
		P.tiles = p_tiles
		P.domain_size = P.tiles.size()
		P.border_keys = p_border_keys
		P.constraints = {}

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

	func get_neighbour(p_cell_index : int, p_border_key : String) -> int:
		return neighbourhood_function.call(p_cell_index,p_border_key)

	func get_border_constraint(p_tile : int, p_border_key : String) -> Array[float]:
		var border_constraint : Array[float]
		border_constraint.assign(constraints[tiles[p_tile]][p_border_key])
		return border_constraint

class Cell extends RefCounted:
	var index : int = -1
	var tile : int = -1: set = _set_tile
	var domain : Array[float]

	func _set_tile(p_tile : int) -> void:
		if p_tile >= domain.size(): return
		tile = p_tile
		if tile != -1:
			domain.fill(0.0)
			domain[tile] = 1.0
		else: domain.fill(1.0)

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
		other.index = index
		other.tile = tile
		other.domain = domain.duplicate()
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
		bnode.domain_veto.resize(p_cell.domain.size())
		bnode.domain_veto.fill(1.0)
		bnode.state.push_back(p_cell.duplicate())
		for border_key in P.border_keys:
			var neighbour_index : int = P.get_neighbour(p_cell.index,border_key)
			if neighbour_index == -1: continue
			var neighbour_cell : Cell = p_cells[neighbour_index]
			bnode.state.push_back(neighbour_cell.duplicate())

		return bnode

################################################################################
## Members

var rng : RandomNumberGenerator = null

################################################################################
## Public Methods

func solve(P : Problem) -> Solution:
	if not rng: return
	var S : Solution = Solution.new()
	S.solution.resize(P.size)
	S.solution.fill(-1)
	S.tile_id_map = P.tiles

	var cells : Array[Cell] = Cell.make_array(P.size,P.domain_size)
	var exploration_queue : PriorityQueue = PriorityQueue.new()
	var backtrack_stack : Array[BacktrackNode]

	exploration_queue.insert(rng.randi() % P.size,0)

	# Algorithm

	while not exploration_queue.is_empty():
		var current_index : int = exploration_queue.next()
		var current_cell : Cell = cells[current_index]

		if current_cell.is_collapsed(): continue

		backtrack_stack.push_back(BacktrackNode.make_backtrack_node(current_cell,cells,P))

		current_cell.collapse(rng)
		var next_cells : Array[Cell]
		var backtrack : bool = not _propagate(current_cell,cells,next_cells,P)

		for cell in next_cells:
				exploration_queue.insert(cell.index,cell.entropy())

		while backtrack:
			if backtrack_stack.is_empty():
				print("Unsolvable problem: empty stack")
				return S

			var bnode : BacktrackNode = backtrack_stack.back()
			current_index = bnode.state[0].index
			current_cell = cells[current_index]

			var is_domain_empty : bool = not _restore_backtrack_node(current_cell,bnode,cells,P)

			if is_domain_empty:
				backtrack_stack.pop_back()
				exploration_queue.insert(current_index,current_cell.entropy())
			else:
				current_cell.collapse(rng)
				backtrack = not _propagate(current_cell,cells,next_cells,P)
				for cell in next_cells:
					exploration_queue.insert(cell.index,cell.entropy())

	# End Algorithm

	for i in P.size: S.solution[i] = cells[i].tile

	return S

################################################################################
## Private Methods

func _propagate(p_cell : Cell, p_cells : Array[Cell], r_next : Array[Cell], P : Problem, ) -> bool:
	for border_key in P.border_keys:
		var neighbour_index : int = P.get_neighbour(p_cell.index,border_key)
		if neighbour_index == -1: continue
		var neighbour_cell : Cell = p_cells[neighbour_index]
		if not neighbour_cell.is_collapsed():
			var constraint : Array[float] = P.get_border_constraint(p_cell.tile,border_key)
			neighbour_cell.constrain_domain(constraint)
			if neighbour_cell.is_domain_empty():
				r_next.clear()
				return false
			r_next.push_back(neighbour_cell)

	return true

func _restore_backtrack_node(p_cell : Cell, p_bnode : BacktrackNode, p_cells : Array[Cell], P : Problem) -> bool:
	p_bnode.domain_veto[p_cell.tile] = 0.0
	for cell in p_bnode.state:
		p_cells[cell.index].assign(cell)
	p_cells[p_bnode.state[0].index].constrain_domain(p_bnode.domain_veto)
	if p_cells[p_bnode.state[0].index].is_domain_empty():
		p_cells[p_bnode.state[0].index].assign(p_bnode.state[0])
		return false
	return true
